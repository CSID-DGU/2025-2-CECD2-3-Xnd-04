from rest_framework import serializers
from ..Models.recipes import Recipes
from ..Models.RecipeIngredient import RecipeIngredient
from ..Models.cart import Cart
from ..Models.savedRecipes import SavedRecipes
from ..Models.tags import Tags


# 1. Tag Serializer
class TagSerializer(serializers.ModelSerializer):
    class Meta:
        model = Tags
        fields = ['tag_id', 'tag_name']

# 2. RecipeIngredient Serializer
class RecipeIngredientDetailSerializer(serializers.ModelSerializer):
    # RecipeIngredient 모델에서 재료의 ID와 Name, 장바구니 상태를 가져옵니다.
    id = serializers.ReadOnlyField(source='ingredient.id')
    name = serializers.ReadOnlyField(source='ingredient.name')
    in_cart = serializers.SerializerMethodField()

    class Meta:
        model = RecipeIngredient
        # amount 필드를 포함할 필요가 없다면 제외합니다. (기존 JSON에 없었음)
        fields = ['id', 'name', 'in_cart']

    def get_in_cart(self, obj):
        # 장바구니 상태 체크 로직
        user_id = self.context.get('user_id')
        if not user_id:
            return False
        # Cart 모델이 RecipeIngredient의 ingredient 필드를 참조하는지 확인
        return Cart.objects.filter(user_id=user_id, ingredient_id=obj.ingredient.id).exists()

# 3. Recipe List Serializer (List View)
class RecipeSerializer(serializers.ModelSerializer):
    is_saved = serializers.SerializerMethodField()

    class Meta:
        model = Recipes
        fields = ['recipe_id', 'food_name', 'recipe_image', 'serving_size', 'cooking_time', 'cooking_level', 'is_saved']

    def get_is_saved(self, obj):
        user_id = self.context.get('user_id')
        if not user_id:
            return False
        return SavedRecipes.objects.filter(user_id=user_id, recipe=obj).exists()

# 4. Recipe Detail Serializer (Detail View)
class RecipeDetailSerializer(serializers.ModelSerializer):
    # M2M 관계 (RecipeIngredient 모델을 통해 연결된 재료)
    ingredients = RecipeIngredientDetailSerializer(source='recipeingredient_set', many=True, read_only=True)

    # M2M 관계 (Tags 모델)
    tags = TagSerializer(many=True, read_only=True)  # Recipes 모델의 tags 필드명과 일치

    # 즐겨찾기 저장 유무 (Detail에서도 필요하다면 추가)
    is_saved = serializers.SerializerMethodField()

    class Meta:
        model = Recipes
        fields = [
            'recipe_id', 'food_name', 'recipe_image', 'ingredients',
            'tags',
            'ingredient_all', 'serving_size', 'cooking_time', 'cooking_level', 'steps',
            'is_saved'
        ]

    def get_is_saved(self, obj):
        # List Serializer와 동일한 로직
        user_id = self.context.get('user_id')
        if not user_id:
            return False
        return SavedRecipes.objects.filter(user_id=user_id, recipe=obj).exists()