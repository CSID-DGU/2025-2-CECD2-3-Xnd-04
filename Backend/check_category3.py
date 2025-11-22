"""
recipes 테이블의 category3 컬럼에 있는 고유값들을 확인하는 스크립트
"""
import os
import django
import sys

# Django 설정
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'Xnd.settings')
django.setup()

from XndApp.Models.recipes import Recipes

# category3의 고유값들 가져오기
category3_values = Recipes.objects.values_list('category3', flat=True).distinct().order_by('category3')

print("=== recipes.category3 컬럼의 고유값 목록 ===")
print(f"총 {len(category3_values)}개의 고유값\n")

for idx, value in enumerate(category3_values, 1):
    # 각 category3 값에 해당하는 레시피 수
    count = Recipes.objects.filter(category3=value).count()
    print(f"{idx:2d}. {value:20s} ({count}개 레시피)")
