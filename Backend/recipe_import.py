# xnd\backend 경로에서 실행 : python recipe_import.py
# 총 5개의 테이블에 데이터 입력
# recipes : 레시피 데이터
# ingredients : 레시피에 한번이라도 사용된 재료
# tags : 레시피에 한번이라도 언급된 태그
# recipeingredient : 레시피-식재료 관계 + 분량
# recipes_tags : 레시피-태그 관계

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

# CSV 파일 경로 설정
FILE_PATH = "recipe_dataset.csv"

def parse_list_string(data_str):
    if not data_str: return []
    cleaned_str = data_str.strip().replace('\n', '').replace('\r', '').replace('\t', '').replace('\xa0', ' ')
    if cleaned_str.startswith('[') and cleaned_str.endswith(']'):
        try:
            return ast.literal_eval(cleaned_str)
        except (SyntaxError, ValueError):
            pass
    try:
        inner_content = cleaned_str[1:-1] if cleaned_str.startswith('[') and cleaned_str.endswith(']') else cleaned_str
        parsed_list = [item.strip().strip("'\"") for item in inner_content.split(',') if item.strip()]
        return parsed_list
    except Exception as e:
        return []

def clean_ingredient_name(ingredient_text):
    ingredient_text = re.sub(r'\([^)]*\)', '', ingredient_text)
    ingredient_name = ingredient_text.split(':')[0].strip() if ':' in ingredient_text else ingredient_text.strip()
    return ingredient_name.replace(' ', '')

