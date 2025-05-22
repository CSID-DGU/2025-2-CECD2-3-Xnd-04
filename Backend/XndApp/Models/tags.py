# 레시피 태그 테이블(저장된 레시피 - 태그)
from django.db import models
from XndApp.Models.recipes import Recipes

class Tags(models.Model):
    tag_id = models.AutoField(primary_key=True)
    tag_name = models.CharField(max_length=50)
    recipe = models.ManyToManyField(Recipes, related_name='tags')

