from django.db import models
from .user import User
from .ingredients import Ingredient


class Purchase(models.Model):
    """
    구매 내역 모델 (장보기 일정)
    장바구니에서 장보기 일정으로 추가되고, 실제 구매 완료 시 가격이 입력됨
    """
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='purchases')
    ingredient = models.ForeignKey(Ingredient, on_delete=models.CASCADE, related_name='purchases')
    ingredient_name = models.CharField(max_length=100)  # 식재료명
    price = models.IntegerField(default=0)  # 구매 가격 (장보기 일정 추가 시 0, 완료 시 입력)
    quantity = models.CharField(max_length=50, default='1')  # 구매 수량
    is_purchased = models.BooleanField(default=False)  # 장보기 완료 유무
    shopping_date = models.DateField(null=True, blank=True)  # 사용자가 선택한 장보기 예정 날짜
    purchase_date = models.DateTimeField(auto_now_add=True)  # 생성 날짜 (장보기 일정 추가 시점)
    completed_date = models.DateTimeField(null=True, blank=True)  # 장보기 완료 날짜

    class Meta:
        db_table = 'xndapp_purchases'
        ordering = ['-purchase_date']  # 최신 구매 내역이 먼저 오도록

    def __str__(self):
        status = "완료" if self.is_purchased else "예정"
        return f"{self.user.user_id} - {self.ingredient_name} ({status}, {self.price}원)"
