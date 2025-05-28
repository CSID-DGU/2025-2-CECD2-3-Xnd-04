# 레시피 리스트, 레시피 상세 조회
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.db.models import Q
from ..Models.recipes import Recipes
from XndApp.serializers.recipe_serializer import RecipeSerializer, RecipeDetailSerializer
from django.utils import timezone
from XndApp.Models.fridgeIngredients import FridgeIngredients
from datetime import timedelta
from django.shortcuts import get_object_or_404
from rest_framework.permissions import AllowAny # 테스트용
from XndApp.Models.cart import Cart
from XndApp.Models.user import User
from XndApp.Models.recipes import Recipes
from XndApp.Models.RecipeIngredient import RecipeIngredient
from XndApp.Models.savedRecipes import SavedRecipes

# 입력 검색 및 키워드 검색을 통한 레시피 (요리명, 이미지, 재료, 조리 순서 / 조리시간, 기준인원, 난이도) 조회

# 사전 정의 키워드
PREDEFINED_KEYWORDS = {
    '빠른요리': {'cooking_time': '15분 이내'},
    '특별한날': {'cooking_level' : '고급', 'category2': '영양식'},
    '쉬운요리': {'cooking_level': '아무나'},
    '다이어트':{'food_name__icontains':'다이어트'},
}

class RecipeView(APIView):



    def get(self, request):

        query = request.query_params.get('query', '')           # 일반 검색 (제목, 태그, 재료)
        keyword = request.query_params.get('keyword', '')       # 키워드 (수집 카테고리, 조건 기반 카테고리, 트렌드)
        ingredients = request.query_params.getlist('ingredient', []) # 재료 필드만 검색

        # 기본 쿼리셋
        recipes = Recipes.objects.all()

        # 검색어
        if query:
            recipes = recipes.filter(
                Q(food_name__icontains=query) |
                Q(tags__tag_name__icontains=query)
                # | Q(ingredient_all__icontains=query)
            ).distinct()


        # 키워드
        if keyword:
            if keyword in PREDEFINED_KEYWORDS:
                filter_conditions = PREDEFINED_KEYWORDS[keyword]
                recipes = recipes.filter(**filter_conditions)
            else:
                # 카테고리의 내용을 키워드인 것처럼. ...
                recipes = recipes.filter(
                    Q(category1__icontains=keyword) | # 볶음, 끓이기,
                    Q(category2__icontains=keyword) | # 일상, 초스피드, 영양식,
                    Q(category3__icontains=keyword) | # 소고기, 돼지고기, 닭고기, 해물류, 채소류, 달걀/유제품,
                    Q(category4__icontains=keyword)   # 밑반찬, 메인반찬, 국/탕, 찌개
                )

        # 재료 선택
        if ingredients:
            for ingredient in ingredients:
                recipes = recipes.filter(ingredient_all__icontains=ingredient)

        total_count = recipes.count()

        # 유통 기한 임박 재료가 포함된 레시피부터 정렬 (근데 5일 이하로 남은 식재료만 고려함)
        recipes = self.prioritize_by_expiring_ingredients(
            list(recipes),
            user_id = request.user.user_id

        )

        # 페이지네이션
        page = int(request.query_params.get('page', '1'))
        page_size = int(request.query_params.get('page_size', '10'))
        start = (page - 1) * page_size
        end = start + page_size

        paginated_recipes = recipes[start:end]

        # 시리얼라이징
        serializer = RecipeSerializer(paginated_recipes, many=True)

        return Response({
            'count': total_count,
            'page': page,
            'page_size': page_size,
            'results': serializer.data
        })

    def prioritize_by_expiring_ingredients(self, recipe_list, user_id):
        """
        유통기한 임박(5일 이내) 재료가 포함된 레시피를 우선적으로 정렬합니다.

        Args:
            recipe_list: 레시피 객체 리스트
            user_id: 사용자 ID

        Returns:
            정렬된 레시피 리스트
        """
        now = timezone.now()

        # 5일 이내 유통기한 임박 재료 가져오기
        expiring_ingredients = FridgeIngredients.objects.filter(
            fridge__user_id=user_id,
            storable_due__lte=now + timedelta(days=5)
        ).order_by('storable_due')  # 유통기한 임박순 정렬

        # 임박 재료가 없으면 원래 순서 유지
        if not expiring_ingredients.exists():
            return recipe_list

        # 임박 재료 이름 목록
        expiring_names = [ing.ingredient_name.lower() for ing in expiring_ingredients]

        # 각 레시피에 대해 임박 재료 매칭 정보 및 가중치 추가
        recipes_with_weights = []

        for recipe in recipe_list:
            recipe_ingredients = recipe.ingredient_all.split(',')
            recipe_ingredients = [ing.strip() for ing in recipe_ingredients]

            # 매칭되는 임박 재료 찾기
            matching_count = 0
            total_weight = 0

            for i, ing_name in enumerate(expiring_names):
                if any(ing_name in recipe_ing for recipe_ing in recipe_ingredients):
                    matching_count += 1

                    # 임박한 재료일수록 높은 가중치
                    weight = len(expiring_names) - i
                    total_weight += weight

            # 가중치 정보 추가
            recipes_with_weights.append({
                'recipe': recipe,
                'matching_count': matching_count,
                'total_weight': total_weight,
                'has_expiring': matching_count > 0
            })

        # 가중치 기반 정렬
        # 1. 임박 재료 포함 여부 (True 우선)
        # 2. 매칭되는 임박 재료의 총 가중치 (높을수록 우선)
        recipes_with_weights.sort(
            key=lambda x: (x['has_expiring'], x['total_weight']),
            reverse=True
        )

        # 정렬된 레시피 객체만 반환
        return [item['recipe'] for item in recipes_with_weights]


# 레시피 상세 정보 조회
# views.py
class RecipeDetailView(APIView):

    def get(self, request, recipe_id):
        recipe = get_object_or_404(Recipes, recipe_id=recipe_id)
        user=request.user

        # 사용자 정보 (실제 환경에서는 request.user.id 사용)
        user_id = 111  # 테스트용
        
        #해당 레시피 재료
        recipeIngredients = Recipes.objects.filter(recipe_id=recipe_id)

        #사용자의 장바구니 재료 목록
        cartIngredients = Cart.objects.filter(user=user).values_list('ingredient__name',flat=True)
        
        #사용자의 냉장고 속 재료 목록
        fridgeIngredients = FridgeIngredients.objects.filter(user=user).values_list('ingredient_all',flat=True)
        

        #재료 명 + 장바구니 포함 여부
        ingredients = []

        for recipeIngredient in recipeIngredients:
            # 장바구니 상태 포함 여부
            include_cart_status = recipeIngredient in cartIngredients or recipeIngredient in fridgeIngredients
            ingredients.append({
                "ingredient": recipeIngredient,
                "include_cart_status": include_cart_status
            })
        
        # 시리얼라이저 적용
        serializer = RecipeDetailSerializer(recipe, context={'ingredients': ingredients})

        return Response(serializer.data,status=status.HTTP_200_OK) 