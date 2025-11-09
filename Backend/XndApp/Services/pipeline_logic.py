# XndApp/Services/pipeline_logic.py
import os
import numpy as np
import cv2
from django.conf import settings
from typing import Dict, List, Any
from XndApp.apps import SrmappConfig
from google.cloud import vision
import re
from datetime import date
import math
from gensim.models import Word2Vec
import Levenshtein


# 식재료명/유통기한 인식에서 제외할 키워드 (영양성분 + 제조시설/경고 문구)
EXCLUSION_KEYWORDS = [
    '나트륨', '탄수화물', '당류', '지방', '트랜스지방', '포화지방',
    '콜레스테롤', '단백질', '칼슘', '열량', 'g', 'mg', 'kcal', '%',
    '제조시설', '사용된', '시설에서', '원재료', '함유', '알레르기', '성분', '주의', '사용할', '수', '있습니다', '제품은', '원재료명',
    '부정', '불량'
]

# OCR VS YOLO 인식 결과 보정
STANDARD_MAP = {
    # 인식 : 표준
    "계란": "달걀",
    "케챂": "케첩",
    "케찹": "케첩",
    "고추가루": "고춧가루"
}

def get_standard_ingredient_list() -> List[str]:
    try:
        from XndApp.Models.foodStorageLife import FoodStorageLife
        return list(FoodStorageLife.objects.values_list('name', flat=True).distinct())
    except Exception as e:
        print(f"Warning: FoodStorageLife DB access failed: {e}. Using fallback list.")
        # DB 접근 실패 시
        return ['케첩', '두부', '파스타면', '쌀', '계란']

def get_standard_name(ingredient_name: str) -> str:
    return STANDARD_MAP.get(ingredient_name, ingredient_name)
TYPO_THRESHOLD = 0.85 # Fuzz 교정 임계값


# 1. 메인 파이프라인 함수
def process_image_pipeline(user_id: int, image_path: str) -> Dict[str, Any]:
    if not os.path.exists(image_path):
        return {"error": "Image file not found"}

    result_data = {
        'user_id': user_id,
        'stored_at': date.today(),
        'ingredient_name': '',
        'category_yolo': None,
        'product_name_ocr': None,
        'expiry_date': None,
        'expiry_date_status': 'NOT_FOUND',
        'ingredient_pic': image_path,
    }

    yolo_result = run_yolo_detection(image_path)  # 1. YOLO 실행: BB 좌표 및 식재료 카테고리 추출

    if yolo_result is None:  # YOLO 인식 실패시 이미지 크롭 X
        yolo_result = {
            'bounding_box': [0, 0, 0, 0],
            'category_name': 'FALLBACK_MODE',
            'fallback_mode': True  # Fallback 모드 플래그
        }

    ocr_raw_output = run_ocr(image_path, yolo_result)  # 2. OCR 실행: 이미지 크롭 후, 클라우드 API 호출 및 원본 텍스트 수신
    ocr_info = extract_ocr_info(ocr_raw_output)  # 3. 텍스트 정보 추출: 원본 텍스트에서 날짜, 제품명 등을 정규식으로 추출
    final_data = integrate_results(result_data, yolo_result, ocr_info,
                                   ocr_raw_output)  # 4. 결과 통합: YOLO와 OCR 결과를 병합하고 신뢰도에 따라 분기 처리

    return final_data


# 2. ② YOLO 모델 적용 (객체 탐지)
def run_yolo_detection(image_path: str) -> Dict[str, Any]:
    model = SrmappConfig.yolo_model

    if model is None:
        return None  # 모델 로드 실패 시 None 반환

    try:
        results = model.predict(source=image_path, conf=0.25, iou=0.5, verbose=True)

        if not results or not results[0].boxes:
            return None  # 탐지 실패 시 None 반환

        ## 객체 인식 성공 시
        box = results[0].boxes[0]
        xmin, ymin, xmax, ymax = map(int, box.xyxy[0].tolist())
        confidence = float(box.conf[0])
        class_index = int(box.cls[0])
        category_name = model.names[class_index]

        print(f"DEBUG: Extracted YOLO Confidence: {confidence}")

        return {
            'category_name': category_name,
            'confidence': confidence,
            'bounding_box': [xmin, ymin, xmax, ymax],
        }

    except Exception as e:
        print(f"YOLO detection error: {e}")
        return None  # 예외 발생 시 None 반환

