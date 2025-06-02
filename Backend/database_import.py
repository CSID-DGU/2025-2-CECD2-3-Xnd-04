import csv
import os
import django
import ast
import re

# Django 설정 로드
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'Xnd.settings')
django.setup()

# 모델 가져오기
from XndApp.Models.recipes import Recipes
from XndApp.Models.tags import Tags
from XndApp.Models.ingredients import Ingredient
from XndApp.Models.RecipeIngredient import RecipeIngredient


def clean_ingredient_name(ingredient_text):
    """
    재료명에서 괄호와 수량 정보를 제거하고 깔끔한 재료명만 추출
    예: '한우 소고기 (살치살): 200g' -> '한우소고기'
    """
    # 괄호와 그 안의 내용 제거: (살치살), (흰부분) 등
    ingredient_text = re.sub(r'\([^)]*\)', '', ingredient_text)

    # 콜론과 그 뒤의 수량 정보 분리
    if ':' in ingredient_text:
        ingredient_name = ingredient_text.split(':')[0].strip()
    else:
        ingredient_name = ingredient_text.strip()

    # 공백 제거
    ingredient_name = ingredient_name.replace(' ', '')

    return ingredient_name


def extract_amount_from_ingredient(ingredient_text):
    """
    재료에서 수량 정보 추출
    예: '한우 소고기 (살치살): 200g' -> '200g'
    """
    if ':' in ingredient_text:
        return ingredient_text.split(':', 1)[1].strip()
    return '적당량'  # 수량 정보가 없는 경우 기본값


