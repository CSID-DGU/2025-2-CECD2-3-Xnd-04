# XndApp/apps.py

import os
from django.apps import AppConfig
from django.conf import settings
from ultralytics import YOLO
from gensim.models import Word2Vec


class SrmappConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'XndApp'

    yolo_model = None
    word_embedding_model = None  # Word2Vec 모델 변수 추가

    def ready(self): # 서버 시작 시 AI 모델 실행
        if os.environ.get('RUN_MAIN', None) == 'true':

            # YOLO 모델 로드
            try:
                model_path = settings.YOLO_MODEL_PATH

                if os.path.exists(model_path):
                    SrmappConfig.yolo_model = YOLO(str(model_path))
                    print("✅ YOLO Model Loaded Successfully.")
                else:
                    print(f"⚠️ YOLO Model not found at: {model_path}. Running with dummy detection.")

            except ImportError:
                print("❌ Ultralytics library not installed. Cannot load YOLO.")
            except Exception as e:
                print(f"❌ Error loading YOLO model: {e}")

            # Word2Vec 모델 로드
            try:
                embedding_path = settings.WORD_EMBEDDING_PATH

                if os.path.exists(embedding_path):
                    SrmappConfig.word_embedding_model = Word2Vec.load(str(embedding_path))
                    print("✅ Word Embedding Model Loaded Successfully.")
                else:
                    print(f"⚠️ Word Embedding Model not found at: {embedding_path}. Running without embedding.")

            except ImportError:
                # gensim 라이브러리가 설치되지 않은 경우
                print("❌ Gensim library not installed. Cannot load Word2Vec.")
            except Exception as e:
                # 모델 파일 자체가 손상되었거나 로드에 실패한 경우
                print(f"❌ Error loading Word Embedding model: {e}")