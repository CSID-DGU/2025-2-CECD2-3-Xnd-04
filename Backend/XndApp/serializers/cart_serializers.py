# serializers.py
from rest_framework import serializers
from XndApp.Models.cart import Cart
from XndApp.Models.ingredients import Ingredient
from XndApp.Models.recipes import Recipes

class CartSerializer(serializers.ModelSerializer):
    ingredient_id = serializers.PrimaryKeyRelatedField(
        source='ingredient',
        queryset=Ingredient.objects.all()
    )
    recipe_id = serializers.PrimaryKeyRelatedField(
        source='recipe',
        queryset=Recipes.objects.all(),
        required=False,
        allow_null=True
    )

    class Meta:
        model = Cart
        fields = ['id', 'ingredient_id', 'recipe_id', 'quantity']

class CartDetailSerializer(serializers.ModelSerializer):
    ingredient_id = serializers.IntegerField(source='ingredient.id', read_only=True)
    ingredient_name = serializers.CharField(source='ingredient.name', read_only=True)
    recipe_id = serializers.IntegerField(source='recipe.recipe_id', read_only=True, allow_null=True)
    recipe_name = serializers.CharField(source='recipe.food_name', read_only=True, allow_null=True)

    class Meta:
        model = Cart
        fields = ['id', 'ingredient_id', 'ingredient_name', 'recipe_id', 'recipe_name', 'quantity']