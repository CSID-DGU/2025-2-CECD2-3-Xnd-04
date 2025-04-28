from django.shortcuts import render
import requests
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import User
from .serializers import UserSerializer
from rest_framework_simplejwt.tokens import RefreshToken

class KakaoLoginView(APIView):
    def Post(self, request):
        kakao_access_token = request.data.get("access_token")

        if not kakao_access_token:
            return Response({"error" : "No Access Token"},status=status.HTTP_400_BAD_REQUEST)
        
        # 여기로 access_token을 header에 실어서 Get요청을 보냄
        kakao_url = "https://kapi.kakao.com/v2/user/me"
        header = {"Authorization" : f"Bearer {kakao_access_token}"}
        kakao_response = requests.get(kakao_url,headers=header)

        if kakao_response.status_code != 200:
            return Response({"error" : "Invalid Access Token"},status=status.HTTP_400_BAD_REQUEST)
        
        # JSON 응답 -> 딕셔너리 형태로 계정 정보 반환
        kakao_account = kakao_response.json()
        kakao_id = kakao_account.get("id")
        if not kakao_id:
            return Response({"error" : "No Kakao ID"},status=status.HTTP_400_BAD_REQUEST)

        # Save new User or get old User
        user = User.users.get_or_create(social_id = kakao_id,social_provider = "kakao")

        # JWT 발급
        refresh = RefreshToken.for_user(user)

        return Response({
            "refresh" : str(refresh),
            "access" : str(refresh.access_token)
        },status=status.HTTP_200_OK)