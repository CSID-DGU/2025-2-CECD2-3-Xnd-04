from rest_framework import serializers
from ..Models.fridgeIngredients import FridgeIngredients
from XndApp.serializers.Ingredient_serializers import IngredientSerializer

class FridgeIngredientsSerializer(serializers.ModelSerializer):

    class Meta:
        model = FridgeIngredients
        fields = [
            'id',
            'ingredient_name',
            'layer',
            'stored_at',
            'storable_due',
            'ingredient_pic'

        ]
