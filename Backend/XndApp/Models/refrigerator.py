from django.db import models

# 냉장고 테이블
class Refrigerator(models.Model):
    layer = models.IntegerField(max_length=10)