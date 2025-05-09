from rest_framework import serializers
from .Models.user import User
from .Models.fridge import Fridge
from django.contrib.auth import get_user_model

class UserSerializer(serializers.ModelSerializer):
    class meta:
        model = get_user_model()
        fields = '__all__'