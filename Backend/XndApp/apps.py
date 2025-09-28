# XndApp/apps.py

import os
from django.apps import AppConfig
from django.conf import settings
# 💡 YOLO 라이브러리 임포트 (설치 확인 필수: pip install ultralytics)
from ultralytics import YOLO

# 💡 이 기존 클래스에 모델 로드 로직을 추가합니다.
class SrmappConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'XndApp'

    # 1. 💡 전역 변수 선언: 모델 객체를 저장할 공간
    yolo_model = None

    def ready(self):
        # 2. 💡 모델 로드 로직 구현
        # 서버 시작 시 (runserver)에만 실행되도록 체크
        if os.environ.get('RUN_MAIN', None) == 'true':
            try:
                model_path = settings.YOLO_MODEL_PATH

                if os.path.exists(model_path):
                    # 모델 로드 후, 클래스 변수에 저장
                    SrmappConfig.yolo_model = YOLO(str(model_path))
                    print("✅ YOLO Model Loaded Successfully.")
                else:
                    print(f"⚠️ YOLO Model not found at: {model_path}. Running with dummy detection.")

            except ImportError:
                print("❌ Ultralytics library not installed. Cannot load YOLO.")
            except Exception as e:
                print(f"❌ Error loading YOLO model: {e}")