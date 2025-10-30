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
class User(AbstractBaseUser):
    user_id = models.AutoField(primary_key=True)
    # SocialLoginInfo
    social_id = models.CharField(max_length=255, unique=True)
    social_provider = models.CharField(max_length=20)
    # userInfo(extra_fields)
    name = models.CharField(max_length=100,default='')
    email = models.TextField(default='')

    # AccountBook fields (가계부 관련 필드)
    monthly_budget = models.IntegerField(default=100000)  # 월 식비 예산 (갱신일마다 초기화할 금액)
    budget_reset_day = models.IntegerField(default=1)  # 예산 갱신일 (1~31일, 기본값 1일)
    monthly_spent = models.IntegerField(default=0)  # 이번 달 식비 누적 지출
    last_reset_date = models.DateField(null=True, blank=True)  # 마지막 예산 갱신일

    # Include UserManager
    objects = UserManager()

    USERNAME_FIELD = 'social_id'
    REQUIRED_FIELDS = ['name','email']

    @property
    def budget(self):
        """이번 달 남은 식비 예산 (monthly_budget - monthly_spent)"""
        return self.monthly_budget - self.monthly_spent

    def add_expense(self, amount):
        """지출 추가 (누적 지출 증가)"""
        self.monthly_spent += amount
        self.save()

    def reset_monthly_budget(self):
        """월 예산 초기화 (갱신일에 호출)"""
        from datetime import date
        self.monthly_spent = 0
        self.last_reset_date = date.today()
        self.save()

    def check_and_reset_budget(self):
        """예산 갱신일 체크 및 필요시 초기화"""
        from datetime import date
        today = date.today()

        # 마지막 갱신일이 없거나, 현재 날짜가 갱신일이고 아직 이번 달에 갱신하지 않았다면
        if (self.last_reset_date is None or
            (today.day == self.budget_reset_day and
             (self.last_reset_date.year != today.year or self.last_reset_date.month != today.month))):
            self.reset_monthly_budget()

