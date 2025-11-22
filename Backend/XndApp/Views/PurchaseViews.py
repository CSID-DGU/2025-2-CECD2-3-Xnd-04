from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.db.models import Sum
from django.utils import timezone
from datetime import datetime
from XndApp.Models.purchase import Purchase
from XndApp.Models.cart import Cart
from XndApp.serializers.purchase_serializer import PurchaseSerializer, PurchaseCreateSerializer


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def purchase_list(request):
    """
    구매 내역 조회
    GET: 사용자의 구매 내역을 날짜별로 그룹화하여 반환
    Query Parameters:
        - year: 연도 (기본값: 현재 연도)
        - month: 월 (기본값: 현재 월)
    """
    user = request.user

    # 쿼리 파라미터에서 년도와 월 가져오기 (기본값: 현재 년월)
    year = request.query_params.get('year', datetime.now().year)
    month = request.query_params.get('month', datetime.now().month)

    try:
        year = int(year)
        month = int(month)
    except ValueError:
        return Response(
            {'error': '연도와 월은 정수여야 합니다'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # 해당 월의 완료된 구매 내역만 조회 (is_purchased=True)
    # timezone을 고려한 날짜 범위 필터링
    from datetime import date
    from django.utils import timezone as dj_timezone

    # 해당 월의 시작일과 종료일
    start_date = date(year, month, 1)
    if month == 12:
        end_date = date(year + 1, 1, 1)
    else:
        end_date = date(year, month + 1, 1)

    # timezone-aware datetime으로 변환
    start_datetime = dj_timezone.make_aware(datetime.combine(start_date, datetime.min.time()))
    end_datetime = dj_timezone.make_aware(datetime.combine(end_date, datetime.min.time()))

    purchases = Purchase.objects.filter(
        user=user,
        is_purchased=True,
        completed_date__gte=start_datetime,
        completed_date__lt=end_datetime
    ).order_by('-completed_date')

    print(f"[purchase_list] user={user.user_id}, year={year}, month={month}")
    print(f"[purchase_list] 조회된 Purchase 개수: {purchases.count()}")

    # 모든 Purchase 확인 (디버깅용)
    all_purchases = Purchase.objects.filter(user=user)
    print(f"[purchase_list] 전체 Purchase 개수: {all_purchases.count()}")

    # 완료된 항목만 확인
    completed_purchases = Purchase.objects.filter(user=user, is_purchased=True)
    print(f"[purchase_list] 완료된 Purchase 개수: {completed_purchases.count()}")
    for p in completed_purchases:
        if p.completed_date:
            print(f"  - {p.ingredient_name}, completed_date.year={p.completed_date.year}, completed_date.month={p.completed_date.month}")
        else:
            print(f"  - {p.ingredient_name}, completed_date=None (문제!)")

    # 날짜별로 그룹화
    grouped_purchases = {}
    for purchase in purchases:
        date_key = purchase.completed_date.strftime('%m월 %d일')
        if date_key not in grouped_purchases:
            grouped_purchases[date_key] = []

        grouped_purchases[date_key].append({
            'id': purchase.id,
            'name': purchase.ingredient_name,
            'amount': -purchase.price,  # 지출이므로 음수
            'quantity': purchase.quantity,
            'completed_date': purchase.completed_date.isoformat(),
        })

    # 각 날짜별로 남은 예산 계산
    result = []
    current_budget = user.budget + user.monthly_spent  # 초기 예산 (남은 예산 + 이미 쓴 돈)

    for date_key, items in grouped_purchases.items():
        for item in items:
            current_budget += item['amount']  # amount가 음수이므로 더하면 예산이 줄어듦
            item['remaining'] = current_budget

        result.append({
            'date': date_key,
            'items': items
        })

    return Response({
        'year': year,
        'month': month,
        'expenses': result
    }, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def purchase_create(request):
    """
    장바구니 -> 장보기 일정 추가
    POST: 선택한 장바구니 아이템들을 장보기 일정(Purchase)으로 추가
    Request Body:
        - cart_ids: 장보기 일정에 추가할 장바구니 아이템 ID 리스트
    """
    user = request.user
    serializer = PurchaseCreateSerializer(data=request.data)

    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    cart_ids = serializer.validated_data['cart_ids']

    # 사용자의 장바구니 아이템만 조회
    cart_items = Cart.objects.filter(id__in=cart_ids, user=user)

    if not cart_items.exists():
        return Response(
            {'error': '장보기 일정에 추가할 아이템이 없습니다'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # shopping_date 추출 (request body에서)
    shopping_date_str = request.data.get('shopping_date')
    shopping_date = None

    if shopping_date_str:
        try:
            from datetime import datetime
            shopping_date = datetime.strptime(shopping_date_str, '%Y-%m-%d').date()
        except ValueError:
            pass  # 날짜 형식이 잘못되면 None으로 유지

    # 장보기 일정 생성 (price=0, is_purchased=False)
    purchases = []

    for cart_item in cart_items:
        # 장보기 일정 생성 (가격은 0으로, 완료 여부는 False)
        purchase = Purchase(
            user=user,
            ingredient=cart_item.ingredient,
            ingredient_name=cart_item.ingredient.name,
            price=0,  # 장보기 일정 추가 시 0
            quantity=cart_item.quantity,
            is_purchased=False,  # 아직 구매 안 함
            shopping_date=shopping_date  # 사용자가 선택한 날짜
        )
        purchases.append(purchase)

    # 장보기 일정 일괄 저장
    Purchase.objects.bulk_create(purchases)

    # 장바구니 아이템 삭제
    cart_items.delete()

    return Response({
        'message': '장보기 일정에 추가되었습니다',
        'added_count': len(purchases),
    }, status=status.HTTP_201_CREATED)


@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def purchase_complete(request):
    """
    장보기 완료 처리
    PATCH: 장보기 일정의 가격을 입력하고 완료 처리
    Request Body:
        - purchases: [
            {
                "purchase_id": int,
                "price": int
            },
            ...
          ]
    """
    user = request.user
    purchases_data = request.data.get('purchases', [])

    if not purchases_data:
        return Response(
            {'error': 'purchases 데이터가 필요합니다'},
            status=status.HTTP_400_BAD_REQUEST
        )

    total_price = 0
    updated_purchases = []

    for item in purchases_data:
        purchase_id = item.get('purchase_id')
        price = item.get('price')

        if purchase_id is None or price is None:
            return Response(
                {'error': 'purchase_id와 price가 필요합니다'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            # 사용자의 장보기 일정만 조회
            purchase = Purchase.objects.get(id=purchase_id, user=user, is_purchased=False)
        except Purchase.DoesNotExist:
            return Response(
                {'error': f'장보기 일정 ID {purchase_id}를 찾을 수 없거나 이미 완료되었습니다'},
                status=status.HTTP_404_NOT_FOUND
            )

        # 가격 업데이트 및 완료 처리
        purchase.price = price
        purchase.is_purchased = True
        purchase.completed_date = timezone.now()
        purchase.save()

        total_price += price
        updated_purchases.append(purchase)

    # 예산에서 차감
    user.check_and_reset_budget()  # 예산 갱신일 체크
    user.add_expense(total_price)  # 지출 추가

    return Response({
        'message': '장보기가 완료되었습니다',
        'total_price': total_price,
        'completed_count': len(updated_purchases),
        'monthly_spent': user.monthly_spent,
        'budget': user.budget,
    }, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def purchase_pending_list(request):
    """
    장보기 일정 조회 (미완료)
    GET: is_purchased=False인 장보기 일정 조회
    Query Parameters:
        - date: 날짜 (YYYY-MM-DD) - 선택적
    """
    user = request.user
    date_str = request.query_params.get('date')

    # 미완료 장보기 일정 조회
    purchases = Purchase.objects.filter(
        user=user,
        is_purchased=False
    )

    # shopping_date로 필터링 (사용자가 선택한 장보기 예정 날짜)
    if date_str:
        try:
            target_date = datetime.strptime(date_str, '%Y-%m-%d').date()
            purchases = purchases.filter(shopping_date=target_date)
        except ValueError:
            return Response(
                {'error': '날짜 형식이 올바르지 않습니다 (YYYY-MM-DD)'},
                status=status.HTTP_400_BAD_REQUEST
            )

    purchases = purchases.order_by('-purchase_date')

    # 데이터 직렬화
    items_data = [{
        'id': item.id,
        'ingredient_id': item.ingredient.id,
        'ingredient_name': item.ingredient_name,
        'quantity': item.quantity,
        'purchase_date': item.purchase_date.strftime('%Y-%m-%d'),
        'price': item.price,
        'is_purchased': item.is_purchased
    } for item in purchases]

    return Response({
        'items': items_data,
        'count': len(items_data)
    }, status=status.HTTP_200_OK)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def purchase_delete(request, purchase_id):
    """
    구매 내역 삭제
    DELETE: 특정 구매 내역을 삭제하고 예산 복구
    """
    user = request.user

    try:
        purchase = Purchase.objects.get(id=purchase_id, user=user)
    except Purchase.DoesNotExist:
        return Response(
            {'error': '구매 내역을 찾을 수 없습니다'},
            status=status.HTTP_404_NOT_FOUND
        )

    # 완료된 구매만 예산 복구
    if purchase.is_purchased:
        user.monthly_spent = max(0, user.monthly_spent - purchase.price)
        user.save()

    purchase.delete()

    return Response({
        'message': '구매 내역이 삭제되었습니다',
        'monthly_spent': user.monthly_spent,
        'budget': user.budget,
    }, status=status.HTTP_200_OK)
