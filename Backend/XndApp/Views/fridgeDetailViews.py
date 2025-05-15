import requests
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from ..Models.fridge import Fridge
from ..Models.fridgeIngredients import FridgeIngredients
from ..serializers.fridge_ingredients_serializer import FridgeIngredientsSerializer


class FridgeDetailView(APIView):
    def get(self,request,fridge_id):

        try:
            fridge = Fridge.objects.get(id=fridge_id, user=request.user)
        except Fridge.DoesNotExist:
            return Response(
                {"error": "냉장고를 찾을 수 없습니다."},
                status=status.HTTP_404_NOT_FOUND)

        ingredients = FridgeIngredients.objects.filter(fridge=fridge_id).order_by('layer')
        serializer = FridgeIngredientsSerializer(ingredients, many=True)

        return Response({
            "ingredients": serializer.data
        }, status=status.HTTP_200_OK)