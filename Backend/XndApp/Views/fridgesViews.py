import requests
from rest_framework.response import Response
from rest_framework import status
from rest_framework.views import APIView
from ..Models.fridge import Fridge
from ..serializers import UserSerializer
from ..serializers.fridge_serializer import FridgeSerializer
from rest_framework.permissions import AllowAny
from django.utils import timezone


# 냉장고 List View
class FridgeViews(APIView):
    # permission_classes = [AllowAny] #테스트용

    ## 냉장고 List
    def get(self, request):

        try:
            user = request.user
            fridges = Fridge.objects.filter(user=user)
            serializer = FridgeSerializer(fridges, many=True)

            return Response(
                {
                    'fridge_count': fridges.count(),
                    'fridges': serializer.data,

                },
                status=status.HTTP_200_OK
            )
        except Exception as e:
            return Response(
                {
                    'error': '냉장고 불러오기 실패!',
                    'details': str(e)
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    ## 냉장고 생성
    def post(self, request):

        data = request.data.copy()  # 단수, 냉장고 이름

        serializer = FridgeSerializer(data=data)

        if serializer.is_valid():
            try:
                serializer.validated_data['user'] = request.user
                fridge = serializer.save()
                return Response(
                    {
                        'message': '냉장고 생성 완료!',
                    },
                    status=status.HTTP_201_CREATED
                )
            except Exception as e:
                return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        else:
            print(serializer.errors)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)