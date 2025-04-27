from django.db import models

# Create your models here.

class user(models.Model):
    name = models.CharField(max_length=10,default='')
    role = models.CharField(max_length=10,default='')
    email = models.TextField(default='')