def import_complex_recipes():
    # 데이터 삭제 확인 및 초기화 (데이터 확장 시)
    if Recipes.objects.exists():
        print(f"기존 레시피: {Recipes.objects.count()}개")
        print("기존 데이터를 삭제하고 BULK IMPORT를 진행하시겠습니까? (y/n)")
        response = input().lower()
        if response == 'y':
            # 관계 테이블부터 삭제
            RecipeIngredient.objects.all().delete()
            try:
                Recipes.tags.through.objects.all().delete()
            except AttributeError:
                pass  # M2M 필드가 없어도 무시

            Recipes.objects.all().delete()
            Tags.objects.all().delete()
            Ingredient.objects.all().delete()
            print("✅ 기존 데이터가 삭제되었습니다. BULK IMPORT를 시작합니다.")
        else:
            print("❌ import가 취소되었습니다.")
            return
    else:
        print("✅ DB가 비어있습니다. BULK IMPORT를 시작합니다.")

    # 2. 데이터 수집 (In-Memory)
    temp_recipes = []
    unique_tags = {}
    unique_ingredients = {}
    raw_relations = []

    # Mapped Objects
    tag_name_to_id = {}
    ingredient_name_to_id = {}
    recipe_id_to_object = {}

    # Error Tracking
    error_tag_length_recipes = set()
    MAX_TAG_LENGTH = 255
    row_count = 0

    try:
        with open(FILE_PATH, 'r', encoding='utf-8-sig') as file:
            print(f"📖 {FILE_PATH} 파일 읽기 시도 중... 데이터 수집 단계")
            reader = csv.DictReader(file)

            for row in reader:
                row_count += 1
                recipe_id = row.get('\ufeffrecipe_id') or row.get('recipe_id')
                if not recipe_id: continue

                # Recipes 모델 데이터 수집
                recipe_data = {
                    'recipe_id': recipe_id,
                    'recipe_image': row.get('recipe_image', ''),
                    'category1': row.get('category1', ''),
                    'category2': row.get('category2', ''),
                    'category3': row.get('category3', ''),
                    'category4': row.get('category4', ''),
                    'food_name': row.get('food_name', ''),
                    'steps': row.get('steps', ''),
                    'serving_size': row.get('serving_size', ''),
                    'cooking_time': row.get('cooking_time', ''),
                    'cooking_level': row.get('cooking_level', ''),
                    'ingredient_all': row.get('ingredient_detail', '')
                }
                temp_recipes.append(recipe_data)

                # 태그 수집 및 오류 체크
                try:
                    tags_list = parse_list_string(row.get('tags', '[]'))
                    for tag_name in tags_list:
                        if not tag_name: continue

                        if len(tag_name) > MAX_TAG_LENGTH:
                            error_tag_length_recipes.add(recipe_id)
                            safe_tag_name = tag_name[:MAX_TAG_LENGTH]
                        else:
                            safe_tag_name = tag_name

                        unique_tags[safe_tag_name] = Tags(tag_name=safe_tag_name)
                        raw_relations.append({'type': 'tag', 'recipe_id': recipe_id, 'tag_name': safe_tag_name})
                except:
                    pass

                # 재료 수집 및 관계 정보 임시 저장
                try:
                    ingredients_name_list = parse_list_string(row.get('ingredient_name', '[]'))
                    ingredients_detail_list = parse_list_string(row.get('ingredient_detail', '[]'))

                    for name, detail in zip(ingredients_name_list, ingredients_detail_list):
                        if not name: continue
                        clean_name = clean_ingredient_name(name)
                        if not clean_name: continue
                        amount = detail.strip() if detail else '적당량'

                        unique_ingredients[clean_name] = Ingredient(name=clean_name)

                        raw_relations.append({
                            'type': 'ingredient',
                            'recipe_id': recipe_id,
                            'clean_name': clean_name,
                            'amount': amount
                        })
                except:
                    pass

            print(f"\n✅ 총 {row_count}개 레코드 인메모리 수집 완료.")
            if error_tag_length_recipes:
                print(f"⚠️ 경고: 태그 길이가 {MAX_TAG_LENGTH}자를 초과하여 태그가 잘린 레시피 ID ({len(error_tag_length_recipes)}개):")
                print(list(error_tag_length_recipes)[:5])

    except Exception as e:
        print(f"🚨파일 읽기 오류: {e}")
        return

    # 3. BULK INSERTION 실행 (Phase 1, 2)

    print("\n[Phase 1/3] 태그 및 재료 (Unique Entity) BULK 생성 시작...")
    try:
        Tags.objects.bulk_create(list(unique_tags.values()), ignore_conflicts=True)
        for tag in Tags.objects.filter(tag_name__in=unique_tags.keys()): tag_name_to_id[tag.tag_name] = tag
        Ingredient.objects.bulk_create(list(unique_ingredients.values()), ignore_conflicts=True)
        for ingredient in Ingredient.objects.filter(name__in=unique_ingredients.keys()): ingredient_name_to_id[
            ingredient.name] = ingredient
        print(f"   -> 태그 {len(tag_name_to_id)}개, 재료 {len(ingredient_name_to_id)}개 맵핑 완료.")
    except Exception as e:
        print(f"🚨 Phase 1 오류 (Tags/Ingredient Bulk): {e}"); return

    print("\n[Phase 2/3] 레시피 (Recipes) BULK 생성 시작...")
    try:
        recipe_objects = [Recipes(**data) for data in temp_recipes]
        Recipes.objects.bulk_create(recipe_objects, ignore_conflicts=True)

        csv_recipe_ids = [data['recipe_id'] for data in temp_recipes]

        # DB에서 읽어온 recipe_id (정수)를 문자열로 변환하여 딕셔너리 키로 저장
        for recipe in Recipes.objects.filter(recipe_id__in=csv_recipe_ids):
            recipe_id_to_object[str(recipe.recipe_id)] = recipe

        print(f"   -> 레시피 {len(recipe_id_to_object)}개 맵핑 완료.")

    except Exception as e:
        print(f"🚨 Phase 2 오류 (Recipes Bulk): {e}"); return

    # 4. BULK INSERTION 실행 (Phase 3: Batch + Unique Check)

    print("\n[Phase 3/3] 관계 (RecipeIngredient, M2M Tags) BULK 생성 시작...")

    try:
        recipe_tags_through = []
        recipe_ingredients_to_create = []

        # M2M/관계 중복 체크를 위한 Set (고유값만 남김)
        unique_recipe_tags = set()
        unique_recipe_ingredients = set()

        MAX_AMOUNT_LENGTH = 50

        for relation in raw_relations:
            recipe_obj = recipe_id_to_object.get(relation['recipe_id'])
            if not recipe_obj: continue

            # --- 태그 관계 처리 ---
            if relation['type'] == 'tag':
                tag_obj = tag_name_to_id.get(relation['tag_name'])
                if tag_obj:
                    key = (recipe_obj.recipe_id, tag_obj.tag_id)
                    if key not in unique_recipe_tags:
                        unique_recipe_tags.add(key)
                        recipe_tags_through.append(
                            Recipes.tags.through(recipes_id=recipe_obj.recipe_id, tags_id=tag_obj.tag_id)
                        )

            # --- 재료 관계 처리  ---
            elif relation['type'] == 'ingredient':
                ingredient_obj = ingredient_name_to_id.get(relation['clean_name'])
                if ingredient_obj:
                    # Recipes PK: recipe_id (OK) / Ingredient PK: id (수정)
                    key = (recipe_obj.recipe_id, ingredient_obj.id)
                    if key not in unique_recipe_ingredients:
                        unique_recipe_ingredients.add(key)

                        # 필드 길이 보정
                        safe_amount = relation['amount'][:MAX_AMOUNT_LENGTH]

                        recipe_ingredients_to_create.append(
                            RecipeIngredient(
                                recipe_id=recipe_obj.recipe_id,
                                ingredient_id=ingredient_obj.id,
                                amount=safe_amount
                            )
                        )

        # 3-4. RecipeIngredient BULK 생성 (BATCH_SIZE 적용)
        BATCH_SIZE = 1000
        total_ri_created = 0

        for i in range(0, len(recipe_ingredients_to_create), BATCH_SIZE):
            batch = recipe_ingredients_to_create[i:i + BATCH_SIZE]
            created_count = len(RecipeIngredient.objects.bulk_create(batch, ignore_conflicts=True))
            total_ri_created += created_count

        # 3-5. 레시피-태그 관계 BULK 생성 (BATCH_SIZE 적용)
        total_tag_rel_created = 0

        try:
            for i in range(0, len(recipe_tags_through), BATCH_SIZE):
                batch = recipe_tags_through[i:i + BATCH_SIZE]
                created_count = len(Recipes.tags.through.objects.bulk_create(batch, ignore_conflicts=True))
                total_tag_rel_created += created_count
        except AttributeError:
            print(
                "❌ WARNING: Recipes.tags.through 객체 오류. Recipes 모델에 tags = models.ManyToManyField('Tags') 필드가 있는지 확인해 주세요.")

        print(f"   -> RecipeIngredient 관계 {total_ri_created}개 생성 완료. (총 {len(recipe_ingredients_to_create)}개 시도)")
        print(f"   -> 레시피-태그 관계 {total_tag_rel_created}개 생성 완료. (총 {len(recipe_tags_through)}개 시도)")

    except Exception as e:
        print(f"🚨 Phase 3 치명적 오류: {e}")
        return

    # ----------------------------------------
    # 5. 최종 결과 요약
    # ----------------------------------------
    print("\n==== 최종 BULK IMPORT 완료 ====")
    print(f"총 레코드 수집: {row_count}개")
    print(f"DB 총 레시피 수: {Recipes.objects.count()}개")
    print(f"DB 총 태그 수: {Tags.objects.count()}개")
    print(f"DB 총 재료 수: {Ingredient.objects.count()}개")
    print(f"DB 총 레시피-재료 관계 수: {RecipeIngredient.objects.count()}개")
    print(f"DB 총 레시피-태그 관계 수: {Recipes.tags.through.objects.count()}개")

if __name__ == "__main__":
    import_complex_recipes()
