import requests
from rest_framework.response import Response
from rest_framework import status
from rest_framework.views import APIView
from django.utils import timezone 
from ..Models.fridge import Fridge
from XndApp.serializers.fridge_serializer import FridgeSerializer

class CreateFridgeView(APIView):
    def post(self,request):

        data = request.data.copy()
        data['user'] = request.user.id
        data['created_at'] = timezone.now()

        serializer = FridgeSerializer(data = data)
        if serializer.is_valid():
            try:
                fridge = serializer.save()
                return Response(
                    {
                        'message':'냉장고 생성 완료!',
                    },
                    status=status.HTTP_201_CREATED
                )
            except Exception as e:
                return Response({'error':str(e)},status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        else:
            return Response(serializer.errors,status=status.HTTP_400_BAD_REQUEST)
    