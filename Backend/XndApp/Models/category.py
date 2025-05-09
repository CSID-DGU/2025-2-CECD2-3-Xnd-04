# 재료 카테고리 저장 테이블
from django.db import models
from datetime import timedelta

class Category(models.Model):
    category = models.CharField(max_length=100,unique=True,primary_key=True)
    duration = models.DurationField(default=timedelta(days=7))