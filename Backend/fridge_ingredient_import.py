# fridge_ingredient_import.py

import os
import time

import django
import random
import datetime

# Django 설정 로드
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'Xnd.settings')
django.setup()

# 모델 임포트
from XndApp.Models.fridgeIngredients import FridgeIngredients
from XndApp.Models.ingredients import Ingredient
from XndApp.Models.fridge import Fridge
from XndApp.Models.foodStorageLife import FoodStorageLife


def main():
    if FridgeIngredients.objects.exists():
        print("이미 냉장고 내부 식재료 데이터가 존재합니다. 기존 데이터를 삭제하시겠습니까? (y/n)")
        response = input().lower()
        if response == 'y':
            FridgeIngredients.objects.all().delete()
            print("기존 데이터가 삭제되었습니다.")
        else:
            print("기존 데이터를 유지합니다. 새 데이터가 추가됩니다.")

    if FoodStorageLife.objects.exists():
        print("이미 유통기한 데이터가 존재합니다. 기존 데이터를 삭제하시겠습니까? (y/n)")
        response = input().lower()
        if response == 'y':
            FoodStorageLife.objects.all().delete()
            print("기존 데이터가 삭제되었습니다.")
        else:
            print("기존 데이터를 유지합니다. 새 데이터가 추가됩니다.")

    # 카운터 초기화
    nowFridge = 1
    foodStorage_count = 0

    # 모든 레시피 조회
    ingredients = Ingredient.objects.all()
    print(f'식재료 {ingredients.count()}개를 찾았습니다.')
    fridges = Fridge.objects.all()
    print(f'냉장고 {fridges.count()}개를 찾았습니다.')
    foodStorageLifes = FoodStorageLife.objects.all()
    print(f'유통기한 {foodStorageLifes.count()}개를 찾았습니다.')

    intList = random.sample(range(1, ingredients.count()), fridges.count() * 16)

    step = 0
    # 냉장고 수에 맞춰서 fridgescount 조정
    while nowFridge < fridges.count() + 1:
        fridge = Fridge.objects.get(fridge_id=nowFridge)
        ingredients_parsed = 0
        while ingredients_parsed < 16:
            ingredient = Ingredient.objects.get(id=intList[step])
            now = datetime.datetime.now()
            stored_at = now.strftime('%Y-%m-%d %H:%M')
            stored_at = datetime.datetime.strptime(stored_at, '%Y-%m-%d %H:%M')
            storable_due = random.randint(30, 60)

            # FoodStorageLife 생성
            foodstoragelife = FoodStorageLife.objects.create(
                name=ingredient.name,
                storage_life=storable_due,
            )

            # FridgeIngredient 생성
            FridgeIngredients.objects.create(
                fridge=fridge,
                foodStorageLife=foodstoragelife,
                stored_at=stored_at,
                layer=1,
                storable_due=storable_due,
                ingredient_name=ingredient.name,
            )
            ingredients_parsed += 1
            step += 1

            time.sleep(1)      # 1초 간격으로 데이터 생성
            print(f'step {step}회 완료')
        nowFridge += 1

    print(f'마이그레이션 완료!')

if __name__ == "__main__":
    main()