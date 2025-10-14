# [API 진입 & ⑤ DB 등록] POST 요청을 처리하고, pipeline_logic.py를 호출하여 결과를 DB에 저장하는 최종 역할을 수행합니다.

from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.permissions import AllowAny  #테스트용
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from XndApp.Services.pipeline_logic import process_image_pipeline
from django.conf import settings
import os
from pathlib import Path

## YOLO 테스트
TEST_IMAGE_DIR = settings.MEDIA_ROOT / 'uploads'
TEST_IMAGE_FILENAME = 'test_container.jpg' # 테스트 대상 사진 변경
TEST_IMAGE_PATH = TEST_IMAGE_DIR / TEST_IMAGE_FILENAME

@api_view(['GET'])  # GET 요청으로 실행할 수 있도록 설정
@permission_classes([AllowAny])
def run_yolo_test(request):
    """
    YOLO와 OCR 파이프라인의 로직만 테스트하기 위한 임시 뷰.
    실제 이미지 업로드 기능이 아님.
    """
    # 1. 이미지 경로 확인
    if not os.path.exists(TEST_IMAGE_PATH):
        return Response(
            {"error": "Test image not found. Check path:", "path": str(TEST_IMAGE_PATH)},
            status=status.HTTP_404_NOT_FOUND
        )

    # 2. 하드코딩된 경로로 메인 파이프라인 함수 호출
    try:
        # user_id는 임시로 1을 사용
        result = process_image_pipeline(user_id=1, image_path=str(TEST_IMAGE_PATH))

        # 3. 결과 반환
        return Response(result, status=status.HTTP_200_OK)

    except Exception as e:
        return Response(
            {"error": "Pipeline execution failed", "detail": str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

# 🚨 임시 뷰 함수: 아직 로직은 없지만, URL 연결을 위해 존재해야 합니다.
@api_view(['POST'])
def handle_detection_post(request):
    """
    CV 파이프라인의 API 진입점입니다.
    현재는 연결 확인을 위해 임시로 200 OK를 반환합니다.
    """
    # TODO: 최종적으로는 pipeline_logic.process_image_pipeline을 호출해야 함

    # 💡 URL 연결 확인용 임시 응답
    return Response(
        {"message": "CV Detection API endpoint is connected (Temporary Response)."},
        status=status.HTTP_200_OK
    )