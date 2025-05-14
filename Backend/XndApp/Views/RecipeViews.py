from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.db.models import Q
from ..Models.recipes import Recipes
from XndApp.serializers.recipe_serializer import RecipeSerializer

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

        query = request.query_params.get('query', '')           # 검색
        keyword = request.query_params.get('keyword', '')       # 키워드

        # 기본 쿼리셋
        recipes = Recipes.objects.all()

        # 검색어
        if query:
            recipes = recipes.filter(
                Q(food_name__icontains=query) |
                Q(tags__tag_name__icontains=query)
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

        # 페이지네이션
        page = int(request.query_params.get('page', '1'))
        page_size = int(request.query_params.get('page_size', '10'))
        start = (page - 1) * page_size
        end = start + page_size

        paginated_recipes = recipes[start:end]

        # 시리얼라이징
        serializer = RecipeSerializer(paginated_recipes, many=True)

        return Response({
            'count': recipes.count(),
            'page': page,
            'page_size': page_size,
            'results': serializer.data
        })