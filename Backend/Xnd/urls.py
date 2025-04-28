from django.contrib import admin
from django.urls import path
from XndApp.views import KakaoLoginView

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/social-login/kakao/', KakaoLoginView.as_view(), name='kakao_login'),
]
