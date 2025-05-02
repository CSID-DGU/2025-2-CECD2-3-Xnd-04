from django.contrib import admin
from django.urls import path
from XndApp.Views.loginViews import KakaoLoginView
from XndApp.Views.loginViews import NaverLoginView

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/kakao-login/', KakaoLoginView.as_view(), name='kakao_login'),
    path('api/auth/naver-login/',NaverLoginView.as_view(),name='naver_login'),
]
