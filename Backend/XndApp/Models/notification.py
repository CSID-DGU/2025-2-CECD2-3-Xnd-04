# notification.py

from django.db import models
from XndApp.Models.user import User
from XndApp.Models.fridgeIngredients import FridgeIngredients

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
        indexes = [
            models.Index(fields=['user', 'is_active']),  # 성능 최적화
        ]

    def __str__(self):
        return f"{self.user.user_id}의 {self.device_type}"

    def save(self, *args, **kwargs):
        if not self.pk and not self.device_name:
            device_count = Device.objects.filter(
                user=self.user,
                device_type=self.device_type
            ).count() + 1

            self.device_name = f"{self.user.user_id}의 {self.device_type} #{device_count}"
        super().save(*args, **kwargs)


class PushNotification(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    fridge_ingredient = models.ForeignKey(FridgeIngredients, on_delete=models.CASCADE, null=True, blank=True)
    title = models.CharField(max_length=100)
    body = models.TextField()
    schedule_time = models.DateTimeField()
    status = models.CharField(max_length=20,
                              choices=[
                                  ('pending', '전송 예정'),
                                  ('sent', '전송 성공'),
                                  ('failed', '전송 실패'),
                                  ('cancelled', '전송 취소')
                              ], default='pending')
    is_read = models.BooleanField(default=False)
    sent_at = models.DateTimeField(null=True, blank=True)  # 실제 전송 시간
    created_at = models.DateTimeField(auto_now_add=True)   # 알림 생성 시간
    celery_task_id = models.CharField(max_length=255, null=True, blank=True)

    class Meta:
        ordering = ['-created_at']  # 최신순 정렬
        indexes = [
            models.Index(fields=['user', 'status']),
            models.Index(fields=['user', 'is_read']),
        ]

    def __str__(self):
        return f"{self.user.user_id} - {self.title}"