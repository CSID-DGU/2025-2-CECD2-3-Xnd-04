import requests
from rest_framework.response import Response
from rest_framework import status
from rest_framework.views import APIView
from ..Models.fridge import Fridge
from ..serializers.fridge_serializer import FridgeSerializer

class FridgeViews(APIView):
    def get(self,request):

        try:
            fridges = Fridge.objects.filter(user=request.user)
            serializer = FridgeSerializer(fridges,many=True)

            return Response(
                {
                    'fridge_count' : fridges.count(),
                    'fridges':serializer.data,
                    
                },
                status=status.HTTP_200_OK
            )
        except Exception as e:
            return Response(
                {
                    'error':'냉장고 불러오기 실패!',
                    'details' : str(e)
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )