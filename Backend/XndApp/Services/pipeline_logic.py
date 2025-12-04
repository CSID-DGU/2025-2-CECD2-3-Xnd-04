# 파일: XndApp/Services/pipeline_logic.py

import os
import numpy as np
import cv2
from django.conf import settings
from typing import Dict, List, Any
from XndApp.apps import SrmappConfig
from google.cloud import vision
import re
from datetime import date, datetime
import math
from gensim.models import Word2Vec
import Levenshtein
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
import logging

logger = logging.getLogger('PipelineLogic')
logger.setLevel(logging.INFO)

CACHED_INGREDIENT_LIST = None

# 식재료명/유통기한 인식에서 제외할 키워드 (영양성분 + 제조시설/경고 문구)
EXCLUSION_KEYWORDS = [
    '나트륨', '탄수화물', '당류', '지방', '트랜스지방', '포화지방',
    '콜레스테롤', '단백질', '칼슘', '열량', 'g', 'mg', 'kcal', '%',
    '제조시설', '사용된', '시설에서', '원재료', '함유', '알레르기', '성분', '주의', '사용할', '수', '있습니다', '제품은', '원재료명',
    '부정', '불량', '가지', '안심', '식품'
]

STANDARD_MAP = {
    # 인식 : 표준
    "계란": "달걀",
    "케챂": "케첩",
    "케찹": "케첩",
    "고추가루": "고춧가루"
}


# ====================================================================
# [헬퍼 함수]
# ====================================================================
def get_area(box: List[int]) -> int:
    """바운딩 박스 면적 계산"""
    return (box[2] - box[0]) * (box[3] - box[1])


def get_center_x(box: List[int]) -> float:
    """바운딩 박스 중심 X 좌표 계산"""
    return (box[0] + box[2]) / 2


def get_standard_ingredient_list() -> List[str]:
    """
    DB에서 표준 식재료 목록을 가져오되, 한 번 로드된 후에는 메모리에서 반환합니다.
    """
    global CACHED_INGREDIENT_LIST
    if CACHED_INGREDIENT_LIST is not None:
        return CACHED_INGREDIENT_LIST

    try:
        from XndApp.Models.foodStorageLife import FoodStorageLife
        CACHED_INGREDIENT_LIST = list(FoodStorageLife.objects.values_list('name', flat=True).distinct())
        return CACHED_INGREDIENT_LIST
    except Exception as e:
        logger.warning(f"Warning: DB Error during initial load. Using fallback list: {e}")
        return ['케첩', '두부', '파스타면', '쌀', '계란']


def get_standard_name(ingredient_name: str) -> str:
    return STANDARD_MAP.get(ingredient_name, ingredient_name)


TYPO_THRESHOLD = 0.85


