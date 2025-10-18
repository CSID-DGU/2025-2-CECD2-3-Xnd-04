import requests
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from ..Models.fridge import Fridge
from ..Models.fridgeIngredients import FridgeIngredients
from ..serializers.fridge_ingredients_serializer import FridgeIngredientsSerializer
from rest_framework.permissions import AllowAny
from django.utils import timezone
from datetime import timedelta
from django.conf import settings
from XndApp.Services.pipeline_logic import process_image_pipeline
from XndApp.Models.foodStorageLife import FoodStorageLife
import os
import time
import traceback

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
            traceback.print_exc()
            return Response(
                {'error': '서버 오류', 'message': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def _calculate_default_expiry(self, ingredient_name, expiry_date_cv):

        # 1. CV로 유통기한이 인식된 경우, 그것을 최우선으로 사용
        if expiry_date_cv:
            return expiry_date_cv

        # 2. 유통기한 미인식 시: DB에서 기본 보관 기간 조회하여 자동 계산
        try:
            storage_info = FoodStorageLife.objects.get(name__iexact=ingredient_name)
            default_days = storage_info.storage_life

            # 현재 날짜에 기본 기간을 더하여 storable_due 계산
            calculated_date = timezone.now().date() + timedelta(days=default_days)
            return timezone.make_aware(timezone.datetime.combine(calculated_date, timezone.datetime.min.time()))

        except FoodStorageLife.DoesNotExist:
            # 인식된 유통기한도 없고, DB에서도 매칭되는 기본 기한이 없는 경우
            print(f"[{ingredient_name}]의 유통기한 정보가 없어 storable_due가 NULL로 저장됩니다.")
            return None
        except Exception as e:
            # 기타 DB 조회 오류 처리
            print(f"FoodStorageLife DB 조회 중 오류 발생: {e}")
            return None

    # 식재료 인식 결과 DB 저장
    def post(self, request, fridge_id):
        user = request.user

        # 1. 필수 입력값 확인 및 유효성 검사
        try:
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
        pipeline_user_id = user.pk

        try:  # 2. 이미지 저장 및 경로 확보
            file_extension = os.path.splitext(uploaded_file.name)[1]
            filename = f"{user_identifier}_{int(time.time())}{file_extension}"
            file_path = os.path.join(settings.MEDIA_ROOT, 'uploaded_images', filename)
            os.makedirs(os.path.dirname(file_path), exist_ok=True)  # 저장 경로가 없으면 생성

            with open(file_path, 'wb+') as destination:
                for chunk in uploaded_file.chunks():
                    destination.write(chunk)

            pipeline_image_path = file_path  # 파이프라인에 전달할 절대 경로
            pipeline_result = None

        except Exception as e:
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
        determined_name = pipeline_result.get('ingredient_name') or ''
        determined_name = determined_name.strip()

        expiry_date_cv = pipeline_result.get('extracted_date')

        # 5. 유통기한 자동 결정 로직 호출
        final_storable_due = self._calculate_default_expiry(
            determined_name,
            expiry_date_cv
        )

        food_storage_life_obj = FoodStorageLife.objects.filter(name__iexact=determined_name).first()

        if food_storage_life_obj: # 보관기한 DB에 없는 경우
            food_storage_life_id = food_storage_life_obj.id
        else:
            food_storage_life_id = None
            print(f"[{determined_name}]의 FoodStorageLife DB 매핑에 실패하여 ID가 None으로 저장됩니다.")

        # Serializer에 전달할 최종 데이터 조합
        final_data = {
            'fridge': fridge_id,
            'layer': layer_value,
            'ingredient_pic': f"uploaded_images/{filename}",

            'ingredient_name': pipeline_result.get('ingredient_name'),
            'storable_due': final_storable_due,  # 계산된 최종 유통기한 값 (None 가능)

            'category_yolo': pipeline_result.get('category_yolo'),
            'yolo_confidence': pipeline_result.get('yolo_confidence'),
            'product_name_ocr': pipeline_result.get('product_name_ocr'),
            'product_similarity_score': pipeline_result.get('product_similarity_score'),

            'expiry_date': pipeline_result.get('extracted_date'),
            'expiry_date_status': pipeline_result.get('expiry_date_status'),
            'date_recognition_confidence': pipeline_result.get('date_recognition_confidence'),
            'date_type_confidence': pipeline_result.get('date_type_confidence'),
            'foodStorageLife': food_storage_life_id,  # None 또는 ID
        }

        # 6. Serializer 유효성 검사 및 저장
        serializer = FridgeIngredientsSerializer(data=final_data)
        if serializer.is_valid():
            instance = serializer.save(fridge=fridge)
            response_serializer = FridgeIngredientsSerializer(instance)
            return Response(response_serializer.data, status=status.HTTP_201_CREATED)
        else:  # serializer 검증 실패 시
            print(f"Serializer Errors: {serializer.errors}")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)