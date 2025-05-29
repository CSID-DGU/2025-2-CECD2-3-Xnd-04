from django.shortcuts import render
from django.http import HttpResponse
import os

def fcm_test_view(request):
    # static 폴더에서 HTML 파일 읽기
    html_path = os.path.join(settings.BASE_DIR, 'static', 'fcm_token.html')
    with open(html_path, 'r', encoding='utf-8') as f:
        content = f.read()
    return HttpResponse(content, content_type='text/html')