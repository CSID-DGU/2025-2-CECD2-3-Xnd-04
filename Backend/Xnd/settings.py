from pathlib import Path
from decouple import config
from datetime import timedelta
import os
from dotenv import load_dotenv

load_dotenv()
# import firebase_admin
# from firebase_admin import credentials

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = config('SECRET_KEY')

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True

ALLOWED_HOSTS = ['*']

# JWT settings
SIMPLE_JWT = {
    "USER_ID_FIELD": "social_id",
    "USER_ID_CLAIM": "user_id",
    "ACCESS_TOKEN_LIFETIME": timedelta(days=7),  # 액세스 토큰 유효기간 7일
    "REFRESH_TOKEN_LIFETIME": timedelta(days=30),  # 리프레시 토큰 유효기간 30일
    "ROTATE_REFRESH_TOKENS": False,
    "BLACKLIST_AFTER_ROTATION": False,
}

# Application definition

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'XndApp',
    'rest_framework',
    'rest_framework_simplejwt',
    'storages',  # django-storages 앱 등록
]

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ]
}


MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'Xnd.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'Xnd.wsgi.application'



# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': config('DB_NAME'),
        'USER': config('DB_USER'),
        'PASSWORD': config('DB_PASSWORD'),
        'HOST': config('DB_HOST', default='localhost'),
        'PORT': config('DB_PORT', default='3306'),
    }
}



AUTH_USER_MODEL = 'XndApp.User'

# Password validation
# https://docs.djangoproject.com/en/5.2/ref/settings/#auth-password-validators

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]


# Internationalization
# https://docs.djangoproject.com/en/5.2/topics/i18n/

LANGUAGE_CODE = 'ko-kr'

TIME_ZONE = 'Asia/Seoul'

USE_I18N = True

USE_TZ = True


# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/5.2/howto/static-files/

STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_DIRS = [
    BASE_DIR / "static",
]
# Default primary key field type
# https://docs.djangoproject.com/en/5.2/ref/settings/#default-auto-field

# service_account_key = {
#
#   "type": config("TYPE"),
#   "project_id": config("PROJECT_ID"),
#   "private_key_id": config("PRIVATE_KEY_ID"),
#   "private_key": config("PRIVATE_KEY").replace("\\n", "\n"),
#   "client_email": config("CLIENT_EMAIL"),
#   "client_id": config("CLIENT_ID"),
#   "auth_uri": config("AUTH_URI"),
#   "token_uri": config("TOKEN_URI"),
#   "auth_provider_x509_cert_url": config("AUTH_PROVIDER_X509_CERT_URL"),
#   "client_x509_cert_url": config("CLIENT_X509_CERT_URL"),
#   "universe_domain": config("UNIVERSE_DOMAIN"),
# }
#
# cred = credentials.Certificate(service_account_key)
# firebase_admin.initialize_app(cred)

# Celery Configuration - 개발용
# CELERY_TASK_ALWAYS_EAGER = True
# CELERY_TASK_EAGER_PROPAGATES = True

# Celery Configuration

CELERY_BROKER_URL = 'redis://localhost:6379'
CELERY_RESULT_BACKEND = 'redis://localhost:6379'
CELERY_ACCEPT_CONTENT = ['application/json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = TIME_ZONE


DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# FireBase
# FIREBASE_CREDENTIALS_PATH = os.path.join(BASE_DIR, 'firebase-service-account.json')

## CV 파이프라인 경로 설정
# YOLO 모델 저장소 경로
YOLO_MODEL_DIR = BASE_DIR / "models"
YOLO_MODEL_FILENAME = "final_ingredients_2.pt"
YOLO_MODEL_PATH = YOLO_MODEL_DIR / YOLO_MODEL_FILENAME
# Word Embedding 모델 저장소 경로
WORD_EMBEDDING_DIR = BASE_DIR / "models"
WORD_EMBEDDING_FILENAME = "food_embedding_2.word2vec"
WORD_EMBEDDING_PATH = WORD_EMBEDDING_DIR / WORD_EMBEDDING_FILENAME

# Google Cloud Vision API 인증 경로 추가
GOOGLE_APPLICATION_CREDENTIALS = BASE_DIR / "auth" / "vision_api_key.json"

# 미디어 파일 경로 (이미지 저장소)
MEDIA_ROOT = BASE_DIR / "media"
MEDIA_URL = '/media/'

# =========================================================
# S3 설정
# =========================================================

# .env에서 값 불러오기 (따옴표는 이미 .env 파일에서 처리되었으므로, 여기서는 문자열로 사용)
AWS_ACCESS_KEY_ID = os.environ.get('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = os.environ.get('AWS_SECRET_ACCESS_KEY')
AWS_STORAGE_BUCKET_NAME = os.environ.get('AWS_STORAGE_BUCKET_NAME')
AWS_S3_REGION_NAME = os.environ.get('AWS_S3_REGION_NAME') # 'ap-northeast-2'

DEFAULT_FILE_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'

# 파일 접근 권한 설정 (웹에서 이미지를 읽을 수 있도록 public-read 설정)
AWS_DEFAULT_ACL = 'public-read'

# S3 URL에 쿼리스트링(인증 정보)이 붙는 것을 방지
AWS_QUERYSTRING_AUTH = False