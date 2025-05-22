# 저장된 레시피에 포함된 재료
from django.db import models
from XndApp.Models.category import Category
from XndApp.Models.savedRecipes import SavedRecipes

class SavedRecipeIngredients(models.Model):
    ingredient_name = models.CharField(max_length=100)
    recipe = models.ForeignKey(SavedRecipes,on_delete=models.CASCADE)

# 메타데이터
class Meta:
    db_table = 'savedRecipeIngredients'  
    ordering = ['recipe']  # ← recipe 기준으로 정렬