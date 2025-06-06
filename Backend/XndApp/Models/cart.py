from django.db import models
from XndApp.Models.user import User
from XndApp.Models.ingredients import Ingredient


class Cart(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    ingredient = models.ForeignKey(Ingredient, on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField(default=1)  # 장바구니에 담은 수량

    class Meta:
        unique_together = (('user', 'ingredient'),)

    def __str__(self):
        return f"재료명: {self.ingredient.name}, 사용자: {self.user.get_full_name()}"