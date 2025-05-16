from rest_framework import serializers
from ..Models.recipes import Recipes

class RecipeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Recipes
        fields = ['recipe_id', 'food_name', 'recipe_image', 'ingredient_all']


class RecipeDetailSerializer(serializers.ModelSerializer):
    class Meta:
        model = Recipes
        fields = ['food_name', 'recipe_image', 'ingredient_all', 'serving_size', 'cooking_time', 'cooking_level', 'steps']

        # 식재료가 장바구니에 담겼는지 여부 추가