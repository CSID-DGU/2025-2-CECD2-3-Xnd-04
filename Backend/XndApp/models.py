from django.db import models
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin, BaseUserManager


# Create your models here.


# UserManager
class UserManager(BaseUserManager):
    # User Create
    def create_user(self, social_id, social_provider, **extra_fields):
        if not social_id:
            raise ValueError('The Social ID must be set')
        user = self.model(social_id=social_id, social_provider=social_provider, **extra_fields)
        user.save()
        return user
    # Super User Create
    # def create_superuser(self, social_id, social_provider, **extra_fields):
    #     extra_fields.setdefault('is_staff', True)
    #     extra_fields.setdefault('is_superuser', True)
    #     return self.create_user(social_id, social_provider, **extra_fields)
    

# User
class User(models.Model):
    # SocialLoginInfo
    social_id = models.CharField(max_length=255, unique=True)
    social_provider = models.CharField(max_length=20)
    # userInfo(extra_fields)
    name = models.CharField(max_length=10,default='')
    email = models.TextField(default='')

    # Include UserManager
    users = UserManager()



# 냉장고 테이블

