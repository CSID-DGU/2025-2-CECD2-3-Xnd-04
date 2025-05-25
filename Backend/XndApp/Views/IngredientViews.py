from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from XndApp.Models import FridgeIngredients
from XndApp.Models import Fridge
from django.shortcuts import get_object_or_404
from ..serializers.Ingredient_serializers import IngredientSerializer
from rest_framework.permissions import AllowAny # 테스트용

class IngredientView(APIView):
    def get(self, request, fridge_id, ingredient_id):  # 매개변수 수정
        user_id = request.user.user_id

        # 냉장고 소유권 확인
        fridge = get_object_or_404(Fridge, fridge_id=fridge_id, user_id=user_id)

        # 해당 냉장고의 특정 재료 가져오기
        ingredient = get_object_or_404(FridgeIngredients, id=ingredient_id, fridge_id=fridge_id)

        serializer = IngredientSerializer(ingredient)
        return Response(serializer.data, status=status.HTTP_200_OK)