# 3. ③ OCR 모델 적용 (이미지 크롭 및 텍스트 인식)
def run_ocr(image_path: str, yolo_result: Dict[str, Any]) -> Dict[str, Any]:
    word_blocks: List[Dict[str, Any]] = []

    try:  # 구글 API 인증 설정
        os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = str(settings.GOOGLE_APPLICATION_CREDENTIALS)
    except AttributeError:
        return {'raw_text': "Error: GOOGLE_APPLICATION_CREDENTIALS is not set in settings.py",
                'word_blocks': word_blocks}

    try:
        img_array = np.fromfile(image_path, np.uint8)
        image_cv = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
    except Exception as e:
        return {"raw_text": f"Error: Image read failed. {e}", 'word_blocks': word_blocks}

    if yolo_result.get('fallback_mode'):  # Fallback 모드 : 이미지 전체 사용
        height, width = image_cv.shape[:2]
        xmin, ymin, xmax, ymax = 0, 0, width, height
    else:  # YOLO가 탐지한 BB박스 사용
        bounding_box = yolo_result.get('bounding_box', [0, 0, 0, 0])
        xmin, ymin, xmax, ymax = bounding_box

    base_name = os.path.splitext(os.path.basename(image_path))[0]
    ocr_output_dir = settings.MEDIA_ROOT / 'stored_images_ocr'
    os.makedirs(ocr_output_dir, exist_ok=True)

    try:
        cropped_image = image_cv[ymin:ymax, xmin:xmax]  # OpenCV 이미지 처리

        is_success, buffer = cv2.imencode(".png", cropped_image)  # Crop된 이미지 인코딩
        if not is_success:
            return {'raw_text': "Error: Image encoding failed", 'word_blocks': word_blocks}

        image_bytes = buffer.tobytes()

        client = vision.ImageAnnotatorClient()  # Vision API 호출
        image = vision.Image(content=image_bytes)  # 데이터 추출

        image_context = vision.ImageContext(language_hints=["ko"])

        response = client.annotate_image(
            request={
                'image': image,
                'features': [{'type_': vision.Feature.Type.DOCUMENT_TEXT_DETECTION}],
                'image_context': image_context
            }
        )

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

            return {'raw_text': raw_text, 'word_blocks': word_blocks}

        return {'raw_text': '', 'word_blocks': word_blocks}

    except Exception as e:
        print(f"OCR API or Image processing error: {e}")
        return {"raw_text": f"OCR API or Processing error: {e}", 'word_blocks': word_blocks}


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

    for block in word_blocks:  # 날짜 후보 및 키워드 수집
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

                            # 12월 - 1월
                            if today.month >=11 and month == 1 and parsed_date < today:
                                parsed_date = date(today.year + 1, month, day)

                        except ValueError:
                            continue

                    date_format_parts = 2  # MM/DD

                    if parsed_date and 2000 <= parsed_date.year <= 2100:  # ✅ [수정] 년도 상한선 2999 -> 2100 으로 현실화

                        found_dates_info.append((parsed_date, block, date_format_parts))
                        break
                except ValueError:
                    continue

    best_date = None
    recognition_confidence = 0.0
    type_confidence = 0.5
    filtered_word_blocks = []

    if found_dates_info:

        sorted_dates = sorted(found_dates_info, key=lambda item: item[0], reverse=True)  # 가장 먼 미래 날짜부터 검토

        for candidate_date, date_block, date_parts_count in sorted_dates:
            today = date.today()
            if candidate_date.year > today.year + 5 or candidate_date.year < today.year - 3:
                print(f"DEBUG: Rejected extreme date: {candidate_date}")
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
                    filtered_word_blocks.append(closest_keyword_block)
            elif best_date > date.today():  # 유통기한 키워드가 없지만 날짜 형태가 있고 미래인 경우
                type_confidence = 0.8  # 신뢰도 0.8 부여
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
        return {'name': 'Word Embedding Model Not Loaded', 'similarity': 0.0}

    if ANCHOR_WORD not in model.wv:  # 기준 단어('식재료')가 모델 단어장에 있는지 확인
        print(f"🚨 Anchor word '{ANCHOR_WORD}' not in Word Embedding vocabulary. Extraction failed.")
        return {'name': 'Anchor Word Missing', 'similarity': 0.0}

    valid_words = []

    # **[수정] product_candidate_blocks를 순회**
    for target_block in product_candidate_blocks:  # 식재료명과 무관한 영양성분 관련 내용 제외
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
            if len(word) > 1 and word in model.wv and word != ANCHOR_WORD:  # 단어 길이가 1 초과이고, 모델 단어장에 존재하며, 기준 단어와 동일하지 않은 단어만 후보로
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
            print(f"Similarity calculation error: {e}")
            continue

    if best_match and max_similarity >= SIMILARITY_THRESHOLD:  # 최종 결과 반환
        final_confidence = round(max_similarity, 4)

        print(
            f"✅ Product Name Found via Word Embedding: {best_match} (Similarity: {max_similarity:.2f}, Final Conf: {final_confidence:.2f})")
        return {'name': best_match, 'similarity': final_confidence}

    else:  # 유사도가 임계값을 넘지 못하거나 매칭되는 단어가 없는 경우
        print(
            f"⚠️ Word Embedding failed (Similarity < {SIMILARITY_THRESHOLD}). Returning None.")
        return {'name': None, 'similarity': 0.0}


