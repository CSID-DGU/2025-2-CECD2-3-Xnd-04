from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.db import transaction
from django.db import models
from datetime import datetime
from XndApp.Models.shoppingList import ShoppingList
from XndApp.Models.cart import Cart
from XndApp.Models.ingredients import Ingredient
from XndApp.Models.user import User
from XndApp.Models.expense import Expense

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_shopping_list(request):
    """
    장보기 목록에 재료 추가 (캘린더에 추가)
    Request body:
    {
        "cart_item_ids": [1, 2, 3],  # 장바구니 항목 ID 배열
        "shopping_date": "2025-11-01"  # 장보기 날짜
    }
    """
    try:
        user = request.user
        cart_item_ids = request.data.get('cart_item_ids', [])
        shopping_date_str = request.data.get('shopping_date')

        if not cart_item_ids:
            return Response(
                {'error': '장바구니 항목을 선택해주세요'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not shopping_date_str:
            return Response(
                {'error': '장보기 날짜를 선택해주세요'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # 날짜 변환
        try:
            shopping_date = datetime.strptime(shopping_date_str, '%Y-%m-%d').date()
        except ValueError:
            return Response(
                {'error': '날짜 형식이 올바르지 않습니다 (YYYY-MM-DD)'},
                status=status.HTTP_400_BAD_REQUEST
            )

        added_count = 0
        duplicate_count = 0

        with transaction.atomic():
            for cart_id in cart_item_ids:
                try:
                    # 장바구니 항목 조회
                    cart_item = Cart.objects.get(id=cart_id, user=user)

                    # ShoppingList에 추가 (중복 체크는 unique_together로 처리)
                    shopping_list, created = ShoppingList.objects.get_or_create(
                        user=user,
                        ingredient=cart_item.ingredient,
                        shopping_date=shopping_date
                    )

                    if created:
                        added_count += 1
                    else:
                        duplicate_count += 1

                except Cart.DoesNotExist:
                    continue

        return Response({
            'message': f'{added_count}개의 재료를 장보기 목록에 추가했습니다',
            'added_count': added_count,
            'duplicate_count': duplicate_count,
            'shopping_date': shopping_date_str
        }, status=status.HTTP_201_CREATED)

    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_shopping_list(request):
    """
    특정 날짜의 장보기 목록 조회
    Query params: ?date=2025-11-01
    """
    try:
        user = request.user
        date_str = request.GET.get('date')

        if not date_str:
            return Response(
                {'error': '날짜를 입력해주세요'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            shopping_date = datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            return Response(
                {'error': '날짜 형식이 올바르지 않습니다 (YYYY-MM-DD)'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # 해당 날짜의 장보기 목록 조회 (is_bought=False인 항목만)
        shopping_items = ShoppingList.objects.filter(
            user=user,
            shopping_date=shopping_date,
            is_bought=False
        ).select_related('ingredient')

        items_data = [{
            'id': item.id,
            'ingredient_id': item.ingredient.id,
            'ingredient_name': item.ingredient.name,
            'shopping_date': item.shopping_date.strftime('%Y-%m-%d'),
            'price': item.price,
            'is_bought': item.is_bought
        } for item in shopping_items]

        return Response({
            'shopping_date': date_str,
            'items': items_data,
            'count': len(items_data)
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def complete_shopping(request):
    """
    장보기 완료 처리
    - 선택된 재료들의 가격 저장 및 is_bought를 True로 업데이트
    - 총 지출을 해당 월의 누적 지출에 추가
    Request body:
    {
        "shopping_list_ids": [1, 2, 3],  # 완료할 장보기 항목 ID 배열
        "prices": {
            "1": 3000,  # shopping_list_id: 가격
            "2": 5000,
            "3": 4500
        }
    }
    """
    try:
        user = request.user
        shopping_list_ids = request.data.get('shopping_list_ids', [])
        prices = request.data.get('prices', {})

        if not shopping_list_ids:
            return Response(
                {'error': '완료할 항목을 선택해주세요'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not prices:
            return Response(
                {'error': '가격 정보가 없습니다'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # 총 지출 계산 및 가격 검증
        total_price = 0
        for item_id in shopping_list_ids:
            item_id_str = str(item_id)
            if item_id_str in prices:
                total_price += int(prices[item_id_str])
            else:
                return Response(
                    {'error': f'항목 {item_id}의 가격이 입력되지 않았습니다'},
                    status=status.HTTP_400_BAD_REQUEST
                )

        with transaction.atomic():
            # 장보기 항목 업데이트 (가격 저장 및 is_bought를 True로 설정)
            updated_count = 0
            shopping_items_info = []

            for item_id in shopping_list_ids:
                item_id_str = str(item_id)
                price = int(prices[item_id_str])

                # ShoppingList 항목 조회
                shopping_item = ShoppingList.objects.filter(
                    id=item_id,
                    user=user
                ).first()

                if shopping_item:
                    # 가격 저장 및 is_bought 업데이트
                    shopping_item.price = price
                    shopping_item.is_bought = True
                    shopping_item.save()
                    updated_count += 1

                    # 지출 내역 생성을 위한 정보 저장
                    shopping_items_info.append({
                        'name': shopping_item.ingredient.name,
                        'price': price,
                        'date': shopping_item.shopping_date
                    })

            # 장보기 지출 내역 생성 (각 재료마다 개별 생성)
            if shopping_items_info:
                # 각 재료마다 개별 지출 내역 생성
                for item_info in shopping_items_info:
                    Expense.objects.create(
                        user=user,
                        date=item_info['date'],
                        item_name=item_info['name'],
                        amount=item_info['price'],
                        category='장보기',
                        memo='장보기'
                    )

            # 사용자의 월 누적 지출에 추가
            user.add_expense(total_price)

        return Response({
            'message': f'{updated_count}개의 재료를 구매 완료했습니다',
            'total_price': total_price,
            'completed_count': updated_count,
            'remaining_budget': user.budget
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_shopping_items(request):
    """
    장보기 목록에서 항목 삭제 (완료하지 않고 그냥 삭제)
    Request body:
    {
        "shopping_list_ids": [1, 2, 3]
    }
    """
    try:
        user = request.user
        shopping_list_ids = request.data.get('shopping_list_ids', [])

        if not shopping_list_ids:
            return Response(
                {'error': '삭제할 항목을 선택해주세요'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # 장보기 목록에서 항목 삭제
        deleted_count, _ = ShoppingList.objects.filter(
            id__in=shopping_list_ids,
            user=user
        ).delete()

        return Response({
            'message': f'{deleted_count}개의 항목이 삭제되었습니다',
            'deleted_count': deleted_count
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_daily_spending(request):
    """
    특정 날짜의 장보기 지출 조회
    is_bought가 true인 항목들의 총 가격 반환
    Query params: ?date=2025-11-01
    """
    try:
        user = request.user
        date_str = request.GET.get('date')

        if not date_str:
            return Response(
                {'error': '날짜를 입력해주세요'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            target_date = datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            return Response(
                {'error': '날짜 형식이 올바르지 않습니다 (YYYY-MM-DD)'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # 해당 날짜의 구매 완료된(is_bought=True) 항목들 조회
        shopping_items = ShoppingList.objects.filter(
            user=user,
            shopping_date=target_date,
            is_bought=True,
            price__isnull=False
        )

        # 총 지출 계산
        total_spending = sum(item.price for item in shopping_items)
        item_count = shopping_items.count()

        return Response({
            'date': date_str,
            'total_spending': total_spending,
            'item_count': item_count
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_monthly_spending(request):
    """
    특정 월의 날짜별 장보기 지출 조회
    각 날짜별로 is_bought가 true인 항목들의 총 가격 반환
    Query params: ?year=2025&month=11
    """
    try:
        user = request.user
        year = request.GET.get('year')
        month = request.GET.get('month')

        if not year or not month:
            return Response(
                {'error': '연도와 월을 입력해주세요'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            year = int(year)
            month = int(month)
        except ValueError:
            return Response(
                {'error': '연도와 월은 숫자여야 합니다'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # 해당 월의 구매 완료된 항목들 조회
        shopping_items = ShoppingList.objects.filter(
            user=user,
            shopping_date__year=year,
            shopping_date__month=month,
            is_bought=True,
            price__isnull=False
        ).values('shopping_date').annotate(
            daily_total=models.Sum('price')
        ).order_by('shopping_date')

        # 날짜별 지출 데이터 생성
        daily_spending = {}
        for item in shopping_items:
            date_str = item['shopping_date'].strftime('%Y-%m-%d')
            daily_spending[date_str] = item['daily_total']

        return Response({
            'year': year,
            'month': month,
            'daily_spending': daily_spending
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
