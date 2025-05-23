from rest_framework import serializers
from ..Models import Recipes

class RecipeSubInfoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Recipes
        fields = ['recipe_id', 'recipe_image', 'food_name', 'ingredient_all']