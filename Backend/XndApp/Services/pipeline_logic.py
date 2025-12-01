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
import logging
# [추가] 병렬 처리를 위한 모듈 임포트
from concurrent.futures import ThreadPoolExecutor

logger = logging.getLogger('PipelineLogic')
logger.setLevel(logging.INFO)

CACHED_INGREDIENT_LIST = None

# 식재료명/유통기한 인식에서 제외할 키워드 (영양성분 + 제조시설/경고 문구)
EXCLUSION_KEYWORDS = [
    '나트륨', '탄수화물', '당류', '지방', '트랜스지방', '포화지방',
    '콜레스테롤', '단백질', '칼슘', '열량', 'g', 'mg', 'kcal', '%',
    '제조시설', '사용된', '시설에서', '원재료', '함유', '알레르기', '성분', '주의', '사용할', '수', '있습니다', '제품은', '원재료명',
    '부정', '불량'
]

STANDARD_MAP = {
    # 인식 : 표준
    "계란": "달걀",
    "케챂": "케첩",
    "케찹": "케첩",
    "고추가루": "고춧가루"
}


# ====================================================================
# [수정] 전역 헬퍼 함수 정의 (Area, Center_X)
# ====================================================================
def get_area(box: List[int]) -> int:
    """바운딩 박스 면적 계산"""
    return (box[2] - box[0]) * (box[3] - box[1])


def get_center_x(box: List[int]) -> float:
    """바운딩 박스 중심 X 좌표 계산"""
    return (box[0] + box[2]) / 2


# ====================================================================


def get_standard_ingredient_list() -> List[str]:
    """
    DB에서 표준 식재료 목록을 가져오되, 한 번 로드된 후에는 메모리에서 반환합니다.
    (첫 호출 시에만 DB 접근)
    """
    global CACHED_INGREDIENT_LIST
    # 1. 캐시가 이미 존재하면 메모리에서 즉시 반환
    if CACHED_INGREDIENT_LIST is not None:
        return CACHED_INGREDIENT_LIST

    # 2. 캐시가 없으면 DB에 접근하여 로드
    try:
        # Django Model이 import된다고 가정
        from XndApp.Models.foodStorageLife import FoodStorageLife
        CACHED_INGREDIENT_LIST = list(FoodStorageLife.objects.values_list('name', flat=True).distinct())
        return CACHED_INGREDIENT_LIST
    except Exception as e:
        logger.warning(f"Warning: DB Error during initial load. Using fallback list: {e}")
        # DB 접근 실패 시 최소한의 대체 목록 사용 (Fallback)
        return ['케첩', '두부', '파스타면', '쌀', '계란']


def get_standard_name(ingredient_name: str) -> str:
    return STANDARD_MAP.get(ingredient_name, ingredient_name)


TYPO_THRESHOLD = 0.85  # Fuzz 교정 임계값


