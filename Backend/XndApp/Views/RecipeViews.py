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
from rest_framework.permissions import AllowAny  # 테스트용
from XndApp.Models.cart import Cart
from XndApp.Models.user import User
from XndApp.Models.recipes import Recipes
from XndApp.Models.RecipeIngredient import RecipeIngredient
from XndApp.Models.savedRecipes import SavedRecipes
from XndApp.Models.fridge import Fridge
from XndApp.Models.ingredients import Ingredient
import re

# 입력 검색 및 키워드 검색을 통한 레시피 (요리명, 이미지, 재료, 조리 순서 / 조리시간, 기준인원, 난이도) 조회

# 사전 정의 키워드
PREDEFINED_KEYWORDS = {
    '빠른요리': {'cooking_time': '15분 이내'},
    '특별한날': {'cooking_level': '고급', 'category2': '영양식'},
    '쉬운요리': {'cooking_level': '아무나'},
    '다이어트': {'food_name__icontains': '다이어트'},
}


class RecipeView(APIView):

    def get(self, request):

        query = request.query_params.get('query', '')  # 일반 검색 (제목, 태그, 재료)
        keyword = request.query_params.get('keyword', '')  # 키워드 (수집 카테고리, 조건 기반 카테고리, 트렌드)
        ingredients = request.query_params.getlist('ingredient', [])  # 재료 필드만 검색

        # 기본 쿼리셋
        recipes = Recipes.objects.all()

        # 검색어 (공백으로 구분된 여러 재료 검색 지원)
        if query:
            # 공백으로 구분하여 여러 검색어 처리
            query_terms = query.strip().split()

            if len(query_terms) == 1:
                # 단일 검색어: 기존 OR 방식
                recipes = recipes.filter(
                    Q(food_name__icontains=query_terms[0]) |
                    Q(tags__tag_name__icontains=query_terms[0]) |
                    Q(ingredient_all__icontains=query_terms[0])
                ).distinct()
            else:
                # 다중 검색어: 모든 검색어가 포함된 레시피 찾기 (AND 조건)
                # 각 검색어가 제목, 태그, 재료 중 하나에라도 포함되어야 함
                for term in query_terms:
                    recipes = recipes.filter(
                        Q(food_name__icontains=term) |
                        Q(tags__tag_name__icontains=term) |
                        Q(ingredient_all__icontains=term)
                    ).distinct()

        # 키워드
        if keyword:
            if keyword in PREDEFINED_KEYWORDS:
                filter_conditions = PREDEFINED_KEYWORDS[keyword]
                recipes = recipes.filter(**filter_conditions)
            else:
                # 카테고리의 내용을 키워드인 것처럼. ...
                recipes = recipes.filter(
                    Q(category1__icontains=keyword) |  # 볶음, 끓이기,
                    Q(category2__icontains=keyword) |  # 일상, 초스피드, 영양식,
                    Q(category3__icontains=keyword) |  # 소고기, 돼지고기, 닭고기, 해물류, 채소류, 달걀/유제품,
                    Q(category4__icontains=keyword)  # 밑반찬, 메인반찬, 국/탕, 찌개
                )

        # 재료 선택
        if ingredients:
            for ingredient in ingredients:
                recipes = recipes.filter(ingredient_all__icontains=ingredient)

        total_count = recipes.count()

        # 유통 기한 + 설문조사 결과를 반영한 레시피 정렬
        recipes = self.prioritize_recipes_with_survey(
            list(recipes),
            user=request.user
        )

        # 페이지네이션
        page = int(request.query_params.get('page', '1'))
        page_size = int(request.query_params.get('page_size', '10'))
        start = (page - 1) * page_size
        end = start + page_size

        paginated_recipes = recipes[start:end]

        # 시리얼라이징
        serializer = RecipeSerializer(paginated_recipes, many=True)

        # 유저
        user = request.user.user_id
        # isSaved 필드 검사 후 값 추가
        for data in serializer.data:
            if SavedRecipes.objects.filter(user=user, recipe_id=data['recipe_id']).exists():
                data['is_saved'] = True

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

        # 가중치 기준 정렬
        # 1. 임박 재료 포함 여부 (True 우선)
        # 2. 매칭되는 임박 재료의 총 가중치 (높을수록 우선)
        recipes_with_weights.sort(
            key=lambda x: (x['has_expiring'], x['total_weight']),
            reverse=True
        )

        # 정렬된 레시피 객체만 반환
        return [item['recipe'] for item in recipes_with_weights]

    def prioritize_recipes_with_survey(self, recipe_list, user):
        """
        유통기한(가중치 3) + 설문조사 결과(가중치 2)를 반영하여 레시피를 정렬합니다.

        Args:
            recipe_list: 레시피 객체 리스트
            user: User 객체

        Returns:
            정렬된 레시피 리스트
        """
        now = timezone.now()

        # 5일 이내 유통기한 임박 재료 가져오기
        expiring_ingredients = FridgeIngredients.objects.filter(
            fridge__user_id=user.user_id,
            storable_due__lte=now + timedelta(days=5)
        ).order_by('storable_due')

        # 임박 재료 이름 목록
        expiring_names = [ing.ingredient_name.lower() for ing in expiring_ingredients]

        # 설문조사 결과 파싱
        survey_ingredients = user.survey_ingredients.split(',') if user.survey_ingredients else []
        survey_dietary_restrictions = user.survey_dietary_restrictions.split(',') if user.survey_dietary_restrictions else []
        survey_cooking_equipment = user.survey_cooking_equipment.split(',') if user.survey_cooking_equipment else []
        survey_favorite_recipes = user.survey_favorite_recipe.split(',') if user.survey_favorite_recipe else []
        survey_serving_size = user.survey_serving_size  # 3번: 인분
        survey_skill_level = user.survey_skill_level  # 6번: 요리 실력

        # 각 레시피에 대해 가중치 계산
        recipes_with_weights = []

        for recipe in recipe_list:
            # 1. 유통기한 기반 가중치 (최대 가중치 3)
            expiry_weight = self._calculate_expiry_weight(recipe, expiring_names)

            # 2. 설문조사 기반 가중치
            survey_weight = self._calculate_survey_weight(
                recipe,
                survey_ingredients,
                survey_dietary_restrictions,
                survey_cooking_equipment,
                survey_favorite_recipes,
                survey_serving_size,
                survey_skill_level
            )

            # 총 가중치 = 유통기한 가중치(3) + 설문조사 가중치
            # 설문조사 가중치는 감점도 포함되어 있음 (피하는 음식 -0.5점)
            total_weight = expiry_weight + survey_weight

            # 피하는 음식이 포함된 경우 확인 (정렬 시 최하위 배치용)
            has_restricted_food = self._check_dietary_restrictions(recipe, survey_dietary_restrictions)

            recipes_with_weights.append({
                'recipe': recipe,
                'total_weight': total_weight,
                'has_restricted_food': has_restricted_food,
                'expiry_weight': expiry_weight,
                'survey_weight': survey_weight
            })

        # 정렬: 피하는 음식 포함 여부 -> 총 가중치
        recipes_with_weights.sort(
            key=lambda x: (not x['has_restricted_food'], x['total_weight']),
            reverse=True
        )

        return [item['recipe'] for item in recipes_with_weights]

    def _calculate_expiry_weight(self, recipe, expiring_names):
        """유통기한 임박 재료 기반 가중치 계산 (비율: 3)"""
        recipe_ingredients = recipe.ingredient_all.lower().split(',')
        recipe_ingredients = [ing.strip() for ing in recipe_ingredients]

        matching_count = 0
        positional_weight = 0

        for i, exp_name in enumerate(expiring_names):
            if any(exp_name in recipe_ing for recipe_ing in recipe_ingredients):
                matching_count += 1
                # 유통기한이 더 임박한 재료일수록 높은 가중치
                positional_weight += (len(expiring_names) - i)

        # 정규화하여 0~3 범위로 조정
        if expiring_names:
            normalized_weight = (positional_weight / (len(expiring_names) * (len(expiring_names) + 1) / 2)) * 3
        else:
            normalized_weight = 0

        return normalized_weight

    def _calculate_survey_weight(self, recipe, survey_ingredients, survey_dietary_restrictions,
                                 survey_cooking_equipment, survey_favorite_recipes,
                                 survey_serving_size, survey_skill_level):
        """
        설문조사 결과 기반 가중치 계산

        가중치 기준:
        - Q1 (식재료): 일치 식재료당 +0.3점
        - Q2 (좋아하는 요리): 일치 종류당 +0.3점
        - Q3 (인분): 일치 시 +0.3점
        - Q5 (피하는 음식): 식재료에 포함당 -0.5점 (별도 처리)
        - Q6 (요리 실력): 일치 시 +0.3점
        - Q7 (요리도구): 일치당 +0.3점
        """
        weight = 0.0

        # 레시피 재료 파싱
        recipe_ingredients = recipe.ingredient_all.lower().split(',')
        recipe_ingredients = [ing.strip() for ing in recipe_ingredients]

        # Q1: 주로 사용하는 식재료 매칭 (category3와 직접 비교, 일치당 +0.3점)
        if survey_ingredients and recipe.category3:
            recipe_category3 = recipe.category3.strip()
            for survey_ing in survey_ingredients:
                survey_ing_stripped = survey_ing.strip()
                # category3 값과 정확히 일치하는지 확인
                if survey_ing_stripped == recipe_category3:
                    weight += 0.3
                    break  # 하나만 일치해도 가중치 부여

        # Q2: 좋아하는 요리 종류 매칭 (텍스트 임베딩 사용, 일치당 +0.3점)
        # TODO: 텍스트 임베딩 적용 예정
        if survey_favorite_recipes:
            recipe_text = f"{recipe.food_name}".lower()
            for favorite in survey_favorite_recipes:
                favorite_lower = favorite.lower().strip()
                # 간단한 포함 체크 (임시)
                if favorite_lower in recipe_text or recipe_text in favorite_lower:
                    weight += 0.3
                    break

        # Q3: 인분 매칭 (serving_size와 직접 비교, 일치 시 +0.3점)
        if survey_serving_size and recipe.serving_size:
            # "1인분", "2인분" 등의 정확한 비교
            if survey_serving_size.strip() == recipe.serving_size.strip():
                weight += 0.3

        # Q5: 피하는 음식 (별도 함수에서 처리하여 감점)
        # _check_dietary_restrictions에서 -0.5점씩 차감
        restricted_penalty = self._calculate_dietary_restriction_penalty(recipe, survey_dietary_restrictions)
        weight += restricted_penalty

        # Q6: 요리 실력 매칭 (cooking_level과 직접 비교, 일치 시 +0.3점)
        # '아무나'인 레시피는 모든 난이도에 일치
        if survey_skill_level and recipe.cooking_level:
            recipe_level = recipe.cooking_level.strip()

            # '아무나'인 레시피는 모든 난이도에 대해 가중치 부여
            if recipe_level == '아무나':
                weight += 0.3
            # 설문 선택값과 레시피 난이도가 정확히 일치
            elif survey_skill_level.strip() == recipe_level:
                weight += 0.3

        # Q7: 요리도구 매칭 (steps에서 포함 여부 판단, 일치당 +0.3점)
        if recipe.steps:
            recipe_steps_lower = recipe.steps.lower()
            for equipment in survey_cooking_equipment:
                if equipment.lower() in recipe_steps_lower:
                    weight += 0.3
                    # 여러 도구가 매칭될 수 있으므로 break 없이 계속 체크

        return weight

    def _calculate_dietary_restriction_penalty(self, recipe, survey_dietary_restrictions):
        """
        피하는 음식이 레시피에 포함된 경우 페널티 계산 (포함당 -0.5점)
        1차: category3, ingredient_all에서 직접 검색
        2차: 텍스트 임베딩으로 유사도 확인 (TODO)
        """
        if not survey_dietary_restrictions or '없음' in survey_dietary_restrictions:
            return 0.0

        penalty = 0.0

        # 1차 필터링: category3와 ingredient_all에서 직접 검색
        recipe_category3 = recipe.category3.lower() if recipe.category3 else ''
        recipe_ingredients = recipe.ingredient_all.lower() if recipe.ingredient_all else ''

        # 피하는 음식 매핑 (category3 및 ingredient_all 키워드)
        restriction_keywords = {
            '매운 음식': ['고추', '청양', '매운', '고춧가루', '라조'],
            '생선': ['생선', '고등어', '갈치', '명태', '연어', '참치', '조기', '해물류'],
            '유제품': ['우유', '치즈', '요거트', '버터', '크림', '달걀/유제품'],
            '글루텐': ['밀가루', '빵', '파스타', '국수', '면'],
            '견과류': ['땅콩', '호두', '아몬드', '잣', '캐슈'],
            '채식주의': ['고기', '돼지', '소고기', '닭', '생선', '해산물', '돼지고기', '소고기', '닭고기', '해물류']
        }

        for restriction in survey_dietary_restrictions:
            keywords = restriction_keywords.get(restriction, [restriction])
            found = False

            # category3 체크
            for keyword in keywords:
                if keyword in recipe_category3:
                    penalty -= 0.5
                    found = True
                    break

            # ingredient_all 체크 (category3에서 찾지 못한 경우)
            if not found:
                for keyword in keywords:
                    if keyword in recipe_ingredients:
                        penalty -= 0.5
                        found = True
                        break

            # TODO: 2차 필터링 - 텍스트 임베딩으로 유사도 확인
            # if not found:
            #     embedding_similarity = calculate_embedding_similarity(restriction, recipe.food_name)
            #     if embedding_similarity > 0.7:  # 임계값
            #         penalty -= 0.5

        return penalty

    def _check_dietary_restrictions(self, recipe, survey_dietary_restrictions):
        """
        피하는 음식이 레시피에 포함되어 있는지 확인
        category3와 ingredient_all에서 검색
        """
        if not survey_dietary_restrictions or '없음' in survey_dietary_restrictions:
            return False

        recipe_category3 = recipe.category3.lower() if recipe.category3 else ''
        recipe_ingredients = recipe.ingredient_all.lower() if recipe.ingredient_all else ''

        # 피하는 음식 매핑
        restriction_keywords = {
            '매운 음식': ['고추', '청양', '매운', '고춧가루', '라조'],
            '생선': ['생선', '고등어', '갈치', '명태', '연어', '참치', '조기', '해물류'],
            '유제품': ['우유', '치즈', '요거트', '버터', '크림', '달걀/유제품'],
            '글루텐': ['밀가루', '빵', '파스타', '국수', '면'],
            '견과류': ['땅콩', '호두', '아몬드', '잣', '캐슈'],
            '채식주의': ['고기', '돼지', '소고기', '닭', '생선', '해산물', '돼지고기', '소고기', '닭고기', '해물류']
        }

        for restriction in survey_dietary_restrictions:
            keywords = restriction_keywords.get(restriction, [restriction])
            # category3 또는 ingredient_all에서 키워드 확인
            for keyword in keywords:
                if keyword in recipe_category3 or keyword in recipe_ingredients:
                    return True

        return False


