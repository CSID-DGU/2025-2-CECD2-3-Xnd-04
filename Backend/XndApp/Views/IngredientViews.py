from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from XndApp.Models import FridgeIngredients
from XndApp.Models import Fridge
from django.shortcuts import get_object_or_404
from ..serializers.fridge_ingredients_serializer import FridgeIngredientsSerializer
from rest_framework.permissions import AllowAny # 테스트용

class IngredientView(APIView):
    def get(self, request, fridge_id, ingredient_id):
        user_id = request.user.user_id
        fridge = get_object_or_404(Fridge, fridge_id=fridge_id, user_id=user_id)
        ingredient = get_object_or_404(FridgeIngredients, id=ingredient_id, fridge_id=fridge_id)

        serializer = FridgeIngredientsSerializer(ingredient)
        return Response(serializer.data, status=status.HTTP_200_OK)