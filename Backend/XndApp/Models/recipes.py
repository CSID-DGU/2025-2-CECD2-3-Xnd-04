# 크롤링한 레시피
from django.db import models

class Recipes(models.Model):
    recipe_id = models.IntegerField(primary_key=True,unique=True)
    recipe_image = models.CharField(max_length=255)
    category1 = models.CharField(max_length=100)
    category2 = models.CharField(max_length=100)
    category3 = models.CharField(max_length=100)
    category4 = models.CharField(max_length=100)
    food_name = models.CharField(max_length=100)
    ingredient_all = models.TextField(max_length=300)
    steps = models.TextField(help_text="요리 순서(내용)")
    serving_size = models.CharField(max_length=50,help_text="N인분")
    cooking_time = models.CharField(max_length=50,help_text="~분 이내")

    COOKING_LEVEL_CHOICES = [
        ('anyone', '아무나'),
        ('beginner', '초급'),
        ('intermediate', '중급'),
        ('advanced', '고급'),
    ]

    cooking_level = models.CharField(
        max_length=20,
        choices=COOKING_LEVEL_CHOICES,
        default='anyone'
    )