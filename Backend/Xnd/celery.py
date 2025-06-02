import os
from celery import Celery

# Django settings 모듈 설정
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'Xnd.settings')

app = Celery('Xnd')

# Django settings에서 Celery 설정을 가져옴
app.config_from_object('django.conf:settings', namespace='CELERY')

# Django 앱에서 tasks.py를 자동으로 발견
app.autodiscover_tasks()

@app.task(bind=True)
def debug_task(self):
    print(f'Request: {self.request!r}')