# 레시피 상세 정보 조회
class RecipeDetailView(APIView):

    def get(self, request, recipe_id):
        recipe = get_object_or_404(Recipes, recipe_id=recipe_id)

        # 사용자 정보 (실제 환경에서는 request.user.id 사용)
        user = request.user.user_id

        # 사용자의 장바구니 재료 목록
        cartIngredients = Cart.objects.filter(user=user).values_list('ingredient__name', flat=True)

        # 사용자의 냉장고 속 재료 목록
        fridges = Fridge.objects.filter(user=user).values_list('fridge_id', flat=True)
        totalFridgeIngredients = []
        for fridge in fridges:
            fridgeIngredients = FridgeIngredients.objects.filter(fridge=fridge).values_list('ingredient_name',
                                                                                            flat=True)
            totalFridgeIngredients.extend(fridgeIngredients)

        # RecipeIngredient 테이블에서 재료 정보 가져오기
        recipe_ingredients = RecipeIngredient.objects.filter(recipe_id=recipe_id).select_related('ingredient')

        ingredients = []
        for ri in recipe_ingredients:
            include_cart_status = ri.ingredient.name in cartIngredients
            include_fridge_status = ri.ingredient.name in totalFridgeIngredients
            ingredients.append({
                "id": ri.ingredient.id,
                "name": ri.ingredient.name,
                "in_cart": include_cart_status,
                "in_fridge": include_fridge_status
            })

        # 시리얼라이저 적용
        serializer = RecipeDetailSerializer(recipe, context={'ingredients': ingredients})

        return Response(serializer.data, status=status.HTTP_200_OK)