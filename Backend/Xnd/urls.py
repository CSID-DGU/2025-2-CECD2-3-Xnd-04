# Xnd/urls.py
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.http import HttpResponse
import os

def serve_sw(request):
    """Service Worker 파일 서빙"""
    sw_path = os.path.join(settings.BASE_DIR, 'firebase-messaging-sw.js')
    try:
        with open(sw_path, 'r', encoding='utf-8') as f:
            content = f.read()
        return HttpResponse(content, content_type='application/javascript')
    except FileNotFoundError:
        return HttpResponse('Service Worker not found', status=404)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('XndApp.urls')),
    path('firebase-messaging-sw.js', serve_sw, name='firebase-sw'),  # Service Worker 서빙
]

#if settings.DEBUG:
    # 정적 파일 서빙
 #   urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
    # 미디어 파일 서빙 (새로 추가한 로직)
  #  urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)