# 1. 메인 파이프라인 함수
def process_image_pipeline(user_id: int, image_paths: List[str], layer: str, image_width: int = 1920,
                           image_height: int = 1080, action_type: str = 'analyzing') -> Dict[
    str, Any]:
    # 1. 모든 이미지에 대해 YOLO 수행 (병렬 처리 적용)
    yolo_results = []

    with ThreadPoolExecutor(max_workers=os.cpu_count() or 4) as executor:
        futures = {executor.submit(run_yolo_detection, path): path for path in image_paths}
        for future in futures:
            result = future.result()
            if result:
                result['file_path'] = futures[future]
                yolo_results.append(result)

    path_to_result = {res['file_path']: res for res in yolo_results}
    valid_detections = [path_to_result[path] for path in image_paths if path in path_to_result]

    ACTION_DETAIL_LOG = []

    # 좌표 변수 초기화 (이미지 픽셀 좌표 기준)
    start_x_center = 0.0
    end_x_center = 0.0
    start_y_center = 0.0
    end_y_center = 0.0

    determined_status = 'inbound'
    determined_layer = int(layer)

    target_path = image_paths[-1] if image_paths else None
    target_yolo_result = None

    # ====================================================================
    # [분석 1] 이동 방향 판단 (🚨 X/Y 교환 로직 - Area 및 Y 일관성 로직 제거됨)
    # ====================================================================

    # 🚨 [X/Y 교환] 임계값 설정: 이미지 Y축 크기(image_height)를 이동 축으로 사용
    ACTUAL_MOVEMENT_DIMENSION = image_height
    ACTUAL_LAYER_DIMENSION = image_width

    RATIO_Y_THRESHOLD = 0.010
    RATIO_Y_MIN_MOVEMENT = 0.015

    Y_THRESHOLD = ACTUAL_MOVEMENT_DIMENSION * RATIO_Y_THRESHOLD
    Y_MIN_MOVEMENT = ACTUAL_MOVEMENT_DIMENSION * RATIO_Y_MIN_MOVEMENT

    # ------------------------------------

    if len(valid_detections) == 0:
        msg = "❌ 인식된 객체 없음: (기본값)"
        logger.error(msg)
        ACTION_DETAIL_LOG.append(msg)

    elif len(valid_detections) == 1:
        msg = "⚠️ 1장만 인식됨: 이동 파악 불가 (기본값 inbound)"
        logger.warning(msg)
        ACTION_DETAIL_LOG.append(msg)
        determined_status = 'inbound'

    else:  # 2장 이상 탐지 시
        first_d = valid_detections[0]
        last_d = valid_detections[-1]

        # 🚨 [X/Y 교환] Y축 중심 변화를 계산 (delta_y는 여기서 입출고를 의미)
        start_y_center = (first_d['bounding_box'][1] + first_d['bounding_box'][3]) / 2
        end_y_center = (last_d['bounding_box'][1] + last_d['bounding_box'][3]) / 2

        # NOTE: delta_y_movement 양수 = Y축 감소 = 물리적으로 안쪽 이동(입고)
        delta_y_movement = start_y_center - end_y_center

        all_centers_y = [(d['bounding_box'][1] + d['bounding_box'][3]) / 2 for d in valid_detections]
        Y_max = max(all_centers_y) if all_centers_y else 0.0
        Y_min = min(all_centers_y) if all_centers_y else 0.0
        total_y_range = abs(Y_max - Y_min)

        # Y축 이동량만으로 행위 완료 여부 판단 (Area 로직 대체)
        is_significant_movement = total_y_range >= Y_MIN_MOVEMENT

        if len(valid_detections) >= 3:

            # Best shot은 OCR 용으로 남겨두고, 이동 판단에서는 Y축 변화만 사용
            best_shot_data = max(valid_detections, key=lambda d: get_area(d['bounding_box']))

            # 🚨 [수정된 부분] 입고/출고 판단 로직 (Y 일관성 검증 제거)

            # --- 출고 후보 (Y축 증가, delta_y_movement 음수) ---
            if delta_y_movement < -Y_MIN_MOVEMENT:
                # is_consistent_outbound 로직 제거됨

                if is_significant_movement:  # 이동량만으로 판단
                    determined_status = 'outbound'
                    log_msg = f"✅ 출고 확정(3+): Y 방향성 O, 이동량:{total_y_range:.0f} | Gap: {delta_y_movement:.0f}"
                else:
                    determined_status = 'uncertain_conflict'
                    log_msg = f"❌ [결론] 출고 불확실 (원인: 이동량 부족)"

            # --- 입고 후보 (Y축 감소, delta_y_movement 양수) ---
            elif delta_y_movement > Y_MIN_MOVEMENT:
                # is_consistent_inbound 로직 제거됨

                if is_significant_movement:  # 이동량만으로 판단
                    determined_status = 'inbound'
                    log_msg = f"✅ 입고 확정(3+): Y 방향성 O, 이동량:{total_y_range:.0f} | Gap: +{delta_y_movement:.0f}"
                else:
                    determined_status = 'uncertain_conflict'
                    log_msg = f"❌ [결론] 입고 불확실 (원인: 이동량 부족)"

            else:
                determined_status = 'uncertain_adjust'
                log_msg = f"⚠️ 이동 미미 (조정 추정): Gap: {delta_y_movement:.0f}"
                if delta_y_movement > 0:
                    ACTION_DETAIL_LOG.append(f"❌ 입고: Y축 이동량 미달 (Gap: +{delta_y_movement:.0f})")
                elif delta_y_movement < 0:
                    ACTION_DETAIL_LOG.append(f"❌ 출고: Y축 이동량 미달 (Gap: {delta_y_movement:.0f})")

            logger.info(log_msg)
            ACTION_DETAIL_LOG.append(log_msg)

        else:
            # Case 2: 2장 탐지 (Y축 이동량만 사용)

            # 입고 (Y축 감소, delta_y_movement 양수)
            is_inbound_coherent = (delta_y_movement > Y_MIN_MOVEMENT)

            # 출고 (Y축 증가, delta_y_movement 음수)
            is_outbound_coherent = (delta_y_movement < -Y_MIN_MOVEMENT)

            if is_inbound_coherent:
                determined_status = 'inbound'
                log_msg = f"✅ 입고 확정(2프레임): Y:{delta_y_movement:.0f}"

            elif is_outbound_coherent:
                determined_status = 'outbound'
                log_msg = f"✅ 출고 확정(2프레임): Y:{delta_y_movement:.0f}"

            else:
                determined_status = 'uncertain_conflict'
                if abs(delta_y_movement) < Y_THRESHOLD: ACTION_DETAIL_LOG.append(
                    f"❌ 2프레임: Y축 이동량 미미 (Gap: {delta_y_movement:.0f})")
                if not is_inbound_coherent and not is_outbound_coherent: ACTION_DETAIL_LOG.append(
                    f"❌ 2프레임: Y 이동량 미달 (Y:{delta_y_movement:.0f})")
                log_msg = f"❌ [결론] 이동 불확실 (2프레임 충돌)"

            logger.info(log_msg)
            ACTION_DETAIL_LOG.append(log_msg)

    # ---------------------------------------------------------
    # [분석 2] Best Shot 선정 및 층수 판단 (🚨 X/Y 교환 로직 - 입고 제스처 로직 제거됨)
    # ---------------------------------------------------------
    if valid_detections:
        # 1. 층수 판단 (X축 중심 위치 기반)
        first_box = valid_detections[0]['bounding_box']
        last_box = valid_detections[-1]['bounding_box']

        # 🚨 [X/Y 교환] X축 중심 위치를 층수 판단의 기준으로 사용
        start_x_center = (first_box[0] + first_box[2]) / 2
        end_x_center = (last_box[0] + last_box[2]) / 2
        # delta_x_layer = start_x_center - end_x_center # 🚨 제스처 분석 제거로 사용 안함

        # 층 판단 제스처 임계값
        GESTURE_THRESHOLD_X = ACTUAL_LAYER_DIMENSION * 0.05

        # [수정] FRAME_CENTER_X를 동적 해상도 기반으로 계산
        FRAME_CENTER_X = ACTUAL_LAYER_DIMENSION * 0.5

        # -----------------------------------------------------------
        # 3. 🗳️ 신뢰도 가중치 투표 (Weighted Voting) - Best Shot 선정 전에 실행 (동일)
        # -----------------------------------------------------------
        score_board = {}

        for d in valid_detections:
            name = d['category_name']
            conf = d['confidence']
            score_board[name] = score_board.get(name, 0) + conf

        most_weighted_category = max(score_board, key=score_board.get)

        winner_scores = [
            d['confidence']
            for d in valid_detections
            if d['category_name'] == most_weighted_category
        ]
        winner_max_conf = max(winner_scores) if winner_scores else 0.0

        FINAL_CUTOFF = 0.4

        # -----------------------------------------------------------
        # 2. OCR용 Best Shot 선정 (스코어링 기반으로 변경 + 투표 결과 필터링) (동일)
        # -----------------------------------------------------------

        winning_detections = [
            d for d in valid_detections if d['category_name'] == most_weighted_category
        ]

        # B) Best Shot 스코어링 고도화 로직
        if winning_detections:
            all_areas_winning = [get_area(d['bounding_box']) for d in winning_detections]
            max_area = max(all_areas_winning) if all_areas_winning else 1.0

            center_x_img = image_width / 2
            center_y_img = image_height / 2
            max_possible_distance = math.sqrt(center_x_img ** 2 + center_y_img ** 2)

            WEIGHT_AREA = 0.8
            WEIGHT_CENTER = 0.2

            def calculate_best_shot_score(data_point):
                box = data_point['bounding_box']
                current_area = get_area(box)
                current_center_x = get_center_x(box)
                current_center_y = (box[1] + box[3]) / 2

                # 1. 면적 정규화 (Area)
                norm_area = current_area / max_area

                # 2. 중앙 배치 정규화 (Centering)
                distance_px = math.sqrt(
                    (current_center_x - center_x_img) ** 2 + (current_center_y - center_y_img) ** 2
                )
                norm_centering = 1.0 - (distance_px / max_possible_distance)

                # 3. [보완] 테두리 근접성 페널티 (Boundary Proximity Penalty)
                # 이미지 해상도(width, height)의 5% 이내에 박스가 위치하면 페널티 적용
                MARGIN_RATIO = 0.05
                width, height = image_width, image_height  # 외부 변수 사용 가정

                # 박스가 이미지 상/하/좌/우 테두리에 5% 마진 내로 근접했는지 확인
                is_too_close = (box[0] < width * MARGIN_RATIO or  # xmin이 왼쪽 테두리에 근접
                                box[2] > width * (1 - MARGIN_RATIO) or  # xmax가 오른쪽 테두리에 근접
                                box[1] < height * MARGIN_RATIO or  # ymin이 위쪽 테두리에 근접
                                box[3] > height * (1 - MARGIN_RATIO))  # ymax가 아래쪽 테두리에 근접

                # 테두리에 근접하면 스코어를 강하게 낮춤
                penalty = 0.5 if is_too_close else 1.0

                # 4. 최종 스코어 계산 (페널티 적용)
                score = ((WEIGHT_AREA * norm_area) + (WEIGHT_CENTER * norm_centering)) * penalty
                return score

            best_shot_data = max(winning_detections, key=calculate_best_shot_score)

        else:
            best_shot_data = max(valid_detections, key=lambda x: get_area(x['bounding_box']))

        target_path = best_shot_data['file_path']
        target_yolo_result = best_shot_data

        if winner_max_conf < FINAL_CUTOFF:
            logger.warning(f"⚠️ [검증 실패] 우승자({most_weighted_category}) 신뢰도({winner_max_conf:.2f})가 너무 낮음 -> 미확인 처리")
            target_yolo_result['category_name'] = '식재료 미확인'

        elif target_yolo_result['category_name'] != most_weighted_category:
            logger.info(f"🗳️ [투표 보정] {target_yolo_result['category_name']} -> {most_weighted_category} (점수 1위)로 변경")
            target_yolo_result['category_name'] = most_weighted_category

        # 🚨 [X/Y 교환] 층수 판단 (수정됨: X값이 클수록 1층)
        # NOTE: 이 로직은 층수 판단이 반대로 나왔던 문제를 해결합니다.
        if len(valid_detections) == 1:
            determined_layer = 1 if end_x_center < FRAME_CENTER_X else 2
            ACTION_DETAIL_LOG.append(f"층판단: 단일 프레임 X 위치 기반 ({determined_layer}층) - 최종 수정")

        elif determined_status == 'outbound':  # 출고 확정 시: 시작 위치(start_x_center) 기준 (유지)
            determined_layer = 1 if start_x_center < FRAME_CENTER_X else 2
            ACTION_DETAIL_LOG.append(f"층판단: 출고 시작 X 위치 ({determined_layer}층) - 최종 수정")

        else:  # 입고 및 모든 불확실 상태 포함 (X 제스처 분석 제거)

            # 🚨 [수정된 로직] 제스처 분석을 완전히 생략하고 최종 위치만 사용
            determined_layer = 1 if end_x_center < FRAME_CENTER_X else 2
            ACTION_DETAIL_LOG.append(f"층판단: 제스처 분석 생략. 최종 X 위치 기반 ({determined_layer}층) - 최종 수정")

    else:
        # 인식 실패 시 Fallback
        target_yolo_result = {
            'bounding_box': [0, 0, 0, 0],
            'category_name': 'FALLBACK_MODE',
            'fallback_mode': True
        }

    # ---------------------------------------------------------
    # 📝 데이터 구성 및 OCR 실행
    # ---------------------------------------------------------
    if target_yolo_result is None:
        target_yolo_result = {'category_name': 'FALLBACK_MODE', 'fallback_mode': True, 'bounding_box': [0, 0, 0, 0]}

    if target_path is None:
        if image_paths:
            target_path = image_paths[-1]
        else:
            return {'error': 'No images found'}

    result_data = {
        'user_id': user_id,
        'stored_at': date.today(),
        'ingredient_name': '',
        'category_yolo': None,
        'product_name_ocr': None,
        'expiry_date': None,
        'expiry_date_status': 'NOT_FOUND',
        'ingredient_pic': target_path,
        'layer': determined_layer,
        'status': determined_status,

        # 서버 내부 분석에서 사용된 값 (교환 전)
        'raw_start_x': start_x_center if 'start_x_center' in locals() else 0.0,
        'raw_end_x': end_x_center if 'end_x_center' in locals() else 0.0,
        'raw_start_y': start_y_center if 'start_y_center' in locals() else 0.0,
        'raw_end_y': end_y_center if 'end_y_center' in locals() else 0.0,
    }

    # OCR 실행
    ocr_raw_output = run_ocr(target_path, target_yolo_result)

    # 정보 추출 및 통합
    ocr_info = extract_ocr_info(ocr_raw_output)

    # 🚨 [최종 결과 재매핑] RPi 로그 출력 편의를 위해 X/Y 최종 교환
    result_data_for_final = {
        **result_data,
        'raw_start_x': result_data.get('raw_start_y', 0.0),  # 이미지 Y축 (이동)
        'raw_end_x': result_data.get('raw_end_y', 0.0),  # 이미지 Y축 (이동)
        'raw_start_y': result_data.get('raw_start_x', 0.0),  # 이미지 X축 (층수)
        'raw_end_y': result_data.get('raw_end_x', 0.0),  # 이미지 X축 (층수)
    }

    final_data = integrate_results(result_data_for_final, target_yolo_result, ocr_info, ocr_raw_output,
                                   ACTION_DETAIL_LOG)
    original_cropped_path = ocr_raw_output.get('cropped_image_path')

    if original_cropped_path:
        try:
            old_full_path = os.path.join(settings.MEDIA_ROOT, original_cropped_path)
            timestamp_str = datetime.now().strftime("%Y%m%d_%H%M%S")
            ingredient_name = final_data.get('ingredient_name', '미확인')
            safe_name = ingredient_name.replace(" ", "_")
            new_crop_filename = f"{timestamp_str}_{safe_name}_cropped.jpg"
            new_full_path = os.path.join(settings.MEDIA_ROOT, 'cropped_for_ui', new_crop_filename)

            if os.path.exists(old_full_path):
                os.rename(old_full_path, new_full_path)
                final_data['cropped_ingredient_pic'] = f"cropped_for_ui/{new_crop_filename}"
            else:
                final_data['cropped_ingredient_pic'] = original_cropped_path

        except Exception as e:
            print(f"⚠️ 크롭 이미지 리네임 실패: {e}")
            final_data['cropped_ingredient_pic'] = original_cropped_path
    else:
        final_data['cropped_ingredient_pic'] = None

    return final_data


