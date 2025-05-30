# 냉장고
from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()

class Fridge(models.Model):
    fridge_id = models.AutoField(primary_key=True)
    layer_count = models.IntegerField(help_text="냉장고 단 수")
    model_label = models.CharField(max_length=100,default='기본 냉장고')
    user = models.ForeignKey(User,on_delete=models.CASCADE,default=111)
    created_at = models.DateTimeField(auto_now_add=True)

    # Admin페이지에서 냉장고를 구분하기 위한 방법
    def __str__(self):
        return f"{self.user.get_full_name()}의 냉장고 ({self.model_label})"
    # 메타데이터
    class Meta:
        db_table = 'fridge'  
        ordering = ['user','-created_at']  # 유저별 최근 등록순 정렬