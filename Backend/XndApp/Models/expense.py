from django.db import models
from XndApp.Models.user import User

class Expense(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='expenses')
    date = models.DateField()  # 지출 날짜
    item_name = models.CharField(max_length=200)  # 항목명
    amount = models.IntegerField()  # 금액
    memo = models.TextField(blank=True, null=True)  # 메모
    category = models.CharField(max_length=50, default='기타')  # 카테고리 (장보기, 외식, 기타 등)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'expense'
        ordering = ['-date', '-created_at']

    def __str__(self):
        return f"{self.user.user_name} - {self.date} - {self.item_name}: {self.amount}원"
