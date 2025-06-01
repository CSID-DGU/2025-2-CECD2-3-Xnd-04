import requests
from rest_framework.response import Response
from rest_framework import status
from rest_framework.views import APIView
from ..serializers.savedRecipes_serializer import SavedRecipeSerializer
from ..serializers.savedRecipes_serializer import SavedRecipeDetailSerializer
from XndApp.serializers.recipe_serializer import RecipeSerializer
from ..Models.savedRecipes import SavedRecipes
from ..Models.recipes import Recipes
from XndApp.Models.ingredients import Ingredient
from XndApp.Models.cart import Cart
from XndApp.Models.fridgeIngredients import FridgeIngredients
from XndApp.Models.user import User
from XndApp.Models.fridge import Fridge
from django.shortcuts import get_object_or_404
from django.utils import timezone
from datetime import timedelta
import re

class SavedRecipesView(APIView):

    # 즐겨찾기 레시피 리스트 로드
    def get(self,request):
        try:
            user = request.user
            savedRecipes = SavedRecipes.objects.filter(user = user).select_related('recipe')
            recipes = [saved.recipe for saved in savedRecipes]
            
            #임박순으로 정렬
            recipes = self.prioritize_by_expiring_ingredients(
                list(recipes),
                user_id = user.user_id
            )
            
            if not savedRecipes.exists():
                    return Response(
                        {"message": "저장된 레시피가 없습니다."},
                        status=status.HTTP_404_NOT_FOUND
                    )
            
            # 페이지네이션
            page = int(request.query_params.get('page', '1'))
            page_size = int(request.query_params.get('page_size', '10'))
            start = (page - 1) * page_size
            end = start + page_size

            paginated_recipes = recipes[start:end]

            serializer = RecipeSerializer(paginated_recipes,many = True)
            return Response(serializer.data,status=status.HTTP_200_OK)
        
        except Exception as e:
            return Response(
                {
                    "error": "레시피 목록을 불러오는 중 오류가 발생했습니다.",
                    "detail": str(e)
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
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
    
    # 즐겨찾기 추가 또는 삭제(토글)
    def post(self,request):
        
        # 클릭한 레시피
        recipe = request.data.get('recipe_id')
        if not Recipes.objects.filter(recipe_id=recipe).exists():
            return Response({'error': '존재하지 않는 레시피입니다.'}, status=status.HTTP_404_NOT_FOUND)
        # 유저
        user = request.user.user_id

        user_obj = User.objects.get(pk=request.user.user_id)
        recipe_obj = Recipes.objects.get(pk=recipe)
        try:
            # 중복 저장 방지
            if SavedRecipes.objects.filter(user=user, recipe_id=recipe).exists():
                savedRecipe = SavedRecipes.objects.get(user=user, recipe=recipe)
                savedRecipe.delete()
                return Response({"message": "레시피가 삭제되었습니다."}, status=status.HTTP_200_OK)
            
            SavedRecipes.objects.create(user=user_obj, recipe=recipe_obj)
            return Response({"message": "레시피가 저장되었습니다."}, status=status.HTTP_201_CREATED)
        
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        

class SavedRecipeDetailView(APIView):
    # 특정 레시피 내용 열람
    def get(self,request,id):

        try:
            user_id = request.user.user_id
            recipe_id = SavedRecipes.objects.get(id=id).recipe_id
            #해당 레시피 재료
            recipeIngredient = Recipes.objects.filter(recipe_id=recipe_id).first().ingredient_all
            # 대괄호 및 작은따옴표 제거 후 쉼표로 분리
            cleaned = re.sub(r"[\[\]']", "", recipeIngredient)
            recipeIngredients = [item.strip() for item in cleaned.split(',')]

            #사용자의 장바구니 재료 목록
            cartIngredients = Cart.objects.filter(user=user_id).values_list('ingredient__name',flat=True)
            
            #사용자의 냉장고 속 재료 목록
            fridges = Fridge.objects.filter(user=user_id).values_list('fridge_id',flat=True)
            totalFridgeIngredients = []
            for fridge in fridges:
                fridgeIngredients = FridgeIngredients.objects.filter(fridge=fridge).values_list('ingredient_name',flat=True)
                totalFridgeIngredients.extend(fridgeIngredients)

            #재료 명 + 장바구니 포함 여부
            ingredients = []

            for recipeIngredient in recipeIngredients:
                # 각 재료의 id 확인
                recipeIngredient_id = Ingredient.objects.filter(name=recipeIngredient).first()
                # id가 없는 경우
                if not recipeIngredient_id:
                    recipeIngredient_id = 'Unknown Id'
                # id가 존재하는 경우
                else:
                    recipeIngredient_id = recipeIngredient_id.id
                # 장바구니 / 냉장고 존재 유무
                include_cart_status = recipeIngredient in cartIngredients
                include_fridge_status = recipeIngredient in totalFridgeIngredients
                ingredients.append({
                    "id" : recipeIngredient_id,
                    "name": recipeIngredient,
                    "in_cart": include_cart_status,
                    "in_fridge" : include_fridge_status
                })
            savedRecipe = SavedRecipes.objects.filter(id=id).first()

            if savedRecipe:
                serializer = SavedRecipeDetailSerializer(savedRecipe,context={'ingredients': ingredients})
                return Response(serializer.data,status=status.HTTP_200_OK)
        
        except SavedRecipes.DoesNotExist:
            return Response(
                {'error':'No Recipe',},
                status=status.HTTP_204_NO_CONTENT
            )
        
        except Exception as e:
            return Response(
                {'error':'레시피를 불러오는 도중 오류가 발생하였습니다.','message':str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def delete(self,request,id):
    # 특정 레시피 즐겨찾기 삭제(상세 페이지 내에서)

        try:
            savedRecipe = SavedRecipes.objects.get(id=id,user=request.user)
            savedRecipe.delete()

            return Response(
                {'message' : '즐겨찾기 삭제'},
                status=status.HTTP_204_NO_CONTENT
            )
        
        except SavedRecipes.DoesNotExist:
            return Response(
                {'error':'No Recipe'},
                status=status.HTTP_204_NO_CONTENT
            )
        
        except Exception as e:
            return Response(
                {"error": "오류 발생", "detail": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
