"""
기존 레시피들의 임베딩 벡터를 일괄 생성하는 스크립트
배치 처리로 빠르게 처리
"""
import os
import django
import sys

# Django 설정
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'Xnd.settings')
django.setup()

from XndApp.Models.recipes import Recipes
from sentence_transformers import SentenceTransformer
import numpy as np
from tqdm import tqdm

# 모델 로드
print("임베딩 모델 로딩 중...")
model = SentenceTransformer('jhgan/ko-sroberta-multitask')
print("모델 로딩 완료!")

# 모든 레시피 가져오기
recipes = Recipes.objects.all()
total_recipes = recipes.count()
print(f"총 {total_recipes}개의 레시피 임베딩 생성 시작...")

# 배치 사이즈 설정 (메모리에 맞게 조정)
BATCH_SIZE = 100

# 배치 단위로 처리
for i in tqdm(range(0, total_recipes, BATCH_SIZE), desc="Processing batches"):
    batch_recipes = recipes[i:i+BATCH_SIZE]

    # 배치의 모든 텍스트 준비
    ingredient_texts = []
    name_texts = []
    recipe_ids = []

    for recipe in batch_recipes:
        # 재료 텍스트
        ingredient_text = recipe.ingredient_all if recipe.ingredient_all else ""
        ingredient_texts.append(ingredient_text)

        # 레시피명 텍스트
        name_text = recipe.food_name if recipe.food_name else ""
        name_texts.append(name_text)

        recipe_ids.append(recipe.recipe_id)

    # 배치 임베딩 생성 (한번에 처리 - 훨씬 빠름!)
    try:
        ingredient_embeddings = model.encode(ingredient_texts, show_progress_bar=False)
        name_embeddings = model.encode(name_texts, show_progress_bar=False)

        # DB에 저장
        for j, recipe in enumerate(batch_recipes):
            recipe.ingredients_embedding = ingredient_embeddings[j].tolist()
            recipe.name_embedding = name_embeddings[j].tolist()

        # 배치 업데이트
        Recipes.objects.bulk_update(
            batch_recipes,
            ['ingredients_embedding', 'name_embedding'],
            batch_size=BATCH_SIZE
        )

    except Exception as e:
        print(f"\n배치 {i}-{i+BATCH_SIZE} 처리 중 에러: {e}")
        # 에러 발생시 개별 처리로 전환
        for recipe in batch_recipes:
            try:
                ingredient_text = recipe.ingredient_all if recipe.ingredient_all else ""
                name_text = recipe.food_name if recipe.food_name else ""

                recipe.ingredients_embedding = model.encode(ingredient_text).tolist()
                recipe.name_embedding = model.encode(name_text).tolist()
                recipe.save()
            except Exception as e2:
                print(f"레시피 {recipe.recipe_id} 처리 실패: {e2}")

print("\n임베딩 생성 완료!")

# 통계 출력
embedded_count = Recipes.objects.filter(
    ingredients_embedding__isnull=False,
    name_embedding__isnull=False
).count()
print(f"임베딩이 생성된 레시피: {embedded_count}/{total_recipes}")
