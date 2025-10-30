from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from XndApp.Models.user import User


@api_view(['GET', 'PATCH'])
@permission_classes([IsAuthenticated])
def account_book_settings(request):
    """
    가계부 설정 조회 및 수정
    GET: 현재 가계부 설정 조회
    PATCH: 가계부 설정 수정
    """
    user = request.user

    if request.method == 'GET':
        # 예산 갱신일 체크 및 필요시 초기화
        user.check_and_reset_budget()

        return Response({
            'monthly_budget': user.monthly_budget,  # 월 식비 예산 (자동 갱신 예산)
            'budget_reset_day': user.budget_reset_day,  # 예산 갱신일
            'monthly_spent': user.monthly_spent,  # 이번 달 누적 지출
            'budget': user.budget,  # 이번 달 남은 예산 (계산된 값)
            'last_reset_date': user.last_reset_date.isoformat() if user.last_reset_date else None,
        }, status=status.HTTP_200_OK)

    elif request.method == 'PATCH':
        # 설정 업데이트
        monthly_budget = request.data.get('monthly_budget')
        budget_reset_day = request.data.get('budget_reset_day')

        # 월 예산 업데이트
        if monthly_budget is not None:
            if not isinstance(monthly_budget, int) or monthly_budget < 0:
                return Response(
                    {'error': '월 예산은 0 이상의 정수여야 합니다'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            user.monthly_budget = monthly_budget

        # 예산 갱신일 업데이트
        if budget_reset_day is not None:
            if not isinstance(budget_reset_day, int) or budget_reset_day < 1 or budget_reset_day > 31:
                return Response(
                    {'error': '예산 갱신일은 1~31 사이의 정수여야 합니다'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            user.budget_reset_day = budget_reset_day

        user.save()

        return Response({
            'message': '가계부 설정이 업데이트되었습니다',
            'monthly_budget': user.monthly_budget,
            'budget_reset_day': user.budget_reset_day,
            'monthly_spent': user.monthly_spent,
            'budget': user.budget,
        }, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_expense(request):
    """
    지출 추가
    POST: 식비 지출 기록
    """
    user = request.user
    amount = request.data.get('amount')

    if amount is None:
        return Response(
            {'error': '금액(amount)이 필요합니다'},
            status=status.HTTP_400_BAD_REQUEST
        )

    if not isinstance(amount, int) or amount < 0:
        return Response(
            {'error': '금액은 0 이상의 정수여야 합니다'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # 예산 갱신일 체크
    user.check_and_reset_budget()

    # 지출 추가
    user.add_expense(amount)

    return Response({
        'message': '지출이 기록되었습니다',
        'amount': amount,
        'monthly_spent': user.monthly_spent,
        'budget': user.budget,  # 남은 예산
    }, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def reset_budget(request):
    """
    예산 수동 초기화
    POST: 예산을 즉시 초기화 (갱신일과 관계없이)
    """
    user = request.user
    user.reset_monthly_budget()

    return Response({
        'message': '예산이 초기화되었습니다',
        'monthly_budget': user.monthly_budget,
        'monthly_spent': user.monthly_spent,
        'budget': user.budget,
        'last_reset_date': user.last_reset_date.isoformat(),
    }, status=status.HTTP_200_OK)
