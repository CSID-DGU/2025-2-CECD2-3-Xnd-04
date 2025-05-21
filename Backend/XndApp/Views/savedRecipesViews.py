import requests
from rest_framework.response import Response
from rest_framework import status
from rest_framework.views import APIView
from ..serializers.savedRecipes_serializer import SavedRecipeSerializer
from ..serializers.savedRecipes_serializer import SavedRecipeDetailSerializer
from ..Models.savedRecipes import SavedRecipes
from ..Models.recipes import Recipes


class SavedRecipesView(APIView):

    # 즐겨찾기 추가
    def post(self,request):
        
        # 클릭한 레시피
        recipe = request.data.get('recipe_id')

        if not Recipes.objects.filter(recipe=recipe).exists():
            return Response({'error': '존재하지 않는 레시피입니다.'}, status=status.HTTP_404_NOT_FOUND)
        
        user = request.user
        
        try:
            # 중복 저장 방지
            if SavedRecipes.objects.filter(user=user, recipe=recipe).exists():
                savedRecipe = SavedRecipes.objects.get(user=user, recipe=recipe)
                savedRecipe.delete()
                return Response({"message": "레시피가 삭제되었습니다."}, status=status.HTTP_200_OK)
            
            SavedRecipes.objects.create(user=user, recipe=recipe)
            return Response({"message": "레시피가 저장되었습니다."}, status=status.HTTP_201_CREATED)
        
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
    # 즐겨찾기 레시피 리스트 로드
    def get(self,request):
        try:
            user = request.user
            savedRecipes = SavedRecipes.objects.filter(user = user)
            serializer = SavedRecipeSerializer(savedRecipes,many = True)
            
            if not savedRecipes.exists():
                    return Response(
                        {"message": "저장된 레시피가 없습니다."},
                        status=status.HTTP_404_NOT_FOUND
                    )
            return Response(serializer.data,status=status.HTTP_200_OK)
        
        except Exception as e:
            return Response(
                {
                    "error": "레시피 목록을 불러오는 중 오류가 발생했습니다.",
                    "detail": str(e)
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class SavedRecipeDetailView(APIView):
    # 특정 레시피 내용 열람
    def get(self,request,id):

        try:
            savedRecipe = SavedRecipes.objects.filter(id=id,user=request.user).first()
            if savedRecipe:
                serializer = SavedRecipeDetailSerializer(savedRecipe)
                return Response(serializer.data,status=status.HTTP_200_OK)
        
        except SavedRecipes.DoesNotExist:
            return Response(
                {'error':'No Recipe'},
                status=status.HTTP_204_NO_CONTENT
            )
        
        except Exception as e:
            return Response(
                {'error':'레시피를 불러오는 도중 오류가 발생하였습니다.'},
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
