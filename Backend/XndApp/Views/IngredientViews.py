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

    def patch(self, request, fridge_id, ingredient_id):
        user_id = request.user.user_id

        get_object_or_404(Fridge, fridge_id=fridge_id, user_id=user_id)

        # 수정할 식재료 인스턴스 조회
        ingredient_instance = get_object_or_404(
            FridgeIngredients,
            id=ingredient_id,
            fridge_id=fridge_id
        )

        serializer = FridgeIngredientsSerializer(
            ingredient_instance,
            data=request.data,
            partial=True # 요청 보낸 부분만 수정 (식재료명/유통기한)
        )

        if serializer.is_valid():
            instance = serializer.save()

            return Response(
                FridgeIngredientsSerializer(instance).data,
                status=status.HTTP_200_OK
            )

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)