# 2. ② YOLO 모델 적용 (객체 탐지)
def run_yolo_detection(image_path: str) -> Dict[str, Any]:
    model = SrmappConfig.yolo_model

    if model is None:
        return None

    try:
        results = model.predict(source=image_path, imgsz=416, conf=0.15, iou=0.5, verbose=True)

        if not results or not results[0].boxes:
            return None

        box = results[0].boxes[0]
        xmin, ymin, xmax, ymax = map(int, box.xyxy[0].tolist())
        confidence = float(box.conf[0])
        class_index = int(box.cls[0])
        category_name = model.names[class_index]

        logger.debug(f"DEBUG: Extracted YOLO Confidence: {confidence}")

        return {
            'category_name': category_name,
            'confidence': confidence,
            'bounding_box': [xmin, ymin, xmax, ymax],
        }

    except Exception as e:
        logger.error(f"YOLO detection error: {e}")
        return None


# 3. ③ OCR 모델 적용 (이미지 크롭 및 텍스트 인식)
def run_ocr(image_path: str, yolo_result: Dict[str, Any]) -> Dict[str, Any]:
    word_blocks: List[Dict[str, Any]] = []

    cropped_for_ui_dir = os.path.join(settings.MEDIA_ROOT, 'cropped_for_ui')
    os.makedirs(cropped_for_ui_dir, exist_ok=True)
    base_name = os.path.splitext(os.path.basename(image_path))[0]
    cropped_filename = f'{base_name}_cropped.jpg'
    cropped_image_path_full = os.path.join(cropped_for_ui_dir, cropped_filename)
    cropped_image_relative_path = os.path.join('cropped_for_ui', cropped_filename).replace('\\', '/')

    try:
        os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = str(settings.GOOGLE_APPLICATION_CREDENTIALS)
    except AttributeError:
        logger.error("Error: GOOGLE_APPLICATION_CREDENTIALS KEY missing")
        return {'raw_text': "Error: KEY missing", 'word_blocks': word_blocks, 'cropped_image_path': None}

    try:
        img_array = np.fromfile(image_path, np.uint8)
        image_cv = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
    except Exception as e:
        logger.error(f"Error: Image read failed {e}")
        return {"raw_text": f"Error: Image read failed {e}", 'word_blocks': word_blocks, 'cropped_image_path': None}

    if yolo_result.get('fallback_mode'):
        height, width = image_cv.shape[:2]
        xmin, ymin, xmax, ymax = 0, 0, width, height
    else:
        bounding_box = yolo_result.get('bounding_box', [0, 0, 0, 0])
        xmin, ymin, xmax, ymax = bounding_box

    try:
        cropped_image = image_cv[ymin:ymax, xmin:xmax]
        cv2.imwrite(cropped_image_path_full, cropped_image)
        is_success, buffer = cv2.imencode(".png", cropped_image)
        if not is_success:
            logger.error("Image encode fail")
            return {'raw_text': "Encode fail", 'word_blocks': word_blocks, 'cropped_image_path': None}

        image_bytes = buffer.tobytes()
        client = vision.ImageAnnotatorClient()
        image = vision.Image(content=image_bytes)
        image_context = vision.ImageContext(language_hints=["ko"])
        response = client.annotate_image(
            request={'image': image, 'features': [{'type_': vision.Feature.Type.DOCUMENT_TEXT_DETECTION}],
                     'image_context': image_context})

        raw_text = ""
        if response.full_text_annotation:
            raw_text = response.full_text_annotation.text

            document = response.full_text_annotation
            for page in document.pages:
                for block in page.blocks:
                    for paragraph in block.paragraphs:
                        for word in paragraph.words:
                            word_text = ''.join([symbol.text for symbol in word.symbols])
                            word_blocks.append({
                                'text': word_text,
                                'confidence': word.confidence,
                                'bounds': [(v.x, v.y) for v in word.bounding_box.vertices]
                            })
            return {'raw_text': raw_text, 'word_blocks': word_blocks, 'cropped_image_path': cropped_image_relative_path}
        return {'raw_text': '', 'word_blocks': word_blocks, 'cropped_image_path': cropped_image_relative_path}
    except Exception as e:
        logger.error(f"OCR execution error: {e}")
        return {"raw_text": f"Error: {e}", 'word_blocks': word_blocks, 'cropped_image_path': None}


