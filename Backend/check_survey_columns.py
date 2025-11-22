"""
설문조사 항목에 사용할 컬럼들의 고유값 확인
"""
import os
import django
import sys

# Django 설정
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'Xnd.settings')
django.setup()

from XndApp.Models.recipes import Recipes

print("=" * 60)
print("설문조사 Q3: recipes.serving_size 컬럼의 고유값")
print("=" * 60)
serving_size_values = Recipes.objects.values_list('serving_size', flat=True).distinct().order_by('serving_size')
print(f"총 {len(serving_size_values)}개의 고유값\n")
for idx, value in enumerate(serving_size_values, 1):
    count = Recipes.objects.filter(serving_size=value).count()
    print(f"{idx:2d}. '{value}' ({count}개 레시피)")

print("\n" + "=" * 60)
print("설문조사 Q6: recipes.cooking_level 컬럼의 고유값")
print("=" * 60)
cooking_level_values = Recipes.objects.values_list('cooking_level', flat=True).distinct().order_by('cooking_level')
print(f"총 {len(cooking_level_values)}개의 고유값\n")
for idx, value in enumerate(cooking_level_values, 1):
    count = Recipes.objects.filter(cooking_level=value).count()
    print(f"{idx:2d}. '{value}' ({count}개 레시피)")
