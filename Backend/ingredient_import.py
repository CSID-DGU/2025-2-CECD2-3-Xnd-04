# ingredient_import.py

import os
import sys
import django
import ast

# Django 설정 로드
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'Xnd.settings')
django.setup()

# 모델 임포트
from XndApp.Models.recipes import Recipes
from XndApp.Models.ingredients import Ingredient
from XndApp.Models.RecipeIngredient import RecipeIngredient


def main():
    # 카운터 초기화
    ingredients_created = 0
    recipe_ingredients_created = 0

    # 모든 레시피 조회
    recipes = Recipes.objects.all()
    print(f'레시피 {recipes.count()}개를 찾았습니다.')

    for recipe in recipes:
        if not recipe.ingredient_all:
            continue

        # 리스트 형태의 문자열을 파이썬 리스트로 변환
        try:
            ingredients_list = ast.literal_eval(recipe.ingredient_all)
        except (ValueError, SyntaxError):
            print(f'레시피 ID {recipe.id}: 재료 파싱 실패 - {recipe.ingredient_all}')
            continue

        # 각 재료 처리
        for ingredient_info in ingredients_list:
            # 재료 이름과 양 분리 (항상 콜론이 있다고 가정)
            ingredient_info = ingredient_info.replace(' ', '')
            parts = ingredient_info.split(':', 1)
            name_part = parts[0]
            amount_part = parts[1] if len(parts) > 1 else ""
            # name_part = parts[0].strip()
            # amount_part = parts[1].strip() if len(parts) > 1 else ""

            # Ingredient 생성 또는 조회
            ingredient, created = Ingredient.objects.get_or_create(name=name_part)
            if created:
                ingredients_created += 1
                print(f'새 재료 생성: {name_part}')

            # RecipeIngredient 생성
            recipe_ingredient, created = RecipeIngredient.objects.get_or_create(
                recipe=recipe,
                ingredient=ingredient,
                defaults={'amount': amount_part}
            )
            if created:
                recipe_ingredients_created += 1

    print(f'마이그레이션 완료!')
    print(f'- {ingredients_created}개의 새로운 Ingredient 생성됨')
    print(f'- {recipe_ingredients_created}개의 새로운 RecipeIngredient 생성됨')


if __name__ == "__main__":
    main()