# 장바구니(recipeIngredients - user관계 테이블)
from django.db import models
from XndApp.Models.savedRecipeIngredients import SavedRecipeIngredients
from django.contrib.auth import get_user_model

User = get_user_model()

class Cart(models.Model):
    ingredient = models.ForeignKey(SavedRecipeIngredients,on_delete=models.CASCADE)
    user =  models.ForeignKey(User,on_delete=models.CASCADE)

    def __str__(self):
        return f"재료명 : {self.ingredient.ingredient_name}, 사용자 : {self.user.get_full_name()}"

# 메타데이터
class Meta:
    db_table = 'cart'  
    ordering = ['user']  # 유저별 정렬