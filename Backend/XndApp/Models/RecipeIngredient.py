from django.db import models
from XndApp.Models.ingredients import Ingredient
from XndApp.Models.recipes import Recipes


class RecipeIngredient(models.Model):
    """
    레시피와 식재료 간의 관계를 저장하는 모델
    """
    recipe = models.ForeignKey(Recipes, on_delete=models.CASCADE)  # 기존 Recipes 모델 참조
    ingredient = models.ForeignKey(Ingredient, on_delete=models.CASCADE)  # 새 Ingredient 모델 참조
    amount = models.CharField(max_length=50)  # 수량 (예: '2개', '약간' 등)

    class Meta:
        unique_together = (('recipe', 'ingredient'),)  # 하나의 레시피에 같은 재료 중복 방지

    def __str__(self):
        return f"{self.recipe.food_name} - {self.ingredient.name}: {self.amount}"