from rest_framework import serializers
from ..Models.fridgeIngredients import FridgeIngredients
from XndApp.serializers.Ingredient_serializers import IngredientSerializer

class FridgeIngredientsSerializer(serializers.ModelSerializer):
    ingredient = serializers.SlugRelatedField(
        read_only=True,
        slug_field='name'
    )
    class Meta:
        model = FridgeIngredients
        fields = [
            'id',
            'ingredient',
            'layer',
            'stored_at',
            'storable_due',
        ]