# 1. 메인 파이프라인 함수
# [수정] image_width와 image_height 인자를 추가
def process_image_pipeline(user_id: int, image_paths: List[str], layer: str, image_width: int = 1920,
                           image_height: int = 1080, action_type: str = 'analyzing') -> Dict[
    str, Any]:
    # 1. 모든 이미지에 대해 YOLO 수행 (병렬 처리 적용)
    yolo_results = []

    # [수정] 병렬 처리를 위한 ThreadPoolExecutor 사용
    with ThreadPoolExecutor(max_workers=os.cpu_count() or 4) as executor:
        # 모든 이미지 경로에 대해 run_yolo_detection을 비동기적으로 실행
        futures = {executor.submit(run_yolo_detection, path): path for path in image_paths}

        # 완료된 작업의 결과를 수집 (원래 순서대로 수집하지 않음)
        for future in futures:
            result = future.result()
            if result:
                result['file_path'] = futures[future]  # 파일 경로를 결과에 다시 매핑
                yolo_results.append(result)

    # 2. [수정] YOLO 결과의 순서를 이미지 경로 순서와 맞춥니다 (궤적 분석을 위해 필수)
    # 이미지 경로를 기준으로 yolo_results를 정렬합니다.
    path_to_result = {res['file_path']: res for res in yolo_results}
    valid_detections = [path_to_result[path] for path in image_paths if path in path_to_result]

    ACTION_DETAIL_LOG = []

    # 좌표 변수 초기화
    start_x = 0.0
    end_x = 0.0
    start_y = 0.0
    end_y = 0.0

    determined_status = 'inbound'
    determined_layer = int(layer)

    target_path = image_paths[-1] if image_paths else None
    target_yolo_result = None

    # ====================================================================
    # [분석 1] 이동 방향 판단 (옆벽 부착 환경 최적화 로직으로 대체)
    # ====================================================================

    # --- [수정] 비율 기반 임계값 정의 ---
    # 비율 설정
    RATIO_X_THRESHOLD = 0.010  # 1.0% (1920x1080 기준 약 19px)
    RATIO_X_MIN_MOVEMENT = 0.015  # 1.5% (1920x1080 기준 약 28px)

    # 해상도에 따른 픽셀 값 변환
    X_THRESHOLD = image_width * RATIO_X_THRESHOLD
    X_MIN_MOVEMENT = image_width * RATIO_X_MIN_MOVEMENT
    AREA_THRESHOLD = 500  # Area 최소 변화 임계값 (픽셀^2, 픽셀 단위 유지)
    AREA_PEAK_DROP_RATIO = 0.1  # Peak 대비 End Area가 이 비율만큼 작아져야 완료로 인정 (30%)

    # ------------------------------------

    if len(valid_detections) == 0:
        msg = "❌ 인식된 객체 없음: (기본값)"
        logger.error(msg)
        ACTION_DETAIL_LOG.append(msg)
        # target_yolo_result는 아래 Fallback에서 처리됨

    elif len(valid_detections) == 1:
        # Case 3: 1장 탐지
        msg = "⚠️ 1장만 인식됨: 이동 파악 불가 (기본값 inbound)"
        logger.warning(msg)
        ACTION_DETAIL_LOG.append(msg)
        determined_status = 'inbound'  # Fallback

    else:  # 2장 이상 탐지 시
        first_d = valid_detections[0]
        last_d = valid_detections[-1]

        start_x = get_center_x(first_d['bounding_box'])
        end_x = get_center_x(last_d['bounding_box'])
        delta_x = end_x - start_x

        Area_start = get_area(first_d['bounding_box'])
        Area_end = get_area(last_d['bounding_box'])
        delta_area = Area_end - Area_start

        # Best Shot 관련 값 미리 계산
        all_areas = [get_area(d['bounding_box']) for d in valid_detections]
        Area_max = max(all_areas)

        # 완료 검증: Peak 대비 최종 면적 감소율
        Area_peak_drop = (Area_max - Area_end) / Area_max if Area_max > 0 else 0
        is_complete = Area_peak_drop >= AREA_PEAK_DROP_RATIO

        if len(valid_detections) >= 3:
            # Case 1: 3장 이상 탐지 (Best Shot 궤적 분석)

            best_shot_data = max(valid_detections, key=lambda d: get_area(d['bounding_box']))
            X_peak = get_center_x(best_shot_data['bounding_box'])

            # --- 입고 후보 (X축 증가) ---
            if delta_x > X_MIN_MOVEMENT:
                # 방향성 검증: X_start < X_peak < X_end 가 모두 성립해야 함
                is_consistent_inbound = (start_x < X_peak) and (X_peak < end_x)

                if not is_consistent_inbound:
                    ACTION_DETAIL_LOG.append("❌ 입고: 이동 방향 불일치 (X-Axis Failure)")  # X축 일관성 실패
                if not is_complete:
                    ACTION_DETAIL_LOG.append("❌ 입고: 행위 미완료 (Area Drop Failure)")  # Area 완료 실패

                if is_consistent_inbound and is_complete:
                    determined_status = 'inbound'
                    log_msg = f"✅ 입고 확정(3+): X 일관성 O, 완료율:{Area_peak_drop:.2f} | Gap: +{delta_x:.0f}"
                else:
                    determined_status = 'uncertain_conflict'
                    log_msg = f"❌ [결론] 입고 불확실 (원인: X/완료 실패)"

            # --- 출고 후보 (X축 감소) ---
            elif delta_x < -X_MIN_MOVEMENT:
                # 방향성 검증: X_start > X_peak > X_end 가 모두 성립해야 함
                is_consistent_outbound = (start_x > X_peak) and (X_peak > end_x)

                if not is_consistent_outbound:
                    ACTION_DETAIL_LOG.append("❌ 출고: 이동 방향 불일치 (X-Axis Failure)")  # X축 일관성 실패
                if not is_complete:
                    ACTION_DETAIL_LOG.append("❌ 출고: 행위 미완료 (Area Drop Failure)")  # Area 완료 실패

                if is_consistent_outbound and is_complete:
                    determined_status = 'outbound'
                    log_msg = f"✅ 출고 확정(3+): X 일관성 O, 완료율:{Area_peak_drop:.2f} | Gap: {delta_x:.0f}"
                else:
                    determined_status = 'uncertain_conflict'
                    log_msg = f"❌ [결론] 출고 불확실 (원인: X/완료 실패)"

            # --- 이동 미미 (입/출고 임계값 미달) ---
            else:
                determined_status = 'uncertain_adjust'  # 미미한 이동은 uncertain_adjust로 분류
                log_msg = f"⚠️ 이동 미미 (조정 추정): Gap: {delta_x:.0f}"
                if delta_x > 0:
                    ACTION_DETAIL_LOG.append(f"❌ 입고: X축 이동량 미달 (Gap: +{delta_x:.0f})")
                elif delta_x < 0:
                    ACTION_DETAIL_LOG.append(f"❌ 출고: X축 이동량 미달 (Gap: {delta_x:.0f})")

            logger.info(log_msg)
            ACTION_DETAIL_LOG.append(log_msg)


        else:
            # Case 2: 2장 탐지 (Start & End 비교 + X/Area 일관성 결합)

            # X와 Area의 방향이 일치해야만 확정
            is_inbound_coherent = (delta_x > X_THRESHOLD) and (delta_area < -AREA_THRESHOLD)
            is_outbound_coherent = (delta_x < -X_THRESHOLD) and (delta_area > AREA_THRESHOLD)

            if is_inbound_coherent:
                determined_status = 'inbound'
                log_msg = f"✅ 입고 확정(2프레임): X:{delta_x:.0f}, Area:{delta_area:.0f}"

            elif is_outbound_coherent:
                determined_status = 'outbound'
                log_msg = f"✅ 출고 확정(2프레임): X:{delta_x:.0f}, Area:{delta_area:.0f}"

            else:
                # 불확실 상황
                determined_status = 'uncertain_conflict'

                # 실패 원인 기록
                if abs(delta_x) < X_THRESHOLD:
                    ACTION_DETAIL_LOG.append(f"❌ 2프레임: X축 이동량 미미 (Gap: {delta_x:.0f})")

                # X와 Area의 방향이 충돌할 때 (일관성이 없을 때)
                if not is_inbound_coherent and not is_outbound_coherent:
                    ACTION_DETAIL_LOG.append(f"❌ 2프레임: X/Area 방향 불일치 (X:{delta_x:.0f}, Area:{delta_area:.0f})")

                log_msg = f"❌ [결론] 이동 불확실 (2프레임 충돌)"

            logger.info(log_msg)
            ACTION_DETAIL_LOG.append(log_msg)

    # ---------------------------------------------------------
    # [분석 2] Best Shot 선정 및 층수 판단 (제스처 우선 + 다수결로 객체 판단)
    # ---------------------------------------------------------
    if valid_detections:
        # 1. 층수 판단 (제스처 우선)
        first_box = valid_detections[0]['bounding_box']
        last_box = valid_detections[-1]['bounding_box']

        start_y = (first_box[1] + first_box[3]) / 2
        end_y = (last_box[1] + last_box[3]) / 2
        delta_y = start_y - end_y  # 위로 가면 양수(+), 아래로 가면 음수(-)

        # 층 판단 제스처 임계값 (튜닝 필요)
        GESTURE_THRESHOLD = image_height * 0.05  # [수정] 5% 비율 사용 (50px 대신)

        # [수정] FRAME_CENTER_Y를 동적 해상도 기반으로 계산 (50% 비율 사용)
        FRAME_CENTER_Y = image_height * 0.5

        # -----------------------------------------------------------
        # 3. 🗳️ 신뢰도 가중치 투표 (Weighted Voting) - Best Shot 선정 전에 실행
        # -----------------------------------------------------------
        score_board = {}

        for d in valid_detections:
            name = d['category_name']
            conf = d['confidence']
            score_board[name] = score_board.get(name, 0) + conf

        most_weighted_category = max(score_board, key=score_board.get)

        # 우승한 카테고리의 점수 리스트를 먼저 추출
        winner_scores = [
            d['confidence']
            for d in valid_detections
            if d['category_name'] == most_weighted_category
        ]
        winner_max_conf = max(winner_scores) if winner_scores else 0.0

        FINAL_CUTOFF = 0.6  # 최종 판정 객체의 신뢰도 임계값

        # -----------------------------------------------------------
        # 2. OCR용 Best Shot 선정 (스코어링 기반으로 변경 + 투표 결과 필터링)
        # -----------------------------------------------------------

        # A) 투표 승리 품목만 필터링
        winning_detections = [
            d for d in valid_detections if d['category_name'] == most_weighted_category
        ]

        # B) Best Shot 스코어링 고도화 로직
        if winning_detections:
            # 전체 프레임 중 최대 Area를 찾고, 이미지 중심 좌표 계산
            all_areas_winning = [get_area(d['bounding_box']) for d in winning_detections]
            max_area = max(all_areas_winning) if all_areas_winning else 1.0  # 분모 0 방지

            center_x_img = image_width / 2
            center_y_img = image_height / 2
            max_possible_distance = math.sqrt(center_x_img ** 2 + center_y_img ** 2)

            # 가중치 설정 (Area 80%, Centering 20%로 가정)
            WEIGHT_AREA = 0.8
            WEIGHT_CENTER = 0.2

            def calculate_best_shot_score(data_point):
                box = data_point['bounding_box']
                current_area = get_area(box)
                current_center_x = get_center_x(box)
                current_center_y = (box[1] + box[3]) / 2

                # --- 1. Area 정규화 (0 ~ 1) ---
                norm_area = current_area / max_area

                # --- 2. Centering 정규화 (0 ~ 1) ---
                distance_px = math.sqrt(
                    (current_center_x - center_x_img) ** 2 + (current_center_y - center_y_img) ** 2
                )
                # 거리를 0~1로 정규화 후, 반전 (1: 중심, 0: 모서리)
                norm_centering = 1.0 - (distance_px / max_possible_distance)

                # --- 3. 최종 스코어 ---
                score = (WEIGHT_AREA * norm_area) + (WEIGHT_CENTER * norm_centering)
                return score

            # 가장 높은 스코어를 가진 데이터 포인트를 Best Shot으로 선정
            best_shot_data = max(winning_detections, key=calculate_best_shot_score)

        else:
            # 투표 승리 품목이 없으면, 전체에서 Area 최대값을 Fallback으로 사용 (기존 방식)
            # 이 경우는 '미확인'으로 처리되지만, OCR을 위해 최소한의 이미지를 가져옴
            best_shot_data = max(valid_detections, key=lambda x: get_area(x['bounding_box']))

        # --- Best Shot 스코어링 고도화 로직 끝 ---

        target_path = best_shot_data['file_path']
        target_yolo_result = best_shot_data  # Best Shot Data는 여기서 결정됨

        # 3. 투표 결과 검증 및 보정 (투표 이후)
        if winner_max_conf < FINAL_CUTOFF:
            logger.warning(f"⚠️ [검증 실패] 우승자({most_weighted_category}) 신뢰도({winner_max_conf:.2f})가 너무 낮음 -> 미확인 처리")
            target_yolo_result['category_name'] = '식재료 미확인'

        elif target_yolo_result['category_name'] != most_weighted_category:
            # 이 로직은 이제 발생하지 않음: Best Shot이 winning category 프레임에서만 나오기 때문
            # 하지만 혹시 모를 에러 방지를 위해 유지
            logger.info(f"🗳️ [투표 보정] {target_yolo_result['category_name']} -> {most_weighted_category} (점수 1위)로 변경")
            target_yolo_result['category_name'] = most_weighted_category

        # -----------------------------------------------------------
        # 1. 층수 판단 (투표 및 Best Shot 결정 후)
        # -----------------------------------------------------------

        if len(valid_detections) == 1:
            determined_layer = 2 if end_y < FRAME_CENTER_Y else 1
            ACTION_DETAIL_LOG.append(f"층판단: 단일 프레임 위치 기반 ({determined_layer}층)")

        elif determined_status == 'outbound':  # 출고 확정 시: 시작 위치(start_y) 기준
            determined_layer = 2 if start_y < FRAME_CENTER_Y else 1
            ACTION_DETAIL_LOG.append(f"층판단: 출고 시작 위치 ({determined_layer}층)")

        else:  # 입고 (Inbound) 및 모든 불확실 상태 (uncertain_adjust, uncertain_conflict) 포함
            if delta_y > GESTURE_THRESHOLD:
                determined_layer = 2
                # 로그에 실제 delta_y 값과 임계값 포함
                ACTION_DETAIL_LOG.append(f"층판단: 위로 제스처 감지 (2층 확정) | ΔY: {delta_y:.0f} > {GESTURE_THRESHOLD:.0f}")
            elif delta_y < -GESTURE_THRESHOLD:
                determined_layer = 1
                # 로그에 실제 delta_y 값과 임계값 포함
                ACTION_DETAIL_LOG.append(f"층판단: 아래로 제스처 감지 (1층 확정) | ΔY: {delta_y:.0f} < -{GESTURE_THRESHOLD:.0f}")
            else:
                determined_layer = 2 if end_y < FRAME_CENTER_Y else 1
                ACTION_DETAIL_LOG.append(f"층판단: 제스처 미미함. 위치 기반 ({determined_layer}층)")

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
        # valid_detections가 0일 때 target_path가 None일 수 있음
        if image_paths:
            target_path = image_paths[-1]  # 임시 Fallback path
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

        # 좌표 정보 전달
        'raw_start_x': start_x,
        'raw_end_x': end_x,
        'raw_start_y': start_y,
        'raw_end_y': end_y,
    }

    # OCR 실행
    ocr_raw_output = run_ocr(target_path, target_yolo_result)

    # 정보 추출 및 통합
    ocr_info = extract_ocr_info(ocr_raw_output)

    result_data['raw_start_x'] = start_x
    result_data['raw_end_x'] = end_x
    result_data['raw_start_y'] = start_y
    result_data['raw_end_y'] = end_y

    final_data = integrate_results(result_data, target_yolo_result, ocr_info, ocr_raw_output, ACTION_DETAIL_LOG)
    original_cropped_path = ocr_raw_output.get('cropped_image_path')

    if original_cropped_path:
        try:
            # 1. 경로 분리
            old_full_path = os.path.join(settings.MEDIA_ROOT, original_cropped_path)

            # 2. 새 이름 생성 (메인 파일과 타임스탬프 공유 불가 -> 현재 시간으로 생성)
            timestamp_str = datetime.now().strftime("%Y%m%d_%H%M%S")
            ingredient_name = final_data.get('ingredient_name', '미확인')
            safe_name = ingredient_name.replace(" ", "_")  # 공백 제거
            new_crop_filename = f"{timestamp_str}_{safe_name}_cropped.jpg"

            new_full_path = os.path.join(settings.MEDIA_ROOT, 'cropped_for_ui', new_crop_filename)

            # 3. 이름 변경 (Rename)
            if os.path.exists(old_full_path):
                os.rename(old_full_path, new_full_path)
                # DB에 저장할 상대 경로 업데이트
                final_data['cropped_ingredient_pic'] = f"cropped_for_ui/{new_crop_filename}"
            else:
                final_data['cropped_ingredient_pic'] = original_cropped_path  # 실패 시 원본 유지

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
        # [수정] imgsz=640 인자를 추가하여 최소 해상도를 확보 (640x640으로 분석)
        # 이 값은 담당자에게 받은 학습 해상도로 최종 튜닝 필요
        results = model.predict(source=image_path, imgsz=640, conf=0.15, iou=0.5, verbose=True)

        if not results or not results[0].boxes:
            return None  # 탐지 실패 시 None 반환

        ## 객체 인식 성공 시
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

    # 결과 확인용
    cropped_for_ui_dir = os.path.join(settings.MEDIA_ROOT, 'cropped_for_ui')
    os.makedirs(cropped_for_ui_dir, exist_ok=True)
    base_name = os.path.splitext(os.path.basename(image_path))[0]
    cropped_filename = f'{base_name}_cropped.jpg'
    cropped_image_path_full = os.path.join(cropped_for_ui_dir, cropped_filename)
    cropped_image_relative_path = os.path.join('cropped_for_ui', cropped_filename).replace('\\', '/')

    try:  # 구글 API 인증 설정
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

    if yolo_result.get('fallback_mode'):  # Fallback 모드 : 이미지 전체 사용
        height, width = image_cv.shape[:2]
        xmin, ymin, xmax, ymax = 0, 0, width, height
    else:  # YOLO가 탐지한 BB박스 사용
        bounding_box = yolo_result.get('bounding_box', [0, 0, 0, 0])
        xmin, ymin, xmax, ymax = bounding_box

    try:
        cropped_image = image_cv[ymin:ymax, xmin:xmax]  # OpenCV 이미지 처리
        cv2.imwrite(cropped_image_path_full, cropped_image)  # Crop된 이미지 인코딩
        is_success, buffer = cv2.imencode(".png", cropped_image)
        if not is_success:
            logger.error("Image encode fail")
            return {'raw_text': "Encode fail", 'word_blocks': word_blocks, 'cropped_image_path': None}

        image_bytes = buffer.tobytes()
        client = vision.ImageAnnotatorClient()  # Vision API 호출
        image = vision.Image(content=image_bytes)  # 데이터 추출
        image_context = vision.ImageContext(language_hints=["ko"])
        response = client.annotate_image(
            request={'image': image, 'features': [{'type_': vision.Feature.Type.DOCUMENT_TEXT_DETECTION}],
                     'image_context': image_context})

        raw_text = ""  # OCR로 읽은 모든 텍스트 (디버깅용)
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