# ④ 정보 추출 및 가공

def get_center(bounds: List[tuple]) -> tuple:
    x_coords = [v[0] for v in bounds]
    y_coords = [v[1] for v in bounds]
    center_x = sum(x_coords) / len(x_coords)
    center_y = sum(y_coords) / len(y_coords)
    return (center_x, center_y)


def calculate_distance(block1: Dict, block2: Dict) -> float:
    center1 = get_center(block1['bounds'])
    center2 = get_center(block2['bounds'])
    return math.sqrt((center1[0] - center2[0]) ** 2 + (center1[1] - center2[1]) ** 2)


# 4-1. 유통기한 패턴 설정
DATE_PATTERNS = [
    r'(?:소비기한|유통기한)\s*[:]?\s*(\d{4})[년./-]\s*(\d{1,2})[월./-]\s*(\d{1,2})[일]?(?:\s+\d{2}:\d{2}(?::\d{2})?)?[.]?',
    r'(\d{4})년\s*(\d{1,2})월\s*(\d{1,2})일(?:\s+\d{2}:\d{2}(?::\d{2})?)?[.]?',
    r'(\d{2})년\s*(\d{1,2})월\s*(\d{1,2})일(?:\s+\d{2}:\d{2}(?::\d{2})?)?[.]?',
    r'(\d{4})[년./-]\s*(\d{1,2})[월./-]\s*(\d{1,2})[일]?\s*까지(?:\s+\d{2}:\d{2}(?::\d{2})?)?[.]?',
    r'(\d{4})[./-]([01]?\d)[./-]([0-3]?\d)(?:\s+\d{2}:\d{2}(?::\d{2})?)?[.]?',
    r'(\d{2})[./-]([01]?\d)[./-]([0-3]?\d)(?:\s+\d{2}:\d{2}(?::\d{2})?)?[.]?',
    r'(\d{4})(\d{2})(\d{2})(?:\s+\d{2}:\d{2}(?::\d{2})?)?[.]?',
    r'(\d{2})(\d{2})(\d{2})(?:\s+\d{2}:\d{2}(?::\d{2})?)?[.]?',
    r'([01]?\d)[./]([0-3]?\d)[.]?'
]


