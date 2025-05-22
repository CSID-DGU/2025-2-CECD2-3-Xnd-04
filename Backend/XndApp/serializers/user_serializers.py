from rest_framework import serializers
from XndApp.Models.user import User
from XndApp.Models.fridge import Fridge
from django.contrib.auth import get_user_model

class UserSerializer(serializers.ModelSerializer):
    class meta:
        model = get_user_model()
        fields = '__all__'