# 텍스트 블록 사이의 거리 계산 (단어 - 숫자)
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
    # 소비/유통기한 : YYYY년 MM월 DD일
    r'(\d{4})년\s*(\d{1,2})월\s*(\d{1,2})일(?:\s+\d{2}:\d{2}(?::\d{2})?)?[.]?',  # YYYY년 MM월 DD일
    r'(\d{2})년\s*(\d{1,2})월\s*(\d{1,2})일(?:\s+\d{2}:\d{2}(?::\d{2})?)?[.]?',  # YY년 MM월 DD일
    r'(\d{4})[년./-]\s*(\d{1,2})[월./-]\s*(\d{1,2})[일]?\s*까지(?:\s+\d{2}:\d{2}(?::\d{2})?)?[.]?',  # YYYY년 MM월 DD일까지
    r'(\d{4})[./-]([01]?\d)[./-]([0-3]?\d)(?:\s+\d{2}:\d{2}(?::\d{2})?)?[.]?',  # YYYY.MM.DD
    r'(\d{2})[./-]([01]?\d)[./-]([0-3]?\d)(?:\s+\d{2}:\d{2}(?::\d{2})?)?[.]?',  # YY.MM.DD
    r'(\d{4})(\d{2})(\d{2})(?:\s+\d{2}:\d{2}(?::\d{2})?)?[.]?',  # YYYYMMDD
    r'(\d{2})(\d{2})(\d{2})(?:\s+\d{2}:\d{2}(?::\d{2})?)?[.]?',  # YYMMDD
    r'([01]?\d)[./]([0-3]?\d)[.]?'  # MM.DD
]


