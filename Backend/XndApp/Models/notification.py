from django.db import models
from XndApp.Models.user import User

class Device(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    fcm_token = models.CharField(max_length=500)
    device_type = models.CharField(max_length=20, choices=[
        ('android', 'Android'),
        ('ios', 'iOS'),
    ])
    device_name = models.CharField(max_length=100, blank=True)
    is_active = models.BooleanField(default=True)  # 알림 on/off
    created_at = models.DateTimeField(auto_now_add=True) # 기기 등록 시점
    updated_at = models.DateTimeField(auto_now=True)  # 토큰 업데이트 시점

    class Meta:
        unique_together = ['user', 'fcm_token']

    def __str__(self):
        return f"{self.user.user_id}의 {self.device_type}"       # user_name은 null 값이 존재해 user_id 사용

    def save(self, *args, **kwargs):

        if not self.pk and not self.device_name:
            device_count = Device.objects.filter(
                user=self.user,
                device_type=self.device_type
            ).count() + 1  # 유저 - 기기별

            self.device_name = f"{self.user.user_id}의 {self.device_type} #{device_count}"
        super().save(*args, **kwargs)
