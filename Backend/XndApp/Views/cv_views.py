# [API 진입 & ⑤ DB 등록] POST 요청을 처리하고, pipeline_logic.py를 호출하여 결과를 DB에 저장하는 최종 역할을 수행합니다.

from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.permissions import AllowAny  #테스트용
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from XndApp.Services.pipeline_logic import process_image_pipeline
from django.conf import settings
import os
from XndApp.Models.fridge import Fridge
from XndApp.Models.foodStorageLife import FoodStorageLife
from XndApp.serializers.fridge_ingredients_serializer import FridgeIngredientsSerializer
from pathlib import Path

## YOLO 테스트
TEST_IMAGE_DIR = settings.MEDIA_ROOT / 'uploads'
TEST_IMAGE_FILENAME = 'test_container.jpg' # 테스트 대상 사진 변경
TEST_IMAGE_PATH = TEST_IMAGE_DIR / TEST_IMAGE_FILENAME

@api_view(['GET'])  # GET 요청으로 실행할 수 있도록 설정
def run_yolo_test(request):
    """
    YOLO와 OCR 파이프라인의 로직을 테스트하고, 로그인된 사용자 정보로 DB에 등록합니다.
    """
    # 1. 사용자 정보 및 필수 ID 확보

    # 🚨 User Model의 PK 필드명(user_id)을 사용합니다.
    # 로그인 상태가 아닐 경우 처리 (테스트용이므로 임시 ID 1 사용)
    if not request.user.is_authenticated:
        user_pk_id = 1
    else:
        # 로그인된 사용자 객체의 PK 필드인 user_id를 사용합니다.
        user_pk_id = request.user.user_id

    test_layer = 10  # 테스트용 층수

    # 2. 사용자의 냉장고 ID 가져오기 (User Model의 PK 사용)
    try:
        # Fridge Model: user=user_pk_id 대신 user_id=user_pk_id로 조회하도록 확인
        # (Fridge Model이 User Model의 FK를 user_id로 설정했다고 가정)
        user_fridge = Fridge.objects.filter(user_id=user_pk_id).first()

        if not user_fridge:
            return Response({"error": f"사용자 ID {user_pk_id}에 연결된 냉장고 정보(Fridge)를 찾을 수 없습니다."},
                            status=status.HTTP_404_NOT_FOUND)

        test_fridge_id = user_fridge.fridge_id  # Fridge Model의 PK는 fridge_id로 가정

    except Exception as e:
        return Response({"error": f"냉장고 정보 조회 오류: {e}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    # 3. 이미지 경로 확인 (기존 로직 유지)
    if not os.path.exists(TEST_IMAGE_PATH):
        return Response(
            {"error": "Test image not found. Check path:", "path": str(TEST_IMAGE_PATH)},
            status=status.HTTP_404_NOT_FOUND
        )

    # 4. 파이프라인 호출
    try:
        # 파이프라인에는 User의 PK인 user_pk_id를 전달
        pipeline_result = process_image_pipeline(user_id=user_pk_id, image_path=str(TEST_IMAGE_PATH))

        if 'error' in pipeline_result:
            raise Exception(f"Pipeline Error: {pipeline_result['error']}")

    except Exception as e:
        return Response(
            {"error": "Pipeline execution failed", "detail": str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

    # 5. DB 저장 로직 (ID 반영)
    try:
        # A. FoodStorageLife 찾기 (임시 처리)
        food_storage_life_id = 100

        # B. Serializer에 전달할 최종 데이터 조합
        final_data = {
            'fridge': test_fridge_id,  # 조회된 냉장고 ID 사용
            'layer': test_layer,
            'foodStorageLife': food_storage_life_id,
        }
        final_data.update(pipeline_result)

        # C. Serializer 유효성 검사 및 저장
        serializer = FridgeIngredientsSerializer(data=final_data)
        if serializer.is_valid():
            # serializer.save() 시 Model의 save()가 실행되어 storable_due 결정 및 DB 저장 완료
            instance = serializer.save()
            response_serializer = FridgeIngredientsSerializer(instance)

            return Response(response_serializer.data, status=status.HTTP_200_OK)
        else:
            print(f"Serializer Errors during test save: {serializer.errors}")
            return Response(
                {"error": "DB Registration Failed (Serializer Error)", "details": serializer.errors},
                status=status.HTTP_400_BAD_REQUEST
            )

    except Exception as e:
        return Response(
            {'error': 'DB 등록 중 오류 발생', 'message': str(e)},
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