# 4-2. 유통기한 텍스트 탐지
def extract_ocr_info(ocr_raw_output: Dict[str, Any]) -> Dict[str, Any]:
    raw_text = ocr_raw_output.get('raw_text', '')
    word_blocks = ocr_raw_output.get('word_blocks', [])

    INDICATOR_KEYWORDS = ['까지', '기한', '유통', '소비', '유통기한', '소비기한']  # 유통기한 키워드 (유통기한 유형 신뢰도 1.0 부여)

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
                if len(pure_digits) > 10:  # 바코드 등 길이 필터
                    continue

                try:
                    parsed_date = None
                    date_format_parts = 0  # 날짜 파트 개수 (2: MM/DD, 3: YMD)
                    today = date.today()  # 현재 날짜 객체 정의

                    if len(date_parts) == 3:
                        year, month, day = map(int, date_parts)
                        if year < 100: year += 2000
                        parsed_date = date(year, month, day)
                        date_format_parts = 3  # YYYY/MM/DD 또는 YY/MM/DD
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

                    date_format_parts = 2  # MM/DD

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
            SEARCH_RADIUS = text_height * 3  # 날짜 텍스트 높이의 3배 반경을 '주변'으로 정의,

            for block in word_blocks:  # 날짜 같아 보이는 숫자 주변에 영양성분 키워드가 있으면, 날짜가 아닌 영양성분 값으로 인식
                if block == date_block: continue
                if any(keyword in block['text'] for keyword in EXCLUSION_KEYWORDS):
                    if calculate_distance(date_block, block) < SEARCH_RADIUS:
                        is_nutrition_info = True
                        break
            if is_nutrition_info:  # 날짜가 아닌 영양 정보로 판단되면 다음 날짜 후보로
                continue

            best_date = candidate_date  # 유효한 날짜 후보를 찾으면 최종 선택
            best_date_block = date_block
            recognition_confidence = best_date_block['confidence']  # 유통기한으로 추정된 글자의 OCR 인식 신뢰도
            filtered_word_blocks.append(best_date_block)

            min_distance = float('inf')
            closest_keyword_block = None
            if found_keywords_info:
                for keyword_block in found_keywords_info:
                    distance = calculate_distance(date_block, keyword_block)
                    if distance < min_distance:
                        min_distance = distance
                        closest_keyword_block = keyword_block

            DISTANCE_THRESHOLD = text_height * 5  # 유통기한 키워드 글자 높이의 5배 이내 거리에 키워드가 있으면 유통기한으로 판단
            if min_distance < DISTANCE_THRESHOLD:
                type_confidence = 1.0  # 신뢰도 1.0 부여
                if closest_keyword_block and closest_keyword_block not in filtered_word_blocks:
                    filtered_word_blocks.append(closest_keyword_block)  # 유통기한 키워드가 없지만 날짜 형태가 있고 미래인 경우
            elif best_date > date.today():  # 신뢰도 0.8 부여
                type_confidence = 0.8
            break  # 최종 날짜를 찾으면 종료

    return {
        'extracted_date': best_date,  # 최종 날짜
        'date_recognition_confidence': round(recognition_confidence, 4),  # 유통기한 인식 신뢰도
        'date_type_confidence': type_confidence,  # 찾은 글자가 유통기한이 맞는가?에 대한 신뢰도 (유통기한 유형 신뢰도)
        'raw_ocr_text': raw_text,  # OCR로 인식한 모든 텍스트
        'filtered_word_blocks': filtered_word_blocks,  # OCR로 인식한 텍스트 중 유통기한 후보 관련
    }


