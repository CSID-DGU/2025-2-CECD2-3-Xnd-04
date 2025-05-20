from rest_framework import serializers
from ..Models.recipes import Recipes
from ..Models.RecipeIngredient import RecipeIngredient
from ..Models.cart import Cart

class RecipeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Recipes
        fields = ['recipe_id', 'food_name', 'recipe_image', 'serving_size', 'cooking_time', 'cooking_level']


# serializers.py
class RecipeDetailSerializer(serializers.ModelSerializer):
    ingredients = serializers.SerializerMethodField()

    class Meta:
        model = Recipes
        fields = ['recipe_id', 'food_name', 'recipe_image', 'ingredients',
                  'ingredient_all', 'serving_size', 'cooking_time', 'cooking_level', 'steps']

    def get_ingredients(self, recipe):
        # 컨텍스트에서 사용자 정보 및 장바구니 포함 여부 가져오기
        include_cart_status = self.context.get('include_cart_status', True)
        user_id = self.context.get('user_id', 111)  # 기본값은 테스트용 ID

        # 레시피와 관련된 식재료 가져오기
        recipe_ingredients = RecipeIngredient.objects.filter(
            recipe_id=recipe.recipe_id
        ).select_related('ingredient')

        # 장바구니 상태를 포함할 경우
        if include_cart_status:
            # 사용자 장바구니에 있는 식재료 ID 목록
            cart_ingredient_ids = Cart.objects.filter(
                user_id=user_id
            ).values_list('ingredient_id', flat=True)
        else:
            cart_ingredient_ids = []

        # 식재료 정보 구성
        result = []
        for recipe_ingredient in recipe_ingredients:
            result.append({
                'id': recipe_ingredient.ingredient.id,
                'name': recipe_ingredient.ingredient.name,
                'in_cart': recipe_ingredient.ingredient.id in cart_ingredient_ids if include_cart_status else False
            })

        return result