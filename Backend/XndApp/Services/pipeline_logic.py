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

    # 1. YOLO 실행: BB 좌표 및 카테고리 추출
    yolo_result = run_yolo_detection(image_path)

    # 💡 Fallback 로직: YOLO 실패(None 반환) 시 전체 이미지 OCR을 시도하도록 yolo_result 덮어쓰기
    if yolo_result is None:
        yolo_result = {
            'bounding_box': [0, 0, 0, 0],
            'category_name': 'FALLBACK_MODE',
            'fallback_mode': True  # Fallback 모드 플래그
        }

    ocr_raw_output = run_ocr(image_path, yolo_result)     # 2. OCR 실행: 이미지 크롭 후, 클라우드 API 호출 및 원본 텍스트 수신
    ocr_info = extract_ocr_info(ocr_raw_output)           # 3. 텍스트 정보 추출: 원본 텍스트에서 날짜, 제품명 등을 정규식으로 추출
    final_data = integrate_results(result_data, yolo_result, ocr_info)     # 4. 결과 통합: YOLO와 OCR 결과를 병합하고 신뢰도에 따라 분기 처리

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

        ## YOLO 결과 시각화 및 저장
        img_array = np.fromfile(image_path, np.uint8)
        image_cv = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
        cv2.rectangle(image_cv, (xmin, ymin), (xmax, ymax), (0, 255, 0), 2)
        text = f"{category_name}: {confidence:.2f}"
        cv2.putText(image_cv, text, (xmin, ymin - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (0, 255, 0), 2)
        base_name = os.path.splitext(os.path.basename(image_path))[0]
        output_filename = f"{base_name}_yolo_checked.jpg"
        output_path = settings.MEDIA_ROOT / 'stored_images_yolo' / output_filename
        os.makedirs(settings.MEDIA_ROOT / 'stored_images_yolo', exist_ok=True)

        is_success, buffer = cv2.imencode(".jpg", image_cv)
        if is_success:
            buffer.tofile(output_path)
            print(f"✅ YOLO visualization saved to: {output_path}")

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

    try:  #구글 API 인증 설정
        os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = str(settings.GOOGLE_APPLICATION_CREDENTIALS)
    except AttributeError:
        return {'raw_text': "Error: GOOGLE_APPLICATION_CREDENTIALS is not set in settings.py",
                'word_blocks': word_blocks}

    try:
        img_array = np.fromfile(image_path, np.uint8)
        image_cv = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
    except Exception as e:
        return {"raw_text": f"Error: Image read failed. {e}", 'word_blocks': word_blocks}


    if yolo_result.get('fallback_mode'): #Fallback 모드 : 이미지 전체 사용
        # Fallback 모드: 이미지 전체를 BB로 사용
        height, width = image_cv.shape[:2]
        xmin, ymin, xmax, ymax = 0, 0, width, height
    else: # YOLO가 탐지한 BB박스 사용
        bounding_box = yolo_result.get('bounding_box', [0, 0, 0, 0])
        xmin, ymin, xmax, ymax = bounding_box

    base_name = os.path.splitext(os.path.basename(image_path))[0]
    ocr_output_dir = settings.MEDIA_ROOT / 'stored_images_ocr'
    os.makedirs(ocr_output_dir, exist_ok=True)

    try:
        cropped_image = image_cv[ymin:ymax, xmin:xmax] #OpenCV 이미지 처리

        is_success, buffer = cv2.imencode(".png", cropped_image) # Crop된 이미지 인코딩
        if not is_success:
            return {'raw_text': "Error: Image encoding failed", 'word_blocks': word_blocks}

        image_bytes = buffer.tobytes()

        client = vision.ImageAnnotatorClient()         # Vision API 호출
        image = vision.Image(content=image_bytes)      # 데이터 추출

        image_context = vision.ImageContext(language_hints=["ko"])

        response = client.annotate_image(
            request={
                'image': image,
                'features': [{'type_': vision.Feature.Type.DOCUMENT_TEXT_DETECTION}],
                'image_context': image_context
            }
        )

        raw_text = "" # OCR로 읽은 모든 텍스트
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

            # OCR 시각화
            ocr_bb_image = cropped_image.copy()
            for block_data in word_blocks:
                bounds = block_data['bounds']
                x1, y1 = bounds[0]
                x2, y2 = bounds[2]

                cv2.rectangle(ocr_bb_image, (x1, y1), (x2, y2), (0, 165, 255), 1)
                cv2.putText(ocr_bb_image, block_data['text'], (x1, y1 - 2),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.35, (255, 255, 255), 1)

            ocr_bb_filename = f"{base_name}_ocr_bb_checked.jpg"
            ocr_bb_path = ocr_output_dir / ocr_bb_filename

            is_success_bb, buffer_bb = cv2.imencode(".jpg", ocr_bb_image)
            if is_success_bb:
                buffer_bb.tofile(ocr_bb_path)
                print(f"✅ OCR BB visualization saved to: {ocr_bb_path}")

            return {'raw_text': raw_text, 'word_blocks': word_blocks}

        return {'raw_text': '', 'word_blocks': word_blocks}

    except Exception as e:
        print(f"OCR API or Image processing error: {e}")
        return {"raw_text": f"OCR API or Processing error: {e}", 'word_blocks': word_blocks}


# ④ 정보 추출 및 가공
# 4-1. 유통기한

# 유통기한 텍스트 탐지
DATE_PATTERNS = [
    r'(?:소비기한|유통기한)\s*[:]?\s*(\d{4})[년./-]\s*(\d{1,2})[월./-]\s*(\d{1,2})[일]?(?:\s+\d{2}:\d{2}(?::\d{2})?)?[.]?', #소비/유통기한 : YYYY년 MM월 DD일
    r'(\d{4})년\s*(\d{1,2})월\s*(\d{1,2})일(?:\s+\d{2}:\d{2}(?::\d{2})?)?[.]?',  # YYYY년 MM월 DD일
    r'(\d{2})년\s*(\d{1,2})월\s*(\d{1,2})일(?:\s+\d{2}:\d{2}(?::\d{2})?)?[.]?',  # YY년 MM월 DD일
    r'(\d{4})[년./-]\s*(\d{1,2})[월./-]\s*(\d{1,2})[일]?\s*까지(?:\s+\d{2}:\d{2}(?::\d{2})?)?[.]?', #YYYY년 MM월 DD일까지
    r'(\d{4})[./-]([01]?\d)[./-]([0-3]?\d)(?:\s+\d{2}:\d{2}(?::\d{2})?)?[.]?',  # YYYY.MM.DD
    r'(\d{2})[./-]([01]?\d)[./-]([0-3]?\d)(?:\s+\d{2}:\d{2}(?::\d{2})?)?[.]?',  # YY.MM.DD
    r'(\d{4})(\d{2})(\d{2})(?:\s+\d{2}:\d{2}(?::\d{2})?)?[.]?',              # YYYYMMDD
    r'(\d{2})(\d{2})(\d{2})(?:\s+\d{2}:\d{2}(?::\d{2})?)?[.]?',              # YYMMDD
    r'([01]?\d)[./]([0-3]?\d)[.]?'                                       # MM.DD
]

# 텍스트 블록 사이의 거리 계산 (단어 - 숫자)
def get_center(bounds: List[tuple]) -> tuple:
    """ 경계 상자(bounds)의 중심점 좌표를 반환합니다. """
    x_coords = [v[0] for v in bounds]
    y_coords = [v[1] for v in bounds]
    center_x = sum(x_coords) / len(x_coords)
    center_y = sum(y_coords) / len(y_coords)
    return (center_x, center_y)

def calculate_distance(block1: Dict, block2: Dict) -> float:
    center1 = get_center(block1['bounds'])
    center2 = get_center(block2['bounds'])
    return math.sqrt((center1[0] - center2[0]) ** 2 + (center1[1] - center2[1]) ** 2)


# 4. 텍스트 정보 추출 (유통기한, 제품명)
def extract_ocr_info(ocr_raw_output: Dict[str, Any]) -> Dict[str, Any]:
    raw_text = ocr_raw_output.get('raw_text', '')
    word_blocks = ocr_raw_output.get('word_blocks', [])

    NUTRITION_KEYWORDS = ['나트륨', '탄수화물', '당류', '지방', '트랜스지방', '포화지방', '콜레스테롤', '단백질', '칼슘', '열량', 'g', 'mg', 'kcal', '%']  #영양성분 키워드 (유통기한 후보에서 탈락)
    INDICATOR_KEYWORDS = ['까지', '기한', '유통', '소비', '유통기한', '소비기한'] # 유통기한 키워드 (유통기한 유형 신뢰도 1.0 부여)

    found_dates_info = []
    found_keywords_info = []

    # 날짜 후보 및 키워드 수집
    for block in word_blocks:
        if any(keyword in block['text'] for keyword in INDICATOR_KEYWORDS):
            found_keywords_info.append(block)

        for pattern in DATE_PATTERNS:
            match = re.search(pattern, block['text'])
            if match:
                date_parts = list(match.groups())
                try:
                    parsed_date = None
                    if len(date_parts) == 3:
                        year, month, day = map(int, date_parts)
                        if year < 100: year += 2000
                        parsed_date = date(year, month, day)
                    elif len(date_parts) == 2:
                        month, day = map(int, date_parts)
                        today = date.today()
                        current_year_date = date(today.year, month, day)
                        parsed_date = date(today.year + 1, month,
                                           day) if current_year_date < today else current_year_date

                    if parsed_date and 2000 <= parsed_date.year <= 2999:
                        found_dates_info.append((parsed_date, block))
                        break
                except ValueError:
                    continue

    best_date = None
    recognition_confidence = 0.0
    type_confidence = 0.5
    filtered_word_blocks = []

    if found_dates_info:
        sorted_dates = sorted(found_dates_info, key=lambda item: item[0], reverse=True)

        for candidate_date, date_block in sorted_dates:
            is_nutrition_info = False
            text_height = abs(date_block['bounds'][0][1] - date_block['bounds'][2][1])
            SEARCH_RADIUS = text_height * 3  # 날짜 텍스트 높이의 3배 반경을 '주변'으로 정의

            # 날짜 같아 보이는 숫자 주변에 영양성분 키워드가 있으면, 날짜가 아닌 영양성분 값으로 인식
            for block in word_blocks:
                if block == date_block: continue

                if any(keyword in block['text'] for keyword in NUTRITION_KEYWORDS):
                    if calculate_distance(date_block, block) < SEARCH_RADIUS:
                        is_nutrition_info = True
                        break
            if is_nutrition_info: # 영양 정보로 판단되면 다음 날짜 후보로
                continue

            best_date = candidate_date   # 유효한 날짜 후보를 찾으면 최종 선택
            best_date_block = date_block
            recognition_confidence = best_date_block['confidence'] # 유통기한 글자의 OCR 인식 신뢰도
            filtered_word_blocks.append(best_date_block)

            # 찾은 정보가 유통기한이 맞는지에 대한 신뢰도
            min_distance = float('inf')
            closest_keyword_block = None
            if found_keywords_info:
                for keyword_block in found_keywords_info:
                    distance = calculate_distance(date_block, keyword_block)
                    if distance < min_distance:
                        min_distance = distance
                        closest_keyword_block = keyword_block

            DISTANCE_THRESHOLD = text_height * 5 # 글자 높이의 5배 이내 거리에 키워드가 있으면 유통기한으로 판단
            if min_distance < DISTANCE_THRESHOLD:
                type_confidence = 1.0 # 신뢰도 1.0 부여
                if closest_keyword_block and closest_keyword_block not in filtered_word_blocks:
                    filtered_word_blocks.append(closest_keyword_block)
            elif best_date > date.today(): # 키워드가 없지만 날짜 형태가 있고 미래인 경우
                type_confidence = 0.8 # 신뢰도 0.8 부여

            break  # 최종 날짜를 찾으면 종료

    product_name = '제품명 추출 실패'  # 추후 추가

    return {
        'product_name': product_name,
        'extracted_date': best_date,
        'date_recognition_confidence': round(recognition_confidence, 4),
        'date_type_confidence': type_confidence,
        'raw_ocr_text': raw_text,
        'filtered_word_blocks': filtered_word_blocks
    }

# 5. 결과 통합 및 신뢰도 분기 처리
def integrate_results(base_data: Dict[str, Any], yolo_result: Dict[str, Any], ocr_info: Dict[str, Any]) -> Dict[
    str, Any]:
    # 1. 기본 정보 병합
    base_data['category_yolo'] = yolo_result.get('category_name') # YOLO로 파악한 식재료 카테고리
    base_data['product_name_ocr'] = ocr_info.get('product_name') # OCR로 파악한 식재료명
    base_data['raw_ocr_text'] = ocr_info.get('raw_ocr_text')  # OCR로 파악한 텍스트 정보 (디버깅용)
    base_data['date_recognition_confidence'] = ocr_info.get('date_recognition_confidence', 0.0) # 유통기한 인식 신뢰도
    base_data['date_type_confidence'] = ocr_info.get('date_type_confidence', 0.0) # 주어진 정보가 유통기한인지에 대한 신뢰도
    base_data['ocr_word_blocks'] = ocr_info.get('filtered_word_blocks')  # OCR로 파악한 유통기한 관련 단어 목록 및 신뢰도

    final_name = ocr_info.get('product_name') or yolo_result.get('category_name') # 식재료 이름 결정
    if final_name in ['FALLBACK_MODE', None, '제품명 추출 실패']:
        final_name = '식재료 미확인'
    base_data['ingredient_name'] = final_name

    # 유통기한 신뢰도 처리
    recognition_conf = ocr_info.get('date_recognition_confidence', 0.0)
    type_conf = ocr_info.get('date_type_confidence', 0.0)
    extracted_date = ocr_info.get('extracted_date')
    RECOGNITION_THRESHOLD = 0.85  # 숫자 인식 신뢰도 임계값
    TYPE_THRESHOLD = 0.75  # 유형 신뢰도 임계값

    base_data['expiry_date'] = extracted_date

    if extracted_date:
        if extracted_date < date.today():
            base_data['expiry_date_status'] = 'EXPIRED'   # 유통기한이 과거 날짜인 경우
        elif recognition_conf >= RECOGNITION_THRESHOLD and type_conf >= TYPE_THRESHOLD:
            base_data['expiry_date_status'] = 'CONFIRMED' # 유통기한 인식, 정보 유형 신뢰도 모두 임계값 이상인 경우
            base_data['raw_ocr_text'] = None
        else:
            base_data['expiry_date_status'] = 'UNCERTAIN' # 유통기한 인식 또는 유형 신뢰도 중 하나 이상 임계값 미만인 경우
    else:
        base_data['expiry_date_status'] = 'NOT_FOUND' # 날짜를 아예 찾지 못한 경우

    return base_data
