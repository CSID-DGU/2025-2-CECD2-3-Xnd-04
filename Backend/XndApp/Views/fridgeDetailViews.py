import requests
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from ..Models.fridge import Fridge
from ..Models.fridgeIngredients import FridgeIngredients
from ..serializers.fridge_ingredients_serializer import FridgeIngredientsSerializer
from rest_framework.permissions import AllowAny
from django.utils import timezone
from datetime import timedelta, datetime
from django.conf import settings
from XndApp.Services.pipeline_logic import process_image_pipeline
from XndApp.Models.foodStorageLife import FoodStorageLife
import os
import time
import traceback
import cv2
import numpy as np

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

    # 식재료 인식 결과 DB 저장
    def post(self, request, fridge_id):
        user = request.user

        # 1. 냉장고 및 필수값 확인
        try:
            fridge = Fridge.objects.get(fridge_id=fridge_id, user=user)
        except Fridge.DoesNotExist:
            return Response({"error": "냉장고를 찾을 수 없습니다."}, status=status.HTTP_404_NOT_FOUND)

        # 이미지 파일 리스트 수집
        image_files = []
        sorted_keys = sorted([k for k in request.FILES.keys() if k.startswith('image_')])
        for key in sorted_keys:
            image_files.append(request.FILES[key])

        layer = request.data.get('layer')
        action_type = request.data.get('action_type')

        # 필수값 확인
        if not image_files or layer is None:
            return Response(
                {"error": "이미지 파일들('image_0'...)과 층('layer')은 필수 입력값입니다."},
                status=status.HTTP_400_BAD_REQUEST)

        try:
            layer_value = int(layer)
        except (ValueError, TypeError):
            return Response({"error": "layer 필드는 정수(숫자)여야 합니다."}, status=status.HTTP_400_BAD_REQUEST)

        user_identifier = str(user.pk)
        pipeline_user_id = user.pk

        saved_file_paths = []

        try:
            timestamp = int(time.time())

            for idx, img_file in enumerate(image_files):
                file_extension = os.path.splitext(img_file.name)[1]
                filename = f"{user_identifier}_{timestamp}_{idx}{file_extension}"

                file_path = os.path.join(settings.MEDIA_ROOT, 'uploaded_images', filename)
                os.makedirs(os.path.dirname(file_path), exist_ok=True)

                with open(file_path, 'wb+') as destination:
                    for chunk in img_file.chunks():
                        destination.write(chunk)

                saved_file_paths.append(file_path)

            pipeline_result = None

        except Exception as e:
            # 실패 시 임시 파일 정리
            for p in saved_file_paths:
                if os.path.exists(p): os.remove(p)
            return Response(
                {'error': '이미지 저장 실패', 'message': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        try:
            # 2. 파이프라인 실행
            pipeline_result = process_image_pipeline(
                pipeline_user_id,
                image_paths=saved_file_paths,
                layer=layer,
                action_type=action_type
            )

            if 'error' in pipeline_result:
                raise Exception(f"Pipeline Error: {pipeline_result['error']}")

        except Exception as e:
            print(f"Pipeline Execution Error: {e}")
            traceback.print_exc()
            return Response(
                {'error': '식재료 인식 파이프라인 오류', 'message': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        # ------------------------------------------------------------------
        # 3. 파일 이름 변경 및 Collage 생성 (디버깅/관리 목적)
        # ------------------------------------------------------------------

        # 1. 결과 데이터 가져오기
        detected_name = pipeline_result.get('ingredient_name', '미확인')
        if not detected_name: detected_name = '미확인'

        status_kor = '입고' if pipeline_result.get('status') == 'inbound' else '출고'
        timestamp_for_name = pipeline_result.get('raw_timestamp', int(time.time())) # 파이프라인 내부에서 쓰는 타임스탬프 활용

        # 2. Best Shot의 원래 경로 찾기
        best_shot_path = pipeline_result.get('ingredient_pic')

        # 3. 새로운 파일명
        new_filename = f"{timestamp_for_name}_{detected_name}_{status_kor}.jpg"
        new_file_path = os.path.join(settings.MEDIA_ROOT, 'uploaded_images', new_filename)
        final_rel_path = ""

        if best_shot_path and os.path.exists(best_shot_path):
            try:
                os.rename(best_shot_path, new_file_path)
                final_rel_path = os.path.join('uploaded_images', new_filename).replace('\\', '/')
                print(f"✅ 파일명 변경 완료: {new_filename}")
            except OSError as e:
                print(f"⚠️ 파일명 변경 실패 (그냥 원본 사용): {e}")
                if str(settings.MEDIA_ROOT) in best_shot_path:
                    final_rel_path = os.path.relpath(best_shot_path, settings.MEDIA_ROOT).replace('\\', '/')
                else:
                    final_rel_path = best_shot_path
        else:
            final_rel_path = best_shot_path

        # 4. [디버깅용] 10장 요약본(Collage) 만들기
        try:
            images_to_concat = []
            for idx, path in enumerate(saved_file_paths):
                if os.path.exists(path):
                    img = cv2.imread(path)
                    if img is not None:
                        h, w = img.shape[:2]
                        new_w = 300
                        new_h = int(h * (300 / w))
                        resized_img = cv2.resize(img, (new_w, new_h))
                        item_name = pipeline_result.get('ingredient_name', 'UNKNOWN')
                        cv2.putText(resized_img, f"F:{idx} | {item_name}",
                                    (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
                        images_to_concat.append(resized_img)

            if images_to_concat:
                summary_img = cv2.hconcat(images_to_concat)
                summary_filename = f"{timestamp_for_name}_{detected_name}_DEBUG_SUMMARY_{status_kor}.jpg"
                summary_path = os.path.join(settings.MEDIA_ROOT, 'uploaded_images', summary_filename)
                cv2.imwrite(summary_path, summary_img)
                print(f"👀 [디버깅] 요약 이미지 생성 완료: {summary_filename}")

        except Exception as e:
            print(f"⚠️ 디버깅 이미지 생성 실패: {e}")

        # 5. [청소] Best Shot이 아닌 나머지 삭제
        for temp_path in saved_file_paths:
            if temp_path != best_shot_path and os.path.exists(temp_path):
                try:
                    os.remove(temp_path)
                except:
                    pass

        # ------------------------------------------------------------------
        # 4. DB 저장 및 응답
        # ------------------------------------------------------------------

        determined_name = pipeline_result.get('ingredient_name') or ''
        determined_name = determined_name.strip()

        food_storage_life_obj = FoodStorageLife.objects.filter(name__iexact=determined_name).first()
        food_storage_life_id = food_storage_life_obj.id if food_storage_life_obj else None

        if not food_storage_life_obj:
            print(f"[{determined_name}]의 FoodStorageLife DB 매핑에 실패하여 ID가 None으로 저장됩니다.")

        final_data = {
            'fridge': fridge_id,
            'layer': pipeline_result.get('layer', layer_value),
            'status': pipeline_result.get('status', 'inbound'),
            'ingredient_pic': final_rel_path,
            'ingredient_name': pipeline_result.get('ingredient_name'),
            'category_yolo': pipeline_result.get('category_yolo'),
            'yolo_confidence': pipeline_result.get('yolo_confidence'),
            'product_name_ocr': pipeline_result.get('product_name_ocr'),
            'product_similarity_score': pipeline_result.get('product_similarity_score'),
            'expiry_date': pipeline_result.get('expiry_date'),
            'expiry_date_status': pipeline_result.get('expiry_date_status'),
            'date_recognition_confidence': pipeline_result.get('date_recognition_confidence'),
            'date_type_confidence': pipeline_result.get('date_type_confidence'),
            'foodStorageLife': food_storage_life_id,
        }

        # 5. 저장
        if final_data.get('expiry_date_status') == 'UNCERTAIN':
            final_data['expiry_date'] = None

        serializer = FridgeIngredientsSerializer(data=final_data)

        if serializer.is_valid():
            instance = serializer.save(fridge=fridge)
            response_serializer = FridgeIngredientsSerializer(instance)

            # [최종 응답] Pi 요청인 경우
            if request.data.get('action_type') == 'analyzing':

                final_log_summary = {
                    "status": pipeline_result.get('status', 'N/A'),
                    "layer": pipeline_result.get('layer', 'N/A'),
                    "item_name": pipeline_result.get('ingredient_name', '미확인'),
                    "yolo_conf": pipeline_result.get('yolo_confidence', 0.0),

                    "raw_start_x": pipeline_result.get('raw_start_x', 0.0),
                    "raw_end_x": pipeline_result.get('raw_end_x', 0.0),
                    "raw_start_y": pipeline_result.get('raw_start_y', 0.0),
                    "raw_end_y": pipeline_result.get('raw_end_y', 0.0),

                    "detail_log": pipeline_result.get('decision_log', '로그 정보 없음'),
                    "log": "AI pipeline executed successfully."
                }
                return Response(final_log_summary, status=status.HTTP_201_CREATED)

            else:
                # [최종 응답] 일반 모바일 앱 요청: 기존 DB 정보 전체 리턴
                return Response(response_serializer.data, status=status.HTTP_201_CREATED)

        else:
            print(f"Serializer Errors: {serializer.errors}")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)