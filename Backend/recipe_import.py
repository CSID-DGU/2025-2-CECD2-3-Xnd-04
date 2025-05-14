# 엑셀 파일의 데이터를 xndapp_recipes DB에 저장하는 코드입니다.

import csv
import os
import django

# Django 설정 로드
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'Xnd.settings')
django.setup()

# 모델 가져오기
from XndApp.Models.recipes import Recipes

def import_recipes():
    # 이미 데이터가 있는지 확인
    if Recipes.objects.exists():
        print("이미 레시피 데이터가 존재합니다. 기존 데이터를 삭제하시겠습니까? (y/n)")
        response = input().lower()
        if response == 'y':
            Recipes.objects.all().delete()
            print("기존 데이터가 삭제되었습니다.")
        else:
            print("기존 데이터를 유지합니다. 새 데이터가 추가됩니다.")

    file_path = r"C:\Users\wjdgu\Downloads\recipe_dataset__.csv"  # 엑셀 파일 컬럼 테이블 컬럼과 일치하는 부분만 남겨두기

    try:
        with open(file_path, 'r', encoding='utf-8-sig') as file:  # BOM 제거를 위한 utf-8-sig 사용
            print("utf-8-sig 인코딩으로 파일 읽기 시도 중...")
            reader = csv.DictReader(file)

            # 필드 매핑 확인
            print("CSV 헤더:", reader.fieldnames)

            # BOM 문자 처리 (첫 번째 필드 이름에서 BOM 제거)
            clean_fieldnames = reader.fieldnames.copy()
            if clean_fieldnames and clean_fieldnames[0].startswith('\ufeff'):
                clean_fieldnames[0] = clean_fieldnames[0].replace('\ufeff', '')
                print("BOM 제거 후 첫 번째 필드:", clean_fieldnames[0])

            count = 0
            for row in reader:
                # BOM 문자가 있는 경우 처리
                recipe_data = {}
                if '\ufeffrecipe_id' in row:
                    recipe_data['recipe_id'] = row['\ufeffrecipe_id']
                elif 'recipe_id' in row:
                    recipe_data['recipe_id'] = row['recipe_id']

                # 나머지 필드 처리
                for field in ['recipe_image', 'category1', 'category2', 'category3',
                              'category4', 'food_name', 'steps', 'serving_size',
                              'cooking_time', 'cooking_level']:
                    if field in row:
                        recipe_data[field] = row[field]

                # 객체 생성 및 저장
                try:
                    recipe = Recipes(**recipe_data)
                    recipe.save()
                    count += 1

                    # 진행 상황 보고
                    if count % 100 == 0:
                        print(f"{count}개 레시피 가져오기 완료...")
                except Exception as e:
                    print(f"레시피 저장 오류: {e}")
                    print(f"문제의 데이터: {recipe_data}")
                    # 계속 진행할지 결정
                    choice = input("계속 진행하시겠습니까? (y/n): ").lower()
                    if choice != 'y':
                        break

            print(f"총 {count}개의 레시피가 성공적으로 가져와졌습니다.")

    except UnicodeDecodeError as e:
        print(f"인코딩 오류: {e}")
        # 다른 인코딩 시도
        try_other_encodings(file_path)
    except Exception as e:
        print(f"오류 발생: {e}")
        import traceback
        traceback.print_exc()  # 상세 오류 정보 출력


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
    import_recipes()