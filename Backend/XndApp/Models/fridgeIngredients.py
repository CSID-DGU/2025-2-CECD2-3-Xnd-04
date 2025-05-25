# 냉장고 속 재료
from django.db import models
from django.core.validators import MinValueValidator
from XndApp.Models.fridge import Fridge
from XndApp.Models.foodStorageLife import FoodStorageLife
from datetime import timedelta
# from XndApp.Models.category import Category

class FridgeIngredients(models.Model):
    fridge = models.ForeignKey(Fridge,on_delete=models.CASCADE)
    stored_at = models.DateTimeField(auto_now_add=True)
    layer = models.IntegerField(
        validators=[MinValueValidator(0)],  #0 이상
        
        help_text="냉장고 내의 재료의 위치(단수)"
        )
    # category = models.ForeignKey(Category,on_delete=models.CASCADE)
    foodStorageLife = models.ForeignKey(FoodStorageLife,on_delete=models.SET_DEFAULT, default=100) 
    storable_due = models.DateTimeField(null=True)
    # 외부 테이블 참조 시 수정
    ingredient_name = models.CharField(max_length=100)

    ingredient_pic = models.CharField(max_length=255)

    def save(self, *args, **kwargs):
        # layer값 검사
        if self.fridge and self.layer > self.fridge.layer_count:
            raise ValueError(f"layer 값은 fridge.layers({self.fridge.layer_count})보다 작아야 합니다.")
        
        # 보관 가능 날짜 DB저장
        if self.stored_at and self.foodStorageLife and self.foodStorageLife.storage_life:
            self.storable_due = self.stored_at + timedelta(days=self.foodStorageLife.storage_life)
        super().save(*args, **kwargs)

    # 메타데이터
    class Meta:
        db_table = 'xndapp_fridgeingredients'
        ordering = ['-storable_due']  # 보관기한 임박순으로 정렬