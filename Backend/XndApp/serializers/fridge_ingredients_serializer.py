from rest_framework import serializers
from ..Models.fridgeIngredients import FridgeIngredients
from XndApp.serializers.Ingredient_serializers import IngredientSerializer

class FridgeIngredientsSerializer(serializers.ModelSerializer):
    storable_due = serializers.DateField(required=False, allow_null=True)

    class Meta:
        model = FridgeIngredients
        fields = [
            'id',
            'status',
            'fridge',
            'layer',
            'ingredient_pic',

            'stored_at',

            'ingredient_name',
            'storable_due',

            'category_yolo',
            'yolo_confidence',

            'product_name_ocr',
            'product_similarity_score',

            'expiry_date',
            'expiry_date_status',
            'date_recognition_confidence',
            'date_type_confidence',


            'foodStorageLife',
        ]


        read_only_fields = [
            'id',
        ]

        extra_kwargs = {
            'ingredient_name': {'required': False},
            'category_yolo': {'required': False},
            'yolo_confidence': {'required': False},
            'product_name_ocr': {'required': False},
            'product_similarity_score': {'required': False},
            'expiry_date':{'required': False},
            'expiry_date_status':{'required': False},
            'date_recognition_confidence':{'required': False},
            'date_type_confidence':{'required': False},
        }