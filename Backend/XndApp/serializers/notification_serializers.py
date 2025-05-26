from rest_framework import serializers
from XndApp.Models.notification import Device

class DeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Device
        fields = ['fcm_token', 'device_type', 'device_name']
        extra_kwargs = {
            'device_type' : {'required' : False}
        }