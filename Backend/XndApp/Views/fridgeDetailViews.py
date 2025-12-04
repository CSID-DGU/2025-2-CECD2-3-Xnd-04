# 파일: XndApp/Views/fridge_views.py

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
from django.db.models import F
# [추가] S3 업로드를 위한 boto3 import 추가
import boto3
from botocore.exceptions import ClientError


class FridgeDetailView(APIView):
    def get(self, request, fridge_id):
        user = request.user
        try:
            fridge = Fridge.objects.get(fridge_id=fridge_id, user=user)
            # 수량 개념이 없으므로, 현재는 layer만 필터링합니다.
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

    # ===== [추가] S3 업로드 함수 =====
    def upload_to_s3(self, file_path, s3_key):
        """
        로컬 파일을 S3에 업로드하고 S3 경로(키)를 반환합니다.
        (settings에 AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_S3_REGION_NAME, AWS_STORAGE_BUCKET_NAME 필요)
        """
        try:
            # boto3 클라이언트를 사용하여 S3에 업로드
            s3_client = boto3.client(
                's3',
                aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
                aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
                region_name=settings.AWS_S3_REGION_NAME
            )

            with open(file_path, 'rb') as f:
                s3_client.upload_fileobj(
                    f,
                    settings.AWS_STORAGE_BUCKET_NAME,
                    s3_key,
                    ExtraArgs={'ContentType': 'image/jpeg'}
                )

            print(f"✅ S3 업로드 성공: {s3_key}")
            return s3_key

        except AttributeError:
            print("❌ S3 설정(AWS_ACCESS_KEY_ID 등)이 settings에 누락되었습니다.")
            raise
        except ClientError as e:
            print(f"❌ S3 업로드 실패: {e}")
            raise Exception(f"S3 업로드 오류: {str(e)}")

    # 식재료 인식 결과 DB 저장 및 업데이트
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

        # [추가] RPi가 보내는 해상도 정보 추출 (없을 경우 기본값 1920x1080 사용)
        image_width = int(request.data.get('image_width', 1920))
        image_height = int(request.data.get('image_height', 1080))

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

        # --- 로컬 임시 저장소 경로 설정 (S3 업로드 전) ---
        temp_dir = os.path.join(settings.MEDIA_ROOT, 'temp_uploaded_images')
        os.makedirs(temp_dir, exist_ok=True)

        try:
            timestamp = int(time.time())

            # 1. 모든 이미지 파일을 로컬 임시 폴더에 저장
            for idx, img_file in enumerate(image_files):
                file_extension = os.path.splitext(img_file.name)[1]
                filename = f"{user_identifier}_{timestamp}_{idx}{file_extension}"
                file_path = os.path.join(temp_dir, filename)

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
            # [수정] 해상도 인자를 pipeline_logic.py에 전달
            pipeline_result = process_image_pipeline(
                pipeline_user_id,
                image_paths=saved_file_paths,
                layer=layer,
                image_width=image_width,
                image_height=image_height,
                action_type=action_type
            )

            if 'error' in pipeline_result:
                raise Exception(f"Pipeline Error: {pipeline_result['error']}")

        except Exception as e:
            print(f"Pipeline Execution Error: {e}")
            traceback.print_exc()

            # 실패 시 임시 파일 정리
            for p in saved_file_paths:
                if os.path.exists(p): os.remove(p)

            return Response(
                {'error': '식재료 인식 파이프라인 오류', 'message': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        # ------------------------------------------------------------------
        # 3. Best Shot 선정, S3 업로드 및 청소
        # ------------------------------------------------------------------

        detected_name = pipeline_result.get('ingredient_name', '미확인')
        if not detected_name: detected_name = '미확인'

        status_kor = '입고' if pipeline_result.get('status') == 'inbound' else '출고'
        timestamp_for_name = pipeline_result.get('raw_timestamp', int(time.time()))

        best_shot_path = pipeline_result.get('ingredient_pic')

        s3_key = None

        try:
            # 3-A. S3 키 생성 및 업로드
            s3_filename = f"{user_identifier}_{timestamp_for_name}_{detected_name}_{status_kor}.jpg"
            s3_key = f"uploaded_images/{s3_filename}"

            print(f"☁️ S3에 최적 이미지 업로드 중: {s3_key}")
            s3_key = self.upload_to_s3(best_shot_path, s3_key)
            final_storage_path = s3_key  # DB에는 S3 키(경로)를 저장

        except Exception as e:
            print(f"❌ S3 최종 업로드 실패! DB에 임시 로컬 경로 저장: {e}")
            # S3 업로드 실패 시, DB에 임시 파일의 로컬 경로를 저장합니다.
            final_storage_path = best_shot_path

            # 3-B. [청소] 모든 임시 파일 삭제
        print(f"🗑️ 임시 파일 {len(saved_file_paths)}개 삭제 중...")
        for temp_path in saved_file_paths:
            if os.path.exists(temp_path):
                try:
                    os.remove(temp_path)
                except OSError as e:
                    print(f"  ⚠️ 삭제 실패: {temp_path} - {e}")

        # ------------------------------------------------------------------
        # 4. DB 저장/업데이트 로직
        # ------------------------------------------------------------------

        determined_status = pipeline_result.get('status', 'inbound')
        determined_layer = pipeline_result.get('layer', layer_value)

        food_storage_life_obj = FoodStorageLife.objects.filter(name__iexact=detected_name).first()
        food_storage_life_id = food_storage_life_obj.id if food_storage_life_obj else None

        if not food_storage_life_obj:
            print(f"[{detected_name}]의 FoodStorageLife DB 매핑에 실패하여 ID가 None으로 저장됩니다.")

        final_data = {
            # DB에 저장/업데이트할 최종 데이터 필드
            'fridge': fridge_id,
            'layer': determined_layer,
            'status': determined_status,
            'ingredient_pic': "https://xndingredientsimagestorage.s3.ap-northeast-2.amazonaws.com/" + final_storage_path,  # S3 키 또는 로컬 임시 경로
            'ingredient_name': detected_name,
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

        # --------------------------------------------------
        # 5. 분기 처리: OUTBOUND (UPDATE) vs INBOUND (POST/CREATE)
        # --------------------------------------------------

        http_status = status.HTTP_201_CREATED  # 기본값: 생성

        if determined_status == 'outbound':
            # 5-A. 출고 처리 (UPDATE: status 변경)

            # [수정] layer 필터링 제거 -> 냉장고 전체에서 해당 식재료의 가장 최근 inbound 항목을 찾음
            existing_item = FridgeIngredients.objects.filter(
                fridge=fridge_id,
                ingredient_name__iexact=detected_name,
                status='inbound'  # status가 inbound인 항목만 출고 대상으로 간주
            ).order_by('-stored_at').first()

            if existing_item:
                # 항목이 존재하면: UPDATE (status를 'outbound'로 변경)
                existing_item.status = 'outbound'
                existing_item.save(update_fields=['status'])

                print(f"✅ 출고 업데이트 완료: {detected_name} (냉장고 전체) status OUTBOUND로 변경. (출고된 재고는 Layer {existing_item.layer}에 있었음)")

                response_serializer = FridgeIngredientsSerializer(existing_item)
                response_data = response_serializer.data
                http_status = status.HTTP_200_OK

            else:
                # 항목이 없으면: 경고 및 POST 시도 안 함
                print(f"❌ 출고 실패: {detected_name} 활성 재고가 냉장고에 없습니다.")
                return Response(
                    {"error": "출고 실패", "message": f"DB에 {detected_name} 활성 재고가 없어 상태를 변경할 수 없습니다."},
                    status=status.HTTP_404_NOT_FOUND)

        else:
            # 5-B. 입고 처리 (POST / CREATE)

            if final_data.get('expiry_date_status') == 'UNCERTAIN':
                final_data['expiry_date'] = None

            serializer = FridgeIngredientsSerializer(data=final_data)

            if serializer.is_valid():
                instance = serializer.save(fridge=fridge)
                response_serializer = FridgeIngredientsSerializer(instance)
                response_data = response_serializer.data
                http_status = status.HTTP_201_CREATED

            else:
                print(f"Serializer Errors: {serializer.errors}")
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        # --------------------------------------------------
        # 6. 최종 응답
        # --------------------------------------------------

        # [최종 응답] Pi 요청인 경우 (파이프라인 로그를 포함하여 리턴)
        if request.data.get('action_type') == 'analyzing':

            final_log_summary = {
                "status": determined_status,
                "layer": determined_layer,
                "item_name": detected_name,
                "yolo_conf": pipeline_result.get('yolo_confidence', 0.0),

                "raw_start_x": pipeline_result.get('raw_start_x', 0.0),
                "raw_end_x": pipeline_result.get('raw_end_x', 0.0),
                "raw_start_y": pipeline_result.get('raw_start_y', 0.0),
                "raw_end_y": pipeline_result.get('raw_end_y', 0.0),

                "detail_log": pipeline_result.get('decision_log', '로그 정보 없음'),
                "log": "AI pipeline executed successfully."
            }
            # 출고 시에도 200 OK를 리턴하여 성공을 알림
            return Response(final_log_summary, status=http_status)

        else:
            # [최종 응답] 일반 모바일 앱 요청: 기존 DB 정보 전체 리턴
            return Response(response_data, status=http_status)