# 4-3. Word2Vec을 이용한 색재료명 추출
def extract_product_name(raw_text: str, yolo_category: str, product_candidate_blocks: List[Dict[str, Any]]) -> Dict[
    str, Any]:
    model = SrmappConfig.word_embedding_model
    ANCHOR_WORD = '식재료'  # '식재료' 단어와의 유사성 판단
    SIMILARITY_THRESHOLD = 0.5  # Word Embedding 유사도 임계값

    if model is None:
        logger.warning('Word Embedding Model Not Loaded')
        return {'name': 'Word Embedding Model Not Loaded', 'similarity': 0.0}

    if ANCHOR_WORD not in model.wv:
        logger.warning('Anchor Word Missing in Word Embedding Model')
        return {'name': 'Anchor Word Missing', 'similarity': 0.0}

    valid_words = []

    for target_block in product_candidate_blocks:  # 식재료명과 무관한 내용 제외
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

    if not valid_words:  # OCR에서 유효한 단어를 찾지 못한 경우
        return {'name': None, 'similarity': 0.0}

    best_match = None  # 워드 임베딩 유사도 비교
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

    if best_match and max_similarity >= SIMILARITY_THRESHOLD:  # 최종 결과 반환
        final_confidence = round(max_similarity, 4)
        logger.info(f"✅ Product Name Found via Word Embedding: {best_match} (Similarity: {max_similarity:.2f})")
        return {'name': best_match, 'similarity': final_confidence}

    else:  # 유사도가 임계값을 넘지 못하거나 매칭되는 단어가 없는 경우
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

    YOLO_CONFIDENCE_THRESHOLD = 0.7
    PRODUCT_SIMILARITY_THRESHOLD = 0.65

    # 🟢 [캐싱 적용] 첫 호출 시 DB 접근, 이후 메모리에서 가져옴
    standard_db_names = get_standard_ingredient_list()

    # Word2Vec이나 YOLO에서 식재료 후보를 결정
    candidate_name = None
    if final_product_name:
        candidate_name = final_product_name
    elif yolo_category not in ['FALLBACK_MODE', '식재료 미확인']:
        candidate_name = yolo_category

    if candidate_name:
        for db_name in standard_db_names:
            # Fuzz (Levenshtein) 유사도 계산
            score = Levenshtein.ratio(candidate_name, db_name)
            if score > max_fuzz_score:
                max_fuzz_score = score
                best_fuzz_match = db_name

    # 식재료명 결정
    determined_ingredient_name = '식재료 미확인'  # 초기값 설정

    # 1순위: Fuzz 교정 성공 시 (가장 강력한 검증)
    if max_fuzz_score >= TYPO_THRESHOLD and best_fuzz_match:
        determined_ingredient_name = best_fuzz_match

    # 2순위: Word2Vec 유사도 통과 시 (OCR 기반)
    elif final_product_name and product_similarity_score >= PRODUCT_SIMILARITY_THRESHOLD:
        determined_ingredient_name = final_product_name

    # 3순위: YOLO 통과 시
    elif yolo_category not in ['FALLBACK_MODE',
                               '식재료 미확인'] and yolo_confidence is not None and yolo_confidence >= YOLO_CONFIDENCE_THRESHOLD:
        determined_ingredient_name = yolo_category

    # 최종 표준 명칭 변환
    # 어떤 경로로 결정되었든, 최종 저장 전에 STANDARD_MAP 기반으로 교정 (예: 케챂 -> 케첩)
    if determined_ingredient_name != '식재료 미확인':
        determined_ingredient_name = get_standard_name(determined_ingredient_name)

    # 유통기한 신뢰도 및 상태 결정 로직
    recognition_conf = ocr_info.get('date_recognition_confidence', 0.0)
    type_conf = ocr_info.get('date_type_confidence', 0.0)
    extracted_date = ocr_info.get('extracted_date')

    # **[유통기한 신뢰도 결합]**
    FINAL_DATE_CONFIDENCE = recognition_conf * type_conf  # 인식 신뢰도 x 유형 신뢰도 결합
    FINAL_CONFIDENCE_THRESHOLD = 0.60  # 최종 임계값

    # **[유통기한 상태 최종 결정]**
    expiry_date_status = 'NOT_FOUND'

    if extracted_date:

        if extracted_date < date.today():
            expiry_date_status = 'EXPIRED'  # 1순위: 만료됨
        elif FINAL_DATE_CONFIDENCE >= FINAL_CONFIDENCE_THRESHOLD:
            expiry_date_status = 'CONFIRMED'  # 2순위: 신뢰도 높음
        else:
            expiry_date_status = 'UNCERTAIN'  # 3순위: 신뢰도 낮음

    # 👇 [수정] ACTION_DETAIL_LOG에 유통기한 결과 기록
    if extracted_date:
        # 이미 위에서 결정된 최종 상태(expiry_date_status)를 가져와 기록합니다.
        ACTION_DETAIL_LOG.append(f"✅ 유통기한: {extracted_date} ({expiry_date_status})")
        ACTION_DETAIL_LOG.append(f"💰 유통기한 신뢰도: {FINAL_DATE_CONFIDENCE:.2f}")
    else:
        ACTION_DETAIL_LOG.append("❌ 유통기한 탐지 실패")

    # =======================================================
    # [수정] Serializer 호환성을 위한 상태 재매핑 로직 (필수 수정)
    # DB Model이 'inbound'/'outbound' 외의 값을 허용하지 않을 때 처리
    # =======================================================
    current_status = base_data.get('status')

    if current_status in ['uncertain_adjust', 'uncertain_conflict', 'FALLBACK_MODE']:
        log_msg = f"⚠️ 상태 : 기본값(inbound) 사용"
        logger.warning(log_msg)
        ACTION_DETAIL_LOG.append(log_msg)

        # DB에 저장 가능한 값으로 'inbound'로 강제 변환
        base_data['status'] = 'inbound'

    # [주의] 이 로직은 base_data['status']만 수정하며, base_data['layer']는 수정하지 않습니다.

    # -------------------------------------------------------------

    # base_data에서 좌표 정보를 꺼내서 최종 결과에 담습니다.
    final_data = {
        'user_id': base_data['user_id'],

        'layer': base_data.get('layer'),
        'status': base_data.get('status'),  # 재매핑된 값이 적용됨

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

        'raw_start_x': base_data.get('raw_start_x', 0.0),
        'raw_end_x': base_data.get('raw_end_x', 0.0),
        'raw_start_y': base_data.get('raw_start_y', 0.0),
        'raw_end_y': base_data.get('raw_end_y', 0.0),
    }
    final_data['decision_log'] = " | ".join(ACTION_DETAIL_LOG)  # 임베디드 확인용

    return final_data