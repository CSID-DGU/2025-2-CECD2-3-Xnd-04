from rest_framework import serializers
from ..Models.recipes import Recipes

class RecipeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Recipes
        fields = ['food_name', 'recipe_image', 'steps', 'serving_size', 'cooking_time', 'cooking_level']



