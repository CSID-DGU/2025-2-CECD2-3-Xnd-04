from rest_framework import serializers
from ..Models.fridgeIngredients import FridgeIngredients

class IngredientSerializer(serializers.ModelSerializer):
    class Meta:
        model = FridgeIngredients
        fields = ['ingredient_name','stored_at', 'storable_due']