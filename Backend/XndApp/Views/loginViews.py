from django.shortcuts import render
import requests
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from ..Models.user import User
from ..serializers import UserSerializer
from rest_framework_simplejwt.tokens import RefreshToken

# KakaoLoginView
class KakaoLoginView(APIView):
    def post(self, request):
        kakao_access_token = request.data.get("access_token")

        if not kakao_access_token:
            return Response({"error" : "No Access Token"},status=status.HTTP_400_BAD_REQUEST)
        
        # 여기로 access_token을 header에 실어서 Get요청을 보냄
        # access token로 user info를 요청하는 url
        kakao_url = "https://kapi.kakao.com/v2/user/me"
        header = {"Authorization" : f"Bearer {kakao_access_token}"}
        kakao_response = requests.get(kakao_url,headers=header)

        if kakao_response.status_code != 200:
            return Response({"error" : "Invalid Access Token"},status=status.HTTP_400_BAD_REQUEST)
        
        # JSON 응답 -> 딕셔너리 형태로 계정 정보 반환
        kakao_account = kakao_response.json()
        kakao_id = kakao_account.get('id')

        kakao_profile = kakao_account.get("kakao_account", {}).get("profile", {})

        name = kakao_profile.get("nickname","")
        email = kakao_account.get("kakao_account", {}).get("email", "")
        if not kakao_id:
            return Response({"error" : "No Kakao ID"},status=status.HTTP_400_BAD_REQUEST)

        # Save new User or get old User
        user, _ = User.users.get_or_create(
            social_id = kakao_id,
            social_provider = "kakao",
            defaults={
                "email": email,
                "name": name
            }
        )

        # JWT 발급
        refresh = RefreshToken.for_user(user)

        return Response({
            "refresh" : str(refresh),
            "access" : str(refresh.access_token)
        },status=status.HTTP_200_OK)
    
# NaverLoginView
class NaverLoginView(APIView):
    def post(self,request):
        naver_access_token = request.data.get("access_token")
        if not naver_access_token:
            return Response({"error" : "No Access Token"},status=status.HTTP_400_BAD_REQUEST)
        
        # 여기로 access_token을 header에 실어서 Get요청을 보냄
        # access token로 user info를 요청하는 url
        naver_url = 'https://openapi.naver.com/v1/nid/me'
        header = {"Authorization" : f"Bearer {naver_access_token}"}
        naver_response = requests.get(naver_url,headers=header)

        if naver_response.status_code != 200:
            return Response({"error" : "Invalid Access Token"},status=status.HTTP_400_BAD_REQUEST)
        
        # JSON 응답 -> 딕셔너리 형태로 계정 정보 반환
        naver_account = naver_response.json()
        user_info = naver_account['response']
        naver_id = user_info.get("id")
        email = user_info.get('email', f'{naver_id}@naver.com')
        nickname = user_info.get('nickname', '')
        if not naver_id:
            return Response({"error" : "No Naver ID"},status=status.HTTP_400_BAD_REQUEST)

        # Save new User or get old User
        user, _ = User.users.get_or_create(
            social_id = naver_id,
            social_provider = "naver",
            defaults={'email': email, 'username': nickname}
            )

        # JWT 발급
        refresh = RefreshToken.for_user(user)

        return Response({
            "refresh" : str(refresh),
            "access" : str(refresh.access_token)
        },status=status.HTTP_200_OK)