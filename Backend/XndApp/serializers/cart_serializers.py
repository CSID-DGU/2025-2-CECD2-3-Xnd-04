# serializers.py
from rest_framework import serializers
from XndApp.Models.cart import Cart
from XndApp.Models.ingredients import Ingredient

class CartSerializer(serializers.ModelSerializer):
    ingredient_id = serializers.PrimaryKeyRelatedField(
        source='ingredient',
        queryset=Ingredient.objects.all()
    )

    class Meta:
        model = Cart
        fields = ['id', 'ingredient_id', 'quantity']

class CartDetailSerializer(serializers.ModelSerializer):
    ingredient_id = serializers.PrimaryKeyRelatedField(source='ingredient', read_only=True)
    ingredient_name = serializers.CharField(source='ingredient.name', read_only=True)

    class Meta:
        model = Cart
        fields = ['id', 'ingredient_id', 'ingredient_name', 'quantity']