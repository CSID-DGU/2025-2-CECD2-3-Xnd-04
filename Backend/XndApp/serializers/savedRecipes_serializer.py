from rest_framework import serializers
from ..Models.savedRecipes import SavedRecipes
from ..serializers.recipe_sub_info_serializer import RecipeSubInfoSerializer
from ..serializers.recipe_serializer import RecipeDetailSerializer


# 저장된 레시피의 sub정보
class SavedRecipeSerializer(serializers.ModelSerializer):
    recipe = RecipeSubInfoSerializer(read_only=True)
    class Meta:
        model = SavedRecipes
        fields = ['id', 'recipe']  # user는 request.user 기반이므로 생략

# 저장된 레시피의 모든 정보
class SavedRecipeDetailSerializer(serializers.ModelSerializer):
    recipe = RecipeDetailSerializer(read_only=True)
    class Meta:
        model = SavedRecipes
        fields = ['id', 'recipe']  # user는 request.user 기반이므로 생략
