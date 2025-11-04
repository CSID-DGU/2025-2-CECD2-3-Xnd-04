from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from datetime import datetime
from XndApp.Models.expense import Expense

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_daily_expenses(request):
    """
    특정 날짜의 지출 내역 조회
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

        # 해당 날짜의 지출 내역 조회
        expenses = Expense.objects.filter(
            user=user,
            date=target_date
        )

        expenses_data = [{
            'id': expense.id,
            'item_name': expense.item_name,
            'amount': expense.amount,
            'category': expense.category,
            'memo': expense.memo,
            'date': expense.date.strftime('%Y-%m-%d')
        } for expense in expenses]

        # 총 지출 계산
        total_amount = sum(expense.amount for expense in expenses)

        return Response({
            'date': date_str,
            'expenses': expenses_data,
            'total_amount': total_amount,
            'count': len(expenses_data)
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_expense(request):
    """
    지출 내역 추가
    Request body:
    {
        "date": "2025-11-01",
        "item_name": "마트 장보기",
        "amount": 15000,
        "category": "기타",
        "memo": "간단한 메모"
    }
    """
    try:
        user = request.user
        date_str = request.data.get('date')
        item_name = request.data.get('item_name')
        amount = request.data.get('amount')
        category = request.data.get('category', '기타')
        memo = request.data.get('memo', '')

        if not date_str or not item_name or not amount:
            return Response(
                {'error': '날짜, 항목명, 금액을 모두 입력해주세요'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            expense_date = datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            return Response(
                {'error': '날짜 형식이 올바르지 않습니다 (YYYY-MM-DD)'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # 지출 내역 생성
        expense = Expense.objects.create(
            user=user,
            date=expense_date,
            item_name=item_name,
            amount=int(amount),
            category=category,
            memo=memo
        )

        # 사용자의 월 누적 지출에 추가
        user.add_expense(int(amount))

        return Response({
            'message': '지출 내역이 추가되었습니다',
            'expense_id': expense.id,
            'remaining_budget': user.budget
        }, status=status.HTTP_201_CREATED)

    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_expense(request, expense_id):
    """
    지출 내역 삭제
    """
    try:
        user = request.user

        # 지출 내역 조회
        expense = Expense.objects.filter(id=expense_id, user=user).first()

        if not expense:
            return Response(
                {'error': '지출 내역을 찾을 수 없습니다'},
                status=status.HTTP_404_NOT_FOUND
            )

        # 지출 금액 저장 (월 누적 지출에서 차감하기 위해)
        expense_amount = expense.amount

        # 지출 내역 삭제
        expense.delete()

        # 사용자의 월 누적 지출에서 차감
        if user.monthly_spent >= expense_amount:
            user.monthly_spent -= expense_amount
            user.save()

        return Response({
            'message': '지출 내역이 삭제되었습니다',
            'remaining_budget': user.budget
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
