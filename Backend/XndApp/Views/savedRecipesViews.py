import requests
from rest_framework.response import Response
from rest_framework import status
from rest_framework.views import APIView
from ..serializers.savedRecipes_serializer import SavedRecipeSerializer
from ..serializers.savedRecipes_serializer import SavedRecipeDetailSerializer
from ..Models.savedRecipes import SavedRecipes


class SavedRecipesView(APIView):

    # 즐겨찾기 추가
    def post(self,request):
        
        recipe = request.data.get('recipe_id')
        user = request.user
        
        try:
            # 중복 저장 방지
            if SavedRecipes.objects.filter(user=user, recipe=recipe).exists():
                return Response({"message": "이미 저장된 레시피입니다."}, status=status.HTTP_400_BAD_REQUEST)
            
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
                        status=status.HTTP_204_NO_CONTENT
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
            savedRecipe = SavedRecipes.objects.filter(id=id)
            if not savedRecipe.exists():
                return Response(
                    {'error':'No Recipe'},
                    status=status.HTTP_204_NO_CONTENT
                )
            
            serializer = SavedRecipeDetailSerializer(savedRecipe)
            return Response(status=status.HTTP_200_OK)
        

        except Exception as e:
            return Response(
                {'error':'레시피를 불러오는 도중 오류가 발생하였습니다.'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

