# 유저가 저장한 레시피
from django.db import models
from XndApp.Models.recipes import Recipes
from django.contrib.auth import get_user_model

User = get_user_model()

class SavedRecipes(models.Model):
    user = models.ForeignKey(User,on_delete=models.CASCADE)
    recipe = models.ForeignKey(Recipes,on_delete=models.CASCADE)
    

# 메타데이터
class Meta:
    db_table = 'savedRecipes'  
    ordering = ['user']  # 유저별 정렬