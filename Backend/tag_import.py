import csv
import os
import django
import ast  # 문자열을 리스트로 변환하기 위한 모듈

# Django 설정 로드
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'Xnd.settings')
django.setup()

# 모델 가져오기
from XndApp.Models.recipes import Recipes
from XndApp.Models.tags import Tags


def link_tags_to_recipes():
    # 기존 태그 정보 알림
    existing_tags_count = Tags.objects.count()
    print(f"현재 {existing_tags_count}개의 태그가 있습니다.")

    file_path = r"C:\Users\wjdgu\Documents\카카오톡 받은 파일\recipe_dataset__tags.csv"

    try:
        with open(file_path, 'r', encoding='utf-8-sig') as file:
            print("utf-8-sig 인코딩으로 파일 읽기 시도 중...")
            reader = csv.DictReader(file)

            # 필드 매핑 확인
            print("CSV 헤더:", reader.fieldnames)

            # 기존 태그 가져오기 (사전으로 변환하여 빠른 조회)
            existing_tags = {tag.tag_name: tag for tag in Tags.objects.all()}
            print(f"기존 태그 {len(existing_tags)}개를 메모리에 로드했습니다.")

            # 진행 통계
            recipes_updated = 0
            relationships_added = 0
            new_tags_created = 0

            for row in reader:
                recipe_id = None

                # BOM 문자가 있는 경우 처리
                if '\ufeffrecipe_id' in row:
                    recipe_id = row['\ufeffrecipe_id']
                elif 'recipe_id' in row:
                    recipe_id = row['recipe_id']

                if not recipe_id:
                    continue

                # 태그 목록 파싱
                tags_str = row.get('tags', '[]')
                try:
                    # 문자열을 리스트로 변환 (안전한 eval)
                    tags_list = ast.literal_eval(tags_str)

                    # 태그가 없으면 다음 레시피로
                    if not tags_list:
                        continue

                    # 레시피 가져오기
                    try:
                        recipe = Recipes.objects.get(recipe_id=recipe_id)

                        # 태그 연결
                        for tag_name in tags_list:
                            if not tag_name:  # 빈 태그 무시
                                continue

                            # 태그가 이미 존재하는지 확인
                            if tag_name in existing_tags:
                                tag = existing_tags[tag_name]
                            else:
                                # 새 태그 생성
                                tag = Tags.objects.create(tag_name=tag_name)
                                existing_tags[tag_name] = tag  # 캐시 업데이트
                                new_tags_created += 1

                            # 레시피와 태그 연결
                            recipe.tags.add(tag)
                            relationships_added += 1

                        recipes_updated += 1

                        # 진행 상황 보고
                        if recipes_updated % 100 == 0:
                            print(f"{recipes_updated}개의 레시피 업데이트 완료...")

                    except Recipes.DoesNotExist:
                        print(f"레시피를 찾을 수 없음 (recipe_id: {recipe_id})")
                    except Exception as e:
                        print(f"레시피-태그 연결 오류 (recipe_id: {recipe_id}): {e}")

                except (SyntaxError, ValueError) as e:
                    print(f"태그 파싱 오류 (recipe_id: {recipe_id}): {e}")
                    print(f"문제의 태그 문자열: {tags_str}")

            print("\n==== 처리 완료 ====")
            print(f"총 {recipes_updated}개의 레시피가 업데이트되었습니다.")
            print(f"새로 생성된 태그: {new_tags_created}개")
            print(f"추가된 레시피-태그 관계: {relationships_added}개")

    except UnicodeDecodeError as e:
        print(f"인코딩 오류: {e}")
        # 다른 인코딩 시도
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
                # 첫 번째 행 읽어보기
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
    link_tags_to_recipes()