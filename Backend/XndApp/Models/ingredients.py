from django.db import models
from XndApp.Models.foodStorageLife import FoodStorageLife

class Ingredient(models.Model):
    name = models.CharField(max_length=100)

    def __str__(self):
        return self.name