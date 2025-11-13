from rest_framework import serializers
from ..Models.purchase import Purchase


class PurchaseSerializer(serializers.ModelSerializer):
    """구매 내역 Serializer"""

    class Meta:
        model = Purchase
        fields = [
            'id',
            'ingredient_name',
            'price',
            'quantity',
            'purchase_date',
        ]
        read_only_fields = ['id', 'purchase_date']


class PurchaseCreateSerializer(serializers.Serializer):
    """구매 내역 생성 Serializer (장바구니 전체 구매)"""
    cart_ids = serializers.ListField(
        child=serializers.IntegerField(),
        required=True,
        help_text="구매할 장바구니 아이템 ID 리스트"
    )
