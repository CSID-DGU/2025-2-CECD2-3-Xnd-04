# [②,③,④ 단계 구현] YOLO 호출, OCR 처리, 제품명/유통기한 추출 로직

# XndApp/Services/pipeline_logic.py

import os
import numpy as np
import cv
from django.conf import settings
from datetime import date
from typing import Dict, List, Any  # Type Hinting을 위해 추가

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
        'expiry_date_status': 'NOT_FOUND',  # CONFIRMED, UNCERTAIN, NOT_FOUND
        'uncertain_date_text': None,
        'ingredient_pic': image_path,
    }

    yolo_result = run_yolo_detection(image_path) # 1. YOLO 실행: BB 좌표 및 카테고리 추출
    ocr_raw_output = run_ocr(image_path, yolo_result) # 2. OCR 실행: 이미지 크롭 후, 클라우드 API 호출 및 원본 텍스트 수신
    ocr_info = extract_ocr_info(ocr_raw_output) # 3. 텍스트 정보 추출: 원본 텍스트에서 날짜, 제품명 등을 정규식으로 추출
    final_data = integrate_results(result_data, yolo_result, ocr_info) # 4. 결과 통합: YOLO와 OCR 결과를 병합하고 신뢰도에 따라 분기 처리
    return final_data

# 2. ② YOLO 모델 적용 (객체 탐지)
def run_yolo_detection(image_path: str) -> Dict[str, Any]:
    # TODO: settings.YOLO_MODEL_PATH를 사용하여 모델 로드 및 실행 코드 구현

    # 더미 결과 (구현 후 실제 코드로 대체)
    return {
        'category_name': '우유',
        'confidence': 0.95,
        'bounding_box': [100, 150, 400, 500],  # [xmin, ymin, xmax, ymax]
    }

# 3. ③ OCR 모델 적용 (이미지 크롭 및 텍스트 인식)
def run_ocr(image_path: str, yolo_result: Dict[str, Any]) -> Dict[str, str]:
    """ YOLO BB를 이용해 이미지를 크롭하고 OCR API를 호출하여 원본 텍스트를 반환 """
    # TODO: OpenCV 및 NumPy를 사용하여 이미지 크롭 로직 구현
    # TODO: 클라우드 OCR API 연동 및 호출

    # 더미 결과 (구현 후 실제 코드로 대체)
    # OCR API가 인식한 모든 원본 텍스트를 반환합니다.
    return {'raw_text': '제조 2024.09.25 유통기한 서울우유 24.12.30'}

# 4. 텍스트 정보 추출 (유통기한, 제품명)
def extract_ocr_info(ocr_raw_output: Dict[str, str]) -> Dict[str, Any]:
    """ OCR 원본 텍스트에서 정규식을 사용해 유통기한, 제품명 등을 추출하고 신뢰도를 측정 """
    raw_text = ocr_raw_output.get('raw_text', '')

    # TODO: raw_text에 다양한 정규식 패턴을 적용하여 날짜 추출 로직 구현
    # TODO: raw_text에서 제품명(예: YOLO 카테고리에 속하는 단어) 추출 로직 구현

    # 더미 결과 (구현 후 실제 코드로 대체)
    return {
        'product_name': '서울우유',
        'extracted_date': date(2025, 12, 30),
        'date_confidence': 0.88,
        'raw_ocr_output': raw_text
    }

# 5. ④ 결과 통합 및 신뢰도 분기 처리
def integrate_results(base_data: Dict[str, Any], yolo_result: Dict[str, Any], ocr_info: Dict[str, Any]) -> Dict[
    str, Any]:

    # 1. 기본 정보 병합
    base_data['category_yolo'] = yolo_result.get('category_name')

    # YOLO 카테고리보다 구체적인 OCR 제품명이 있다면 사용
    final_name = ocr_info.get('product_name') or yolo_result.get('category_name')
    base_data['ingredient_name'] = final_name
    base_data['product_name_ocr'] = ocr_info.get('product_name')
    base_data['uncertain_date_text'] = ocr_info.get('raw_ocr_output')

    # 2. 유통기한 신뢰도 분기 처리
    date_confidence = ocr_info.get('date_confidence', 0.0)
    CONFIDENCE_THRESHOLD = 0.90

    if date_confidence >= CONFIDENCE_THRESHOLD:
        base_data['expiry_date_status'] = 'CONFIRMED'
        base_data['expiry_date'] = ocr_info.get('extracted_date')
        base_data['uncertain_date_text'] = None  # 확정된 경우 원본 텍스트는 필요 없음
    elif date_confidence > 0.0:
        base_data['expiry_date_status'] = 'UNCERTAIN'
        base_data['expiry_date'] = ocr_info.get('extracted_date')  # 불확실해도 일단 저장
    else:  # date_confidence == 0.0 또는 날짜 추출 실패
        base_data['expiry_date_status'] = 'NOT_FOUND'  # expiry_date는 None 유지

    return base_data