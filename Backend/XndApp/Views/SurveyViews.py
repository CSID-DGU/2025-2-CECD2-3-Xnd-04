from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from XndApp.Models.user import User


@api_view(['POST', 'GET'])
@permission_classes([IsAuthenticated])
def survey_submit(request):
    """
    사전 설문조사 결과 저장 및 조회
    POST: 설문조사 결과 저장
    GET: 현재 사용자의 설문조사 결과 조회
    """
    user = request.user

    if request.method == 'GET':
        # 설문조사 결과 조회
        return Response({
            'survey_completed': user.survey_completed,
            'ingredients': user.survey_ingredients.split(',') if user.survey_ingredients else [],
            'favorite_recipe': user.survey_favorite_recipe.split(',') if user.survey_favorite_recipe else [],
            'serving_size': user.survey_serving_size,
            'cooking_frequency': user.survey_cooking_frequency,
            'dietary_restrictions': user.survey_dietary_restrictions.split(',') if user.survey_dietary_restrictions else [],
            'skill_level': user.survey_skill_level,
            'cooking_equipment': user.survey_cooking_equipment.split(',') if user.survey_cooking_equipment else [],
        }, status=status.HTTP_200_OK)

    elif request.method == 'POST':
        # 설문조사 결과 저장
        data = request.data

        # 다중 선택 항목은 리스트로 받아서 쉼표로 연결
        ingredients = data.get('ingredients', [])
        favorite_recipe = data.get('favorite_recipe', [])
        dietary_restrictions = data.get('dietary_restrictions', [])
        cooking_equipment = data.get('cooking_equipment', [])

        # 리스트를 쉼표로 구분된 문자열로 변환
        user.survey_ingredients = ','.join(ingredients) if isinstance(ingredients, list) else ingredients
        user.survey_favorite_recipe = ','.join(favorite_recipe) if isinstance(favorite_recipe, list) else favorite_recipe
        user.survey_dietary_restrictions = ','.join(dietary_restrictions) if isinstance(dietary_restrictions, list) else dietary_restrictions
        user.survey_cooking_equipment = ','.join(cooking_equipment) if isinstance(cooking_equipment, list) else cooking_equipment

        # 단일 선택 항목
        user.survey_serving_size = data.get('serving_size', '')
        user.survey_cooking_frequency = data.get('cooking_frequency', '')
        user.survey_skill_level = data.get('skill_level', '')

        # 설문조사 완료 표시
        user.survey_completed = True
        user.save()

        return Response({
            'message': '설문조사가 저장되었습니다.',
            'survey_completed': True,
        }, status=status.HTTP_200_OK)
