import requests
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from ..Models.fridge import Fridge
from ..Models.fridgeIngredients import FridgeIngredients
from ..serializers.fridge_ingredients_serializer import FridgeIngredientsSerializer
from rest_framework.permissions import AllowAny
from django.conf import settings
from XndApp.Services.pipeline_logic import process_image_pipeline
from XndApp.Models.foodStorageLife import FoodStorageLife
import os
import time

class FridgeDetailView(APIView):
    def get(self, request, fridge_id):
        user = request.user
        try:
            fridge = Fridge.objects.get(fridge_id=fridge_id, user=user)
            ingredients = FridgeIngredients.objects.filter(fridge=fridge_id).order_by('layer')
            serializer = FridgeIngredientsSerializer(ingredients, many=True)

            return Response({
                "ingredients": serializer.data,
                "fridge_id": fridge_id
            }, status=status.HTTP_200_OK)
        except Fridge.DoesNotExist:
            return Response(
                {"error": "냉장고를 찾을 수 없습니다."},
                status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            print(f"❌ FridgeDetailView GET 에러 발생: {e}")
            import traceback
            traceback.print_exc()
            return Response(
                {'error': '서버 오류', 'message': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    # 식재료 인식 결과 DB 저장
    def post(self, request, fridge_id):
        user = request.user

        try:  # 1. 필수 입력값 확인 및 유효성 검사
            fridge = Fridge.objects.get(fridge_id=fridge_id, user=user)
        except Fridge.DoesNotExist:
            return Response(
                {"error": "냉장고를 찾을 수 없습니다."},
                status=status.HTTP_404_NOT_FOUND)

        uploaded_file = request.FILES.get('ingredient_image')
        layer = request.data.get('layer')

        if not uploaded_file or layer is None:
            return Response(
                {"error": "이미지 파일('ingredient_image')과 층('layer')은 필수 입력값입니다."},
                status=status.HTTP_400_BAD_REQUEST)

        try:
            layer_value = int(layer)
        except (ValueError, TypeError):
            return Response(
                {"error": "layer 필드는 정수(숫자)여야 합니다."},
                status=status.HTTP_400_BAD_REQUEST)

        user_identifier = str(user.pk)
        pipeline_user_id = user.pk  # 파이프라인 함수에 전달할 ID

        try:  # 2. 이미지 저장 및 경로 확보
            file_extension = os.path.splitext(uploaded_file.name)[1]

            # 🚨 수정됨: user.pk를 사용하여 파일명 생성
            filename = f"{user_identifier}_{int(time.time())}{file_extension}"

            file_path = os.path.join(settings.MEDIA_ROOT, 'uploaded_images', filename)
            os.makedirs(os.path.dirname(file_path), exist_ok=True)  # 저장 경로가 없으면 생성

            with open(file_path, 'wb+') as destination:
                for chunk in uploaded_file.chunks():
                    destination.write(chunk)

            pipeline_image_path = file_path  # 파이프라인에 전달할 절대 경로

        except Exception as e:
            # User.pk 접근 오류는 이제 이 Exception으로 잡힙니다.
            return Response(
                {'error': '이미지 저장 실패', 'message': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        try:  # 3. 파이프라인 실행
            pipeline_result = process_image_pipeline(pipeline_user_id, pipeline_image_path)

            if 'error' in pipeline_result:
                raise Exception(f"Pipeline Error: {pipeline_result['error']}")

        except Exception as e:
            print(f"Pipeline Execution Error: {e}")
            return Response(
                {'error': '식재료 인식 파이프라인 오류', 'message': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        # 4. DB 저장 준비 및 foodStorageLife 찾기
        determined_name = pipeline_result.get('name')
        food_storage_life_obj = FoodStorageLife.objects.filter(name__iexact=determined_name).first()

        # 인식 실패 시 foodStorageLife ID 100 사용 (추후 구현)
        if determined_name == '식재료 미확인' or not food_storage_life_obj:
            food_storage_life_id = 100
        else:
            food_storage_life_id = food_storage_life_obj.id

        # Serializer에 전달할 최종 데이터 조합
        final_data = {
            'fridge': fridge_id,
            'layer': layer_value,
            'ingredient_pic': f"uploaded_images/{filename}",  # DB에 저장할 상대 경로
            'foodStorageLife': food_storage_life_id,

            'ingredient_name': pipeline_result.get('ingredient_name'),
            'category_yolo': pipeline_result.get('category_yolo'),
            'yolo_confidence': pipeline_result.get('yolo_confidence'),
            'product_name_ocr': pipeline_result.get('product_name_ocr'),
            'product_similarity_score': pipeline_result.get('product_similarity_score'),
            'expiry_date': pipeline_result.get('extracted_date'),
            'expiry_date_status': pipeline_result.get('expiry_date_status'),
            'date_recognition_confidence': pipeline_result.get('date_recognition_confidence'),
            'date_type_confidence': pipeline_result.get('date_type_confidence'),
        }

        # 5. Serializer 유효성 검사 및 저장
        serializer = FridgeIngredientsSerializer(data=final_data)
        if serializer.is_valid():
            instance = serializer.save()
            response_serializer = FridgeIngredientsSerializer(instance)
            return Response(response_serializer.data, status=status.HTTP_201_CREATED)
        else:  # serializer 검증 실패 시
            print(f"Serializer Errors: {serializer.errors}")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)