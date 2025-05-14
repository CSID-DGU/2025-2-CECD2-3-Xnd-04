from rest_framework import serializers
from ..Models.fridgeIngredients import FridgeIngredients

class FridgeIngredientsSerializer(serializers.ModelSerializer):
    class Meta:
        model = FridgeIngredients
        fields = [
            'id',
            'ingredient_name',
            'layer',
            'stored_at',
            'storable_due',
            'category',
        ]
