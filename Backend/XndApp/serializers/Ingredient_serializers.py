from rest_framework import serializers
from ..Models.fridgeIngredients import FridgeIngredients

class IngredientSerializer(serializers.ModelSerializer):
    ingredient = serializers.SlugRelatedField(
        read_only=True,
        slug_field='name'
    )
    class Meta:
        model = FridgeIngredients
        fields = ['ingredient_name','stored_at', 'storable_due']