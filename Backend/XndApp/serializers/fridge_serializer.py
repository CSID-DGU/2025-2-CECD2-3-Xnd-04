from rest_framework import serializers
from ..Models.fridge import Fridge

class FridgeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Fridge
        fields = ['model_label','layer_count','user','created_at']
        read_only_fields=['user','created_at']