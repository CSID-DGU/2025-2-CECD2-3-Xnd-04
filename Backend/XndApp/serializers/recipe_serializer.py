from rest_framework import serializers
from ..Models.recipes import Recipes
from ..Models.RecipeIngredient import RecipeIngredient
from ..Models.cart import Cart
from ..Models.savedRecipes import SavedRecipes

# 레시피 sub 정보 (List View)
class RecipeSerializer(serializers.ModelSerializer):

    # 응답 반환시에만 쓰이는 변수로 실제 모델에는 존재 X
    # 즐겨찾기 저장 유무
    is_saved = serializers.SerializerMethodField()

    class Meta:
        model = Recipes
        fields = ['recipe_id', 'food_name', 'recipe_image', 'serving_size', 'cooking_time', 'cooking_level','is_saved']

    def get_is_saved(self, obj):
        user_id = self.context.get('user_id')
        if not user_id:
            return False
        return SavedRecipes.objects.filter(user_id=user_id, recipe=obj).exists()



# 레시피 전체 정보 (Detail View)
class RecipeDetailSerializer(serializers.ModelSerializer):
    ingredients = serializers.SerializerMethodField()

    class Meta:
        model = Recipes
        fields = ['recipe_id', 'food_name', 'recipe_image', 'ingredients',
                  'ingredient_all', 'serving_size', 'cooking_time', 'cooking_level', 'steps']

    def get_ingredients(self, recipe):
        # 컨텍스트에서 사용자 정보 및 장바구니 포함 여부 가져오기
        include_cart_status = self.context.get('include_cart_status', True)
        user_id = self.context.get('user_id')  # 기본값은 테스트용 ID

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