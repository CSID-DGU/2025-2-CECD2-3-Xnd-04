# 냉장고 속 재료
from django.db import models
from django.core.validators import MinValueValidator
from XndApp.Models.fridge import Fridge
from XndApp.Models.foodStorageLife import FoodStorageLife
from datetime import timedelta
from XndApp.Models.ingredients import Ingredient

class FridgeIngredients(models.Model):

    STATUS_CHOICES = [
        ('inbound', '입고'),
        ('outbound', '출고'),
        ('in_use', '사용중'),
    ]

    STORAGE_LOCATION_CHOICES = [
        ('fridge', '냉장실'),
        ('freezer', '냉동실'),
        ('external', '외부'),
    ]

    fridge = models.ForeignKey(Fridge,on_delete=models.CASCADE)
    stored_at = models.DateTimeField(auto_now_add=True)
    storage_location = models.CharField(
        max_length=20,
        choices=STORAGE_LOCATION_CHOICES,
        default='fridge',
        help_text="보관 위치 (냉장실/냉동실/외부)"
    )
    layer = models.IntegerField(
        validators=[MinValueValidator(0)],  #0 이상
        help_text="냉장고 내의 재료의 위치(단수)"
        )
    # category = models.ForeignKey(Category,on_delete=models.CASCADE)
    foodStorageLife = models.ForeignKey(FoodStorageLife,on_delete=models.SET_DEFAULT, default=100, null=True)
    storable_due = models.DateTimeField(null=True)
    ingredient_name = models.CharField(max_length=100)
    ingredient_pic = models.CharField(max_length=255)

    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='inbound',
        help_text = "식재료 상태 (입고/출고/사용중)"
    )


    # 식재료 인식 결과
    category_yolo = models.CharField(max_length=100, default='FALLBACK_MODE', help_text="YOLO 객체 탐지 카테고리")
    yolo_confidence = models.FloatField(default=0.0, help_text="YOLO 객체 인식 신뢰도 점수 (0.0~1.0)")
    product_name_ocr = models.CharField(max_length=100, null=True, blank=True, help_text="OCR Word2Vec 추출 식재료명")
    product_similarity_score = models.FloatField(default=0.0, help_text="Word2Vec '식재료' 앵커 워드 유사도 점수 (0.0~1.0)")

    # 유통기한 인식 결과
    expiry_date = models.DateField(null=True, blank=True, help_text="파이프라인이 인식한 유통기한 날짜")
    expiry_date_status = models.CharField(max_length=15, default='NOT_FOUND', help_text="유통기한 상태 (CONFIRMED, UNCERTAIN, EXPIRED 등)")
    date_recognition_confidence = models.FloatField(default=0.0, help_text="유통기한 OCR 인식 신뢰도")
    date_type_confidence = models.FloatField(default=0.0, help_text="유통기한 유형 신뢰도")

    def save(self, *args, **kwargs):

        # 생성 시점(self._state.adding=True)이거나, storable_due가 비어있을 때만 자동 계산 로직 실행
        if self._state.adding or self.storable_due is None:

            # 1순위: OCR 유통기한이 인식되었고, 그 상태가 'CONFIRMED' 등일 때
            if self.expiry_date and (self.expiry_date_status == 'CONFIRMED' or self.expiry_date_status == 'EXPIRED'):
                self.storable_due = self.expiry_date

                # 2순위: FoodStorageLife 정보를 기반으로 자동 계산
            elif self.stored_at and self.foodStorageLife and self.foodStorageLife.storage_life:
                # stored_at이 DateTimeField이므로 .date()를 추출하여 계산합니다.
                self.storable_due = self.stored_at.date() + timedelta(days=self.foodStorageLife.storage_life)

        super().save(*args, **kwargs)

    # 메타데이터
    class Meta:
        db_table = 'xndapp_fridgeingredients'
        ordering = ['-storable_due']  # 보관기한 임박순으로 정렬