import csv
import os
import django
from datetime import datetime

# Django 설정 로드
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'Xnd.settings')
django.setup()

# 모델 가져오기
from XndApp.Models.fridgeIngredients import FridgeIngredients
from XndApp.Models.fridge import Fridge
from XndApp.Models.foodStorageLife import FoodStorageLife


def parse_datetime(date_string):
    """
    문자열 날짜를 datetime 객체로 변환
    """
    if not date_string:
        return datetime.now()

    try:
        # '2025-06-02 0:00' 형식 처리
        if ' 0:00' in date_string:
            date_string = date_string.replace(' 0:00', ' 00:00:00')

        # 여러 형식 시도
        for fmt in ['%Y-%m-%d %H:%M:%S', '%Y-%m-%d', '%Y-%m-%d %H:%M']:
            try:
                return datetime.strptime(date_string, fmt)
            except ValueError:
                continue

        # 기본값 반환
        return datetime.now()
    except:
        return datetime.now()


def import_fridge_ingredients():
    """
    CSV 파일에서 FridgeIngredients 데이터를 import
    """

    # 기존 데이터 확인
    if FridgeIngredients.objects.exists():
        print(f"기존 FridgeIngredients: {FridgeIngredients.objects.count()}개")
        print("기존 데이터를 삭제하시겠습니까? (y/n)")
        response = input().lower()
        if response == 'y':
            FridgeIngredients.objects.all().delete()
            print("기존 데이터가 삭제되었습니다.")
        else:
            print("기존 데이터를 유지합니다. 새 데이터가 추가됩니다.")

    file_path = "FridgeIngredients.csv"

    try:
        with open(file_path, 'r', encoding='utf-8-sig') as file:
            print("utf-8-sig 인코딩으로 파일 읽기 시도 중...")
            reader = csv.DictReader(file)

            # 필드 매핑 확인
            print("CSV 헤더:", reader.fieldnames)

            # 진행 통계
            created_count = 0

            for row in reader:
                # BOM 처리
                fridge_ingredient_data = {}

                # BOM 처리 (첫 번째 필드)
                first_field = list(row.keys())[0]
                if first_field.startswith('\ufeff'):
                    clean_field = first_field.replace('\ufeff', '')
                    row[clean_field] = row[first_field]
                    del row[first_field]

                # 나머지 필드들
                field_mapping = {
                    'stored_at': 'stored_at',
                    'layer': 'layer',
                    'storable_due': 'storable_due',
                    'ingredient_name': 'ingredient_name',
                    'ingredient_pic': 'ingredient_pic',
                    'foodStorageLife_id': 'foodStorageLife_id',
                    'fridge_id': 'fridge_id'
                }

                for csv_field, model_field in field_mapping.items():
                    if csv_field in row:
                        fridge_ingredient_data[model_field] = row[csv_field]

                try:

                    fridge = Fridge.objects.get(pk=5)  # 여기에 각자 냉장고 아이디 넣으시면 됩니다

                    food_storage_life = None
                    if fridge_ingredient_data.get('foodStorageLife_id'):
                        try:
                            food_storage_life = FoodStorageLife.objects.get(
                                pk=fridge_ingredient_data['foodStorageLife_id'])
                        except FoodStorageLife.DoesNotExist:
                            food_storage_life = None  # 없으면 None으로

                    # FridgeIngredients 객체 생성 (날짜 변환 추가)
                    fridge_ingredient = FridgeIngredients(
                        fridge=fridge,  # 모두 같은 fridge 사용
                        layer=int(fridge_ingredient_data['layer']),
                        stored_at=parse_datetime(fridge_ingredient_data['stored_at']),
                        storable_due=parse_datetime(fridge_ingredient_data['storable_due']),
                        ingredient_name=fridge_ingredient_data['ingredient_name'],
                        ingredient_pic=fridge_ingredient_data.get('ingredient_pic', ''),
                        foodStorageLife=food_storage_life
                    )

                    fridge_ingredient.save()
                    created_count += 1

                    # 진행 상황 보고
                    if created_count % 10 == 0:
                        print(f"{created_count}개 데이터 처리 완료...")

                except Fridge.DoesNotExist:
                    print("fridge_id=1을 찾을 수 없습니다. Fridge 테이블을 확인해주세요.")
                    break
                except Exception as e:
                    print(f"데이터 생성 오류: {e}")
                    print(f"문제 데이터: {fridge_ingredient_data}")
                    choice = input("계속 진행하시겠습니까? (y/n): ").lower()
                    if choice != 'y':
                        break

            print("\n==== 처리 완료 ====")
            print(f"생성된 FridgeIngredients: {created_count}개")
            print(f"총 FridgeIngredients 수: {FridgeIngredients.objects.count()}")

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
    print("FridgeIngredients import를 시작하시겠습니까? (y/n)")
    response = input().lower()
    if response == 'y':
        import_fridge_ingredients()
    else:
        print("import가 취소되었습니다.")