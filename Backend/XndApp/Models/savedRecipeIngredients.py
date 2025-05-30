# 저장된 레시피에 포함된 재료
from django.db import models
from XndApp.Models.savedRecipes import SavedRecipes
from XndApp.Models.ingredients import Ingredient

class SavedRecipeIngredients(models.Model):
    ingredient = models.ForeignKey(Ingredient, on_delete=models.CASCADE)  # 새 Ingredient 모델 참조
    recipe = models.ForeignKey(SavedRecipes,on_delete=models.CASCADE)
    amount = models.CharField(max_length=50)  # 수량 (예: '2개', '약간' 등)

    # 메타데이터
    class Meta:
        db_table = 'savedRecipeIngredients'  
        ordering = ['recipe']  # ← recipe 기준으로 정렬