# 5. 결과 통합 및 신뢰도 분기 처리
def integrate_results(base_data: Dict[str, Any], yolo_result: Dict[str, Any], ocr_info: Dict[str, Any],
                      ocr_raw_output: Dict[str, Any]) -> Dict[str, Any]:
    yolo_category = yolo_result.get('category_name', '식재료 미확인')
    yolo_confidence = yolo_result.get('confidence', None)

    raw_ocr_text = ocr_info.get('raw_ocr_text', '')
    all_word_blocks = ocr_raw_output.get('word_blocks', [])

    # 유통기한 관련 블록을 식재료명 후보에서 제거
    date_blocks_to_exclude = ocr_info.get('filtered_word_blocks', [])

    product_candidate_blocks = [
        block for block in all_word_blocks
        if block not in date_blocks_to_exclude
    ]

    # 날짜/키워드 블록이 제외된 후보 리스트 전달
    product_result = extract_product_name(raw_ocr_text, yolo_category, product_candidate_blocks)

    final_product_name = product_result['name']
    product_similarity_score = product_result['similarity']

    best_fuzz_match = None
    max_fuzz_score = -1.0

    YOLO_CONFIDENCE_THRESHOLD = 0.7
    PRODUCT_SIMILARITY_THRESHOLD = 0.65

    standard_db_names = get_standard_ingredient_list()  # DB 목록 안전하게 가져오기

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
    FINAL_CONFIDENCE_THRESHOLD = 0.90  # 최종 임계값 (0.90 이하)

    # **[유통기한 상태 최종 결정]**
    expiry_date_status = 'NOT_FOUND'

    if extracted_date:
        if extracted_date < date.today():
            expiry_date_status = 'EXPIRED'  # 1순위: 만료됨
        elif FINAL_DATE_CONFIDENCE >= FINAL_CONFIDENCE_THRESHOLD:
            expiry_date_status = 'CONFIRMED'  # 2순위: 신뢰도 높음
        else:
            expiry_date_status = 'UNCERTAIN'  # 3순위: 신뢰도 낮음

    final_data = {
        'user_id': base_data['user_id'],

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
        'final_date_confidence': round(FINAL_DATE_CONFIDENCE, 4),  # 최종 신뢰도 점수

        'raw_ocr_text': raw_ocr_text,
        'ocr_word_blocks': ocr_info.get('filtered_word_blocks')
    }

    return final_data