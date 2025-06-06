# notification_serializers.py

from rest_framework import serializers
from XndApp.Models.notification import Device, PushNotification

class DeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Device
        fields = ['fcm_token', 'device_type', 'device_name', 'is_active', 'created_at', 'updated_at']
        extra_kwargs = {
            'device_name': {'required': False},
            'is_active': {'read_only': True},  # 서버에서 관리
            'created_at': {'read_only': True},
            'updated_at': {'read_only': True}
        }

class PushNotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = PushNotification
        fields = ['id', 'fridge_ingredient', 'title', 'body', 'schedule_time', 'status', 'is_read', 'created_at', 'sent_at']  # fridge_ingredient 추가!
        extra_kwargs = {
            'id': {'read_only': True},
            'status': {'read_only': True},
            'is_read': {'read_only': True},
            'created_at': {'read_only': True},
            'sent_at': {'read_only': True}
        }