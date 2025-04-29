from rest_framework import serializers
from .Models.user import User
from .Models.refrigerator import Refrigerator

class UserSerializer(serializers.ModelSerializer):
    class meta:
        model = User
        fields = '__all__'