# 4-2. 유통기한 텍스트 탐지
def extract_ocr_info(ocr_raw_output: Dict[str, Any]) -> Dict[str, Any]:
    raw_text = ocr_raw_output.get('raw_text', '')
    word_blocks = ocr_raw_output.get('word_blocks', [])

    INDICATOR_KEYWORDS = ['까지', '기한', '유통', '소비', '유통기한', '소비기한']

    found_dates_info = []
    found_keywords_info = []

    for block in word_blocks:
        if any(keyword in block['text'] for keyword in INDICATOR_KEYWORDS):
            found_keywords_info.append(block)

        for pattern in DATE_PATTERNS:
            match = re.search(pattern, block['text'])
            if match:
                date_parts = list(match.groups())
                date_text = match.group(0)

                pure_digits = re.sub(r'[^0-9]', '', date_text)
                if len(pure_digits) > 10:
                    continue

                try:
                    parsed_date = None
                    date_format_parts = 0
                    today = date.today()

                    if len(date_parts) == 3:
                        year, month, day = map(int, date_parts)
                        if year < 100: year += 2000
                        parsed_date = date(year, month, day)
                        date_format_parts = 3
                    elif len(date_parts) == 2:
                        month, day = map(int, date_parts)

                        try:
                            parsed_date = date(today.year, month, day)

                            if parsed_date < today:
                                days_diff = (today - parsed_date).days
                                if days_diff > 30:
                                    parsed_date = date(today.year + 1, month, day)
                        except ValueError:
                            continue

                        date_format_parts = 2

                    if parsed_date and 2000 <= parsed_date.year <= 2100:
                        found_dates_info.append((parsed_date, block, date_format_parts))
                        break
                except ValueError:
                    continue

    best_date = None
    recognition_confidence = 0.0
    type_confidence = 0.5
    filtered_word_blocks = []

    if found_dates_info:
        sorted_dates = sorted(found_dates_info, key=lambda item: item[0], reverse=True)

        for candidate_date, date_block, date_parts_count in sorted_dates:
            today = date.today()
            if candidate_date.year > today.year + 5 or candidate_date.year < today.year - 3:
                continue

            is_nutrition_info = False
            text_height = abs(date_block['bounds'][0][1] - date_block['bounds'][2][1])
            SEARCH_RADIUS = text_height * 3

            for block in word_blocks:
                if block == date_block: continue
                if any(keyword in block['text'] for keyword in EXCLUSION_KEYWORDS):
                    if calculate_distance(date_block, block) < SEARCH_RADIUS:
                        is_nutrition_info = True
                        break
            if is_nutrition_info:
                continue

            best_date = candidate_date
            best_date_block = date_block
            recognition_confidence = best_date_block['confidence']
            filtered_word_blocks.append(best_date_block)

            min_distance = float('inf')
            closest_keyword_block = None
            if found_keywords_info:
                for keyword_block in found_keywords_info:
                    distance = calculate_distance(date_block, keyword_block)
                    if distance < min_distance:
                        min_distance = distance
                        closest_keyword_block = keyword_block

            DISTANCE_THRESHOLD = text_height * 5
            if min_distance < DISTANCE_THRESHOLD:
                type_confidence = 1.0
                if closest_keyword_block and closest_keyword_block not in filtered_word_blocks:
                    filtered_word_blocks.append(closest_keyword_block)
            elif best_date > date.today():
                type_confidence = 0.8
            break

    return {
        'extracted_date': best_date,
        'date_recognition_confidence': round(recognition_confidence, 4),
        'date_type_confidence': type_confidence,
        'raw_ocr_text': raw_text,
        'filtered_word_blocks': filtered_word_blocks,
    }


