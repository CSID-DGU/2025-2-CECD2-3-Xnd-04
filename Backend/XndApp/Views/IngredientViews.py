from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from XndApp.Models import FridgeIngredients
from XndApp.Models import Fridge
from django.shortcuts import get_object_or_404
from ..serializers.Ingredient_serializers import IngredientSerializer
from rest_framework.permissions import AllowAny # 테스트용

class IngredientView(APIView):

    #permission_classes = [AllowAny] #테스트용

    def get(self, request, id):

        # user_id = request.user.id
        user_id = 111 # 테스트용

        fridge = Fridge.objects.get(user_id=user_id)
        fridge_id = fridge.fridge_id

        ingredient = get_object_or_404(FridgeIngredients, id=id, fridge_id=fridge_id)
        serializer = IngredientSerializer(ingredient)
        return Response(serializer.data,status=status.HTTP_200_OK)
