# XndApp/Services/pipeline_logic.py
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
TYPO_THRESHOLD = 0.85 # Fuzz 교정 임계값

# 1. 메인 파이프라인 함수
def process_image_pipeline(user_id: int, image_paths: List[str], layer: str, action_type: str = 'analyzing') -> Dict[
    str, Any]:
    # 1. 모든 이미지에 대해 YOLO 수행
    yolo_results = []
    for path in image_paths:
        if not os.path.exists(path): continue
        result = run_yolo_detection(path)
        if result:
            result['file_path'] = path
            yolo_results.append(result)

    # 2. 감지된 프레임만 필터링
    valid_detections = [res for res in yolo_results if res is not None]

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

    # ---------------------------------------------------------
    # [분석 1] 이동 방향 판단
    # ---------------------------------------------------------
    if len(valid_detections) >= 2:
        first_valid = valid_detections[0]
        last_valid = valid_detections[-1]

        def get_center_x(box):
            return (box[0] + box[2]) / 2

        start_x = get_center_x(first_valid['bounding_box'])
        end_x = get_center_x(last_valid['bounding_box'])
        delta_x = end_x - start_x

        if delta_x > 20:
            determined_status = 'inbound'
            log_msg = f"이동: 입고 (X: {start_x:.0f}→{end_x:.0f} | Gap: +{delta_x:.0f})"
            logger.info(f"➡️ {log_msg}")
            ACTION_DETAIL_LOG.append(log_msg)

        elif delta_x < -20:
            determined_status = 'outbound'
            log_msg = f"이동: 출고 (X: {start_x:.0f}→{end_x:.0f} | Gap: {delta_x:.0f})"
            logger.info(f"⬅️ {log_msg}")
            ACTION_DETAIL_LOG.append(log_msg)

        else:
            determined_status = 'inbound'
            log_msg = f"이동미미: 기본값 사용 (X: {start_x:.0f}→{end_x:.0f} | Gap: {delta_x:.0f})"
            logger.info(f"⏺️ {log_msg}")
            ACTION_DETAIL_LOG.append(log_msg)

    elif len(valid_detections) == 1:
        msg = "⚠️ 1장만 인식됨: 이동 파악 불가 (기본값)"
        logger.warning(msg)
        ACTION_DETAIL_LOG.append(msg)

    else:
        msg = "❌ 인식된 객체 없음: (기본값)"
        logger.error(msg)
        ACTION_DETAIL_LOG.append(msg)

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

        FRAME_CENTER_Y = 360  # 720p 기준

        if len(valid_detections) == 1:
            determined_layer = 2 if end_y < FRAME_CENTER_Y else 1
            ACTION_DETAIL_LOG.append(f"층판단: 단일 프레임 위치 기반 ({determined_layer}층)")

        elif determined_status == 'outbound':  # 출고 시: 시작 위치(start_y) 기준
            determined_layer = 2 if start_y < FRAME_CENTER_Y else 1
            ACTION_DETAIL_LOG.append(f"층판단: 출고 시작 위치 ({determined_layer}층)")

        else:  # 입고 (Inbound)일 때
            if delta_y > 50:
                determined_layer = 2
                ACTION_DETAIL_LOG.append(f"층판단: 위로 제스처 감지 (2층 확정)")
            elif delta_y < -50:
                determined_layer = 1
                ACTION_DETAIL_LOG.append(f"층판단: 아래로 제스처 감지 (1층 확정)")
            else:
                determined_layer = 2 if end_y < FRAME_CENTER_Y else 1
                ACTION_DETAIL_LOG.append(f"층판단: 제스처 미미함. 위치 기반 ({determined_layer}층)")

        # 2. OCR용 Best Shot 선정
        def get_area(box):
            return (box[2] - box[0]) * (box[3] - box[1])

        best_shot_data = max(valid_detections, key=lambda x: get_area(x['bounding_box']))

        target_path = best_shot_data['file_path']
        target_yolo_result = best_shot_data

        # 3. 🗳️ 신뢰도 가중치 투표 (Weighted Voting)
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

        FINAL_CUTOFF = 0.6 # 최종 판정 객체의 신뢰도 임계값

        if winner_max_conf < FINAL_CUTOFF:
            logger.warning(f"⚠️ [검증 실패] 우승자({most_weighted_category}) 신뢰도({winner_max_conf:.2f})가 너무 낮음 -> 미확인 처리")
            target_yolo_result['category_name'] = '식재료 미확인'

        elif target_yolo_result['category_name'] != most_weighted_category:
            logger.info(f"🗳️ [투표 보정] {target_yolo_result['category_name']} -> {most_weighted_category} (점수 1위)로 변경")
            target_yolo_result['category_name'] = most_weighted_category

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
        results = model.predict(source=image_path, conf=0.15, iou=0.5, verbose=True)

        if not results or not results[0].boxes:
            return None # 탐지 실패 시 None 반환

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
    r'(?:소비기한|유통기한)\s*[:]?\s*(\d{4})[년./-]\s*(\d{1,2})[월./-]\s*(\d{1,2})[일]?(?:\s+\d{2}:\d{2}(?::\d{2})?)?[.]?', # 소비/유통기한 : YYYY년 MM월 DD일
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
        return {'name': None, 'similarity': 0.0}


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
    FINAL_DATE_CONFIDENCE = recognition_conf * type_conf # 인식 신뢰도 x 유형 신뢰도 결합
    FINAL_CONFIDENCE_THRESHOLD = 0.60 # 최종 임계값

    # **[유통기한 상태 최종 결정]**
    expiry_date_status = 'NOT_FOUND'

    if extracted_date:
        if extracted_date < date.today():
            expiry_date_status = 'EXPIRED'  # 1순위: 만료됨
        elif FINAL_DATE_CONFIDENCE >= FINAL_CONFIDENCE_THRESHOLD:
            expiry_date_status = 'CONFIRMED'  # 2순위: 신뢰도 높음
        else:
            expiry_date_status = 'UNCERTAIN'  # 3순위: 신뢰도 낮음

    # base_data에서 좌표 정보를 꺼내서 최종 결과에 담습니다.
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

        'raw_start_x': base_data.get('raw_start_x', 0.0),
        'raw_end_x': base_data.get('raw_end_x', 0.0),
        'raw_start_y': base_data.get('raw_start_y', 0.0),
        'raw_end_y': base_data.get('raw_end_y', 0.0),
    }
    final_data['decision_log'] = " | ".join(ACTION_DETAIL_LOG) #임베디드 확인용

    return final_data