# 4-3. Word2Vec을 이용한 색재료명 추출
def extract_product_name(raw_text: str, yolo_category: str, product_candidate_blocks: List[Dict[str, Any]]) -> Dict[
    str, Any]:
    model = SrmappConfig.word_embedding_model
    ANCHOR_WORD = '식재료'
    SIMILARITY_THRESHOLD = 0.5

    if model is None:
        logger.warning('Word Embedding Model Not Loaded')
        return {'name': 'Word Embedding Model Not Loaded', 'similarity': 0.0}

    if ANCHOR_WORD not in model.wv:
        logger.warning('Anchor Word Missing in Word Embedding Model')
        return {'name': 'Anchor Word Missing', 'similarity': 0.0}

    valid_words = []

    for target_block in product_candidate_blocks:
        if not target_block['text']: continue
        is_nutrition_value = False
        text_height = abs(target_block['bounds'][0][1] - target_block['bounds'][2][1])
        SEARCH_RADIUS = text_height * 3

        is_numeric_like = re.match(r'[\d\.\,]+[gmkcal%]', target_block['text'], re.IGNORECASE)

        if is_numeric_like:
            for block in product_candidate_blocks:
                if block == target_block: continue
                if any(keyword in block['text'] for keyword in EXCLUSION_KEYWORDS):
                    if calculate_distance(target_block, block) < SEARCH_RADIUS:
                        is_nutrition_value = True
                        break

        if not is_nutrition_value:
            word = re.sub(r'[^가-힣a-zA-Z]', '', target_block['text'])
            if len(word) > 1 and word in model.wv and word != ANCHOR_WORD:
                valid_words.append(word)

    if not valid_words:
        return {'name': None, 'similarity': 0.0}

    best_match = None
    max_similarity = -1

    for word in set(valid_words):
        try:
            similarity = model.wv.similarity(ANCHOR_WORD, word)
            if similarity > max_similarity:
                max_similarity = similarity
                best_match = word
        except Exception as e:
            logger.debug(f"Similarity calculation failed for {word}: {e}")
            continue

    if best_match and max_similarity >= SIMILARITY_THRESHOLD:
        final_confidence = round(max_similarity, 4)
        logger.info(f"✅ Product Name Found via Word Embedding: {best_match} (Similarity: {max_similarity:.2f})")
        return {'name': best_match, 'similarity': final_confidence}

    else:
        return {'name': 'Word Embedding Model Not Loaded', 'similarity': 0.0}