def import_complex_recipes():
    """
    레시피, 태그, 재료를 모두 한 번에 import하는 함수
    """
    # 기존 데이터 확인
    if Recipes.objects.exists():
        print(f"기존 레시피: {Recipes.objects.count()}개")
        print(f"기존 태그: {Tags.objects.count()}개")
        print(f"기존 재료: {Ingredient.objects.count()}개")
        print("기존 데이터를 삭제하시겠습니까? (y/n)")
        response = input().lower()
        if response == 'y':
            RecipeIngredient.objects.all().delete()
            Recipes.objects.all().delete()
            Tags.objects.all().delete()
            Ingredient.objects.all().delete()
            print("기존 데이터가 삭제되었습니다.")
        else:
            print("기존 데이터를 유지합니다. 새 데이터가 추가됩니다.")

    file_path = "RecipeDataset.csv"

    try:
        with open(file_path, 'r', encoding='utf-8-sig') as file:
            print("utf-8-sig 인코딩으로 파일 읽기 시도 중...")
            reader = csv.DictReader(file)

            # 필드 매핑 확인
            print("CSV 헤더:", reader.fieldnames)

            # 기존 데이터를 메모리에 캐시 (빠른 조회를 위해)
            existing_tags = {tag.tag_name: tag for tag in Tags.objects.all()}
            existing_ingredients = {ingredient.name: ingredient for ingredient in Ingredient.objects.all()}

            # 진행 통계
            recipes_created = 0
            tags_created = 0
            ingredients_created = 0
            recipe_ingredients_created = 0
            tag_relationships_created = 0

            for row in reader:
                # BOM 처리
                recipe_data = {}

                # recipe_id 처리
                if '\ufeffrecipe_id' in row:
                    recipe_data['recipe_id'] = row['\ufeffrecipe_id']
                elif 'recipe_id' in row:
                    recipe_data['recipe_id'] = row['recipe_id']

                # 나머지 필드 처리
                for field in ['recipe_image', 'category1', 'category2', 'category3',
                              'category4', 'food_name', 'steps', 'serving_size',
                              'cooking_time', 'cooking_level', 'ingredient_all']:
                    if field in row:
                        recipe_data[field] = row[field]

                try:
                    # 1. 레시피 생성 (중복 처리)
                    recipe, created = Recipes.objects.get_or_create(
                        recipe_id=recipe_data['recipe_id'],
                        defaults=recipe_data
                    )
                    if created:
                        recipes_created += 1

                    # 2. 태그 처리
                    tags_str = row.get('tags', '[]')
                    try:
                        tags_list = ast.literal_eval(tags_str)
                        for tag_name in tags_list:
                            if not tag_name:
                                continue

                            # 태그가 이미 존재하는지 확인
                            if tag_name in existing_tags:
                                tag = existing_tags[tag_name]
                            else:
                                # 새 태그 생성
                                tag = Tags.objects.create(tag_name=tag_name)
                                existing_tags[tag_name] = tag
                                tags_created += 1

                            # 레시피와 태그 연결 (Django가 자동으로 중복 처리)
                            recipe.tags.add(tag)
                            tag_relationships_created += 1

                    except (SyntaxError, ValueError) as e:
                        print(f"태그 파싱 오류 (recipe_id: {recipe_data.get('recipe_id')}): {e}")

                    # 3. 재료 처리
                    ingredient_all_str = row.get('ingredient_all', '[]')
                    try:
                        ingredients_list = ast.literal_eval(ingredient_all_str)
                        for ingredient_text in ingredients_list:
                            if not ingredient_text:
                                continue

                            # 재료명 정리 (괄호, 공백 제거)
                            clean_name = clean_ingredient_name(ingredient_text)
                            if not clean_name:
                                continue

                            # 수량 정보 추출
                            amount = extract_amount_from_ingredient(ingredient_text)

                            # 재료가 이미 존재하는지 확인 (중복 처리)
                            ingredient, created = Ingredient.objects.get_or_create(name=clean_name)
                            if created:
                                existing_ingredients[clean_name] = ingredient
                                ingredients_created += 1
                            else:
                                existing_ingredients[clean_name] = ingredient

                            # RecipeIngredient 관계 생성 (중복 처리)
                            recipe_ingredient, created = RecipeIngredient.objects.get_or_create(
                                recipe=recipe,
                                ingredient=ingredient,
                                defaults={'amount': amount}
                            )
                            if created:
                                recipe_ingredients_created += 1

                    except (SyntaxError, ValueError) as e:
                        print(f"재료 파싱 오류 (recipe_id: {recipe_data.get('recipe_id')}): {e}")
                        print(f"문제의 재료 문자열: {ingredient_all_str}")

                    # 진행 상황 보고
                    if recipes_created % 50 == 0:
                        print(f"{recipes_created}개 레시피 처리 완료...")

                except Exception as e:
                    print(f"레시피 생성 오류 (recipe_id: {recipe_data.get('recipe_id')}): {e}")
                    choice = input("계속 진행하시겠습니까? (y/n): ").lower()
                    if choice != 'y':
                        break

            print("\n==== 처리 완료 ====")
            print(f"생성된 레시피: {recipes_created}개")
            print(f"생성된 태그: {tags_created}개")
            print(f"생성된 재료: {ingredients_created}개")
            print(f"생성된 레시피-재료 관계: {recipe_ingredients_created}개")
            print(f"생성된 레시피-태그 관계: {tag_relationships_created}개")

            # 최종 데이터 확인
            print(f"\n총 레시피 수: {Recipes.objects.count()}")
            print(f"총 태그 수: {Tags.objects.count()}")
            print(f"총 재료 수: {Ingredient.objects.count()}")
            print(f"총 레시피-재료 관계 수: {RecipeIngredient.objects.count()}")

    except UnicodeDecodeError as e:
        print(f"인코딩 오류: {e}")
        try_other_encodings(file_path)
    except Exception as e:
        print(f"오류 발생: {e}")
        import traceback
        traceback.print_exc()


def try_other_encodings(file_path):
    """다른 인코딩으로 파일 읽기 시도"""
    encodings = ['cp949', 'euc-kr']

    for encoding in encodings:
        try:
            with open(file_path, 'r', encoding=encoding) as file:
                print(f"{encoding} 인코딩으로 파일 읽기 시도 중...")
                reader = csv.DictReader(file)
                first_row = next(reader, None)
                if first_row:
                    print(f"첫 번째 행 데이터: {first_row}")
                    print(f"{encoding} 인코딩으로 성공적으로 읽었습니다. 이 인코딩으로 다시 실행하세요.")
                    return True
        except UnicodeDecodeError:
            print(f"{encoding} 인코딩은 실패했습니다.")
        except Exception as e:
            print(f"{encoding} 인코딩 사용 중 오류 발생: {e}")

    print("모든 인코딩 시도가 실패했습니다.")
    return False


if __name__ == "__main__":


    print("\n레시피 import를 시작하시겠습니까? (y/n)")
    response = input().lower()
    if response == 'y':
        import_complex_recipes()
    else:
        print("import가 취소되었습니다.")