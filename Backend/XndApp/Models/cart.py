from django.db import models
from XndApp.Models.user import User
from XndApp.Models.ingredients import Ingredient
from XndApp.Models.recipes import Recipes


class Cart(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    ingredient = models.ForeignKey(Ingredient, on_delete=models.CASCADE)
    recipe = models.ForeignKey(Recipes, on_delete=models.CASCADE, to_field='recipe_id', null=True, blank=True)
    quantity = models.CharField(max_length=50, default='1')  # 재료 중량 (예: "200g", "1/2포기")

    class Meta:
        unique_together = (('user', 'ingredient', 'recipe'),)

    def __str__(self):
        return f"재료명: {self.ingredient.name}, 사용자: {self.user.get_full_name()}, 레시피: {self.recipe.food_name if self.recipe else 'N/A'}"