# 5. 결과 통합 및 신뢰도 분기 처리
def integrate_results(base_data: Dict[str, Any], yolo_result: Dict[str, Any], ocr_info: Dict[str, Any],
                      ocr_raw_output: Dict[str, Any], ACTION_DETAIL_LOG: List[str]) -> Dict[str, Any]:
    yolo_category = yolo_result.get('category_name', '식재료 미확인')
    yolo_confidence = yolo_result.get('confidence', None)

    raw_ocr_text = ocr_info.get('raw_ocr_text', '')
    all_word_blocks = ocr_raw_output.get('word_blocks', [])

    date_blocks_to_exclude = ocr_info.get('filtered_word_blocks', [])

    product_candidate_blocks = [
        block for block in all_word_blocks
        if block not in date_blocks_to_exclude
    ]

    product_result = extract_product_name(raw_ocr_text, yolo_category, product_candidate_blocks)

    final_product_name = product_result['name']
    product_similarity_score = product_result['similarity']

    best_fuzz_match = None
    max_fuzz_score = -1.0

    YOLO_CONFIDENCE_THRESHOLD = 0.70  # YOLO 강제 확정 기준
    YOLO_MIN_FALLBACK_CONFIDENCE = 0.40  # YOLO 최소 감지 기준
    PRODUCT_SIMILARITY_THRESHOLD = 0.65

    standard_db_names = get_standard_ingredient_list()

    candidate_name = None

    determined_ingredient_name = '식재료 미확인'
    is_ocr_based_determination = False # <<--- 플래그 추가

    # 1. (최우선) YOLO 강제 확정: YOLO 신뢰도가 0.7 이상일 경우
    if yolo_category not in ['FALLBACK_MODE', '식재료 미확인'] and \
            yolo_confidence is not None and yolo_confidence >= YOLO_CONFIDENCE_THRESHOLD:

        determined_ingredient_name = yolo_category
        ACTION_DETAIL_LOG.append(
            f"✅ YOLO 강제 확정: 신뢰도 {yolo_confidence:.2f} > {YOLO_CONFIDENCE_THRESHOLD} 이므로 {yolo_category} 사용")

    else:
        # YOLO가 낮거나 미확인일 경우에만 OCR/Word2Vec 경로 사용

        # 1-1. Levenshtein 검증 대상: OCR 결과(final_product_name)만 사용
        candidate_name = final_product_name

        # 2. Levenshtein 유사도 검증 (OCR 텍스트가 DB 표준명과 오타 보정될 때)
        if candidate_name:
            for db_name in standard_db_names:
                score = Levenshtein.ratio(candidate_name, db_name)
                if score > max_fuzz_score:
                    max_fuzz_score = score
                    best_fuzz_match = db_name

        if max_fuzz_score >= TYPO_THRESHOLD and best_fuzz_match:
            determined_ingredient_name = best_fuzz_match
            is_ocr_based_determination = True # <<--- OCR 기반 확정
            ACTION_DETAIL_LOG.append(f"✅ Levenshtein 확정: DB 표준명 {best_fuzz_match}로 오타 보정")

        # 3. Word2Vec 신뢰도 기반 확정 (Levenshtein 실패했으나 Word2Vec은 높을 때)
        elif final_product_name and product_similarity_score >= PRODUCT_SIMILARITY_THRESHOLD:
            determined_ingredient_name = final_product_name
            is_ocr_based_determination = True # <<--- OCR 기반 확정
            ACTION_DETAIL_LOG.append(f"✅ Word2Vec 확정: 유사도 {product_similarity_score:.2f}로 {final_product_name} 사용")

        # 4. YOLO 신뢰도 기준 미달이나 fallback으로 YOLO 사용 (0.4 ~ 0.7 사이)
        elif yolo_category not in ['FALLBACK_MODE', '식재료 미확인'] and \
                yolo_confidence is not None and yolo_confidence >= YOLO_MIN_FALLBACK_CONFIDENCE:
            determined_ingredient_name = yolo_category
            ACTION_DETAIL_LOG.append(f"⚠️ YOLO 폴백 사용: {yolo_confidence:.2f} (최소 {YOLO_MIN_FALLBACK_CONFIDENCE} 통과)")

    # ------------------------------------------------------------------------------------
    # 🚨 [YOLO 0.4 미달 강제 미확인 로직] 최종 확정 후 신뢰도 미달 시 취소 (수정된 로직)

    if determined_ingredient_name != '식재료 미확인':
        # 1. DB 표준명으로 정규화
        determined_ingredient_name = get_standard_name(determined_ingredient_name)

        # 2. 🚨 [추가 검증]: YOLO 신뢰도가 0.4 미만일 경우 강제 미확인 처리
        #     OCR 기반 확정(is_ocr_based_determination == True)인 경우는 이 로직을 통과시킴
        if (not is_ocr_based_determination) and \
           yolo_confidence is not None and yolo_confidence < YOLO_MIN_FALLBACK_CONFIDENCE:

            if yolo_category not in ['FALLBACK_MODE', '식재료 미확인']:
                ACTION_DETAIL_LOG.append(
                    f"❌ 확정 취소: YOLO 기반 확정이었으나 YOLO 신뢰도({yolo_confidence:.2f})가 최소 기준({YOLO_MIN_FALLBACK_CONFIDENCE}) 미달."
                )
                determined_ingredient_name = '식재료 미확인'

    recognition_conf = ocr_info.get('date_recognition_confidence', 0.0)
    type_conf = ocr_info.get('date_type_confidence', 0.0)
    extracted_date = ocr_info.get('extracted_date')

    FINAL_DATE_CONFIDENCE = recognition_conf * type_conf
    FINAL_CONFIDENCE_THRESHOLD = 0.60

    expiry_date_status = 'NOT_FOUND'

    if extracted_date:

        if extracted_date < date.today():
            expiry_date_status = 'EXPIRED'
        elif FINAL_DATE_CONFIDENCE >= FINAL_CONFIDENCE_THRESHOLD:
            expiry_date_status = 'CONFIRMED'
        else:
            expiry_date_status = 'UNCERTAIN'

    if extracted_date:
        ACTION_DETAIL_LOG.append(f"✅ 유통기한: {extracted_date} ({expiry_date_status})")
        ACTION_DETAIL_LOG.append(f"💰 유통기한 신뢰도: {FINAL_DATE_CONFIDENCE:.2f}")
    else:
        ACTION_DETAIL_LOG.append("❌ 유통기한 탐지 실패")

    current_status = base_data.get('status')

    if current_status in ['uncertain_adjust', 'uncertain_conflict', 'FALLBACK_MODE']:
        log_msg = f"⚠️ 상태 : 기본값(inbound) 사용"
        logger.warning(log_msg)
        ACTION_DETAIL_LOG.append(log_msg)

        base_data['status'] = 'inbound'

    final_data = {
        'user_id': base_data['user_id'],

        'layer': base_data.get('layer'),
        'status': base_data.get('status'),

        'ingredient_pic': base_data['ingredient_pic'],
        'stored_at': base_data['stored_at'],

        'ingredient_name': determined_ingredient_name,

        'category_yolo': yolo_category,
        'yolo_confidence': yolo_confidence,

        'product_name_ocr': final_product_name,
        'product_similarity_score': product_similarity_score,

        'expiry_date': extracted_date,
        'expiry_date_status': expiry_date_status,
        'date_recognition_confidence': recognition_conf,
        'date_type_confidence': type_conf,
        'final_date_confidence': round(FINAL_DATE_CONFIDENCE, 4),

        'raw_ocr_text': raw_ocr_text,
        'ocr_word_blocks': ocr_info.get('filtered_word_blocks'),

        # 🚨 [최종 결과 재매핑] RPi 로그 출력 편의를 위해 X/Y 최종 교환
        'raw_start_x': base_data.get('raw_start_y', 0.0),  # 이미지 Y축 (이동)
        'raw_end_x': base_data.get('raw_end_y', 0.0),  # 이미지 Y축 (이동)
        'raw_start_y': base_data.get('raw_start_x', 0.0),  # 이미지 X축 (층수)
        'raw_end_y': base_data.get('raw_end_x', 0.0),  # 이미지 X축 (층수)
    }
    final_data['decision_log'] = " | ".join(ACTION_DETAIL_LOG)

    original_cropped_path = ocr_raw_output.get('cropped_image_path')

    if original_cropped_path:
        try:
            old_full_path = os.path.join(settings.MEDIA_ROOT, original_cropped_path)
            timestamp_str = datetime.now().strftime("%Y%m%d_%H%M%S")
            ingredient_name = final_data.get('ingredient_name', '미확인')
            safe_name = ingredient_name.replace(" ", "_")
            new_crop_filename = f"{timestamp_str}_{safe_name}_cropped.jpg"
            new_full_path = os.path.join(settings.MEDIA_ROOT, 'cropped_for_ui', new_crop_filename)

            if os.path.exists(old_full_path):
                os.rename(old_full_path, new_full_path)
                final_data['cropped_ingredient_pic'] = f"cropped_for_ui/{new_crop_filename}"
            else:
                final_data['cropped_ingredient_pic'] = original_cropped_path

        except Exception as e:
            print(f"⚠️ 크롭 이미지 리네임 실패: {e}")
            final_data['cropped_ingredient_pic'] = original_cropped_path
    else:
        final_data['cropped_ingredient_pic'] = None

    return final_data