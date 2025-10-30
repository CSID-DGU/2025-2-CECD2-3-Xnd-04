from django.db import models
from XndApp.Models.user import User
from XndApp.Models.ingredients import Ingredient

class ShoppingList(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='shopping_lists')
    ingredient = models.ForeignKey(Ingredient, on_delete=models.CASCADE, related_name='shopping_lists')
    shopping_date = models.DateField()
    price = models.IntegerField(null=True, blank=True)  # 가격 (null 허용)
    is_bought = models.BooleanField(default=False)  # 장보기 완료 여부
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'shopping_list'
        # 같은 날짜에 같은 재료를 중복으로 추가하지 않도록
        unique_together = ('user', 'ingredient', 'shopping_date')

    def __str__(self):
        return f"{self.user.user_name} - {self.ingredient.name} - {self.shopping_date} - {'구매완료' if self.is_bought else '미구매'}"
