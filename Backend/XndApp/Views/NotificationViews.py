# NotificationViews.py

from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone
from datetime import timedelta
from XndApp.Models.notification import Device, PushNotification
from XndApp.serializers.notification_serializers import DeviceSerializer, PushNotificationSerializer
from tasks import schedule_push_notification

# 알림 받을 기기 등록
class RegisterDeviceView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = DeviceSerializer(data=request.data)

        if serializer.is_valid():
            device, created = Device.objects.update_or_create(
                user=request.user,
                fcm_token=serializer.validated_data['fcm_token'],
                defaults={
                    **serializer.validated_data,
                    'is_active': True,
                    'updated_at': timezone.now()
                }
            )

            message = '기기 등록 성공' if created else '기기 정보 업데이트 성공'
            return Response({
                'message': message,
                'device_id': device.id
            }, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# 기기 설정 - 알림 On/Off
class DeviceManageView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request):
        fcm_token = request.data.get('fcm_token')
        is_active = request.data.get('is_active', True)

        if not fcm_token:
            return Response({
                'error': 'fcm_token이 필요합니다'
            }, status=status.HTTP_400_BAD_REQUEST)

        try:
            device = Device.objects.get(user=request.user, fcm_token=fcm_token)
            device.is_active = is_active
            device.save()

            status_text = "활성화" if is_active else "비활성화"
            return Response({
                'message': f'알림이 {status_text}되었습니다',
                'is_active': device.is_active
            }, status=status.HTTP_200_OK)
        except Device.DoesNotExist:
            return Response({
                'error': '기기를 찾을 수 없습니다'
            }, status=status.HTTP_404_NOT_FOUND)


# 알림 생성 및 조회
class NotificationView(APIView):

    permission_classes = [IsAuthenticated]

    # 알림 생성 - 식재료 입고 시 함께
    def post(self, request):
        print(f"=== 유통기한 알림 생성 API ===")
        print(f"User: {request.user}")
        print(f"Request Data: {request.data}")

        fridge_ingredient_id = request.data.get('fridge_ingredient')

        if not fridge_ingredient_id:
            return Response({
                'error': 'fridge_ingredient 필드가 필요합니다'
            }, status=status.HTTP_400_BAD_REQUEST)

        try:
            from XndApp.Models.fridgeIngredients import FridgeIngredients

            ingredient = FridgeIngredients.objects.get(
                id=fridge_ingredient_id,
                fridge__user=request.user
            )
            print(f"식재료: {ingredient.ingredient_name}, 유통기한: {ingredient.storable_due}")

            from fcm_services import create_expiry_notifications
            notifications = create_expiry_notifications(ingredient)

            print(f"생성된 알림: {len(notifications)}개")

            return Response({
                'message': f'{ingredient.ingredient_name} 유통기한 알림 설정 완료',
                'ingredient_name': ingredient.ingredient_name,
                'storable_due': ingredient.storable_due,
                'notifications_created': len(notifications)
            }, status=status.HTTP_201_CREATED)

        except FridgeIngredients.DoesNotExist:
            return Response({
                'error': '해당 식재료를 찾을 수 없습니다'
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            print(f"에러: {e}")
            return Response({
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    def get(self, request):
        notifications = PushNotification.objects.filter(
            user=request.user,
            status='sent'
        )
        serializer = PushNotificationSerializer(notifications, many=True)
        return Response({
            'notifications': serializer.data,
            'count': notifications.count(),
            'unread_count': notifications.filter(is_read=False).count()
        }, status=status.HTTP_200_OK)


# 개별 알림 읽음 처리
class NotificationDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, notification_id):
        try:
            notification = PushNotification.objects.get(
                id=notification_id,
                user=request.user
            )
            notification.is_read = True
            notification.save()
            return Response({
                'message': '읽음 처리 완료',
                'notification_id': notification_id
            }, status=status.HTTP_200_OK)
        except PushNotification.DoesNotExist:
            return Response({
                'error': '알림을 찾을 수 없습니다'
            }, status=status.HTTP_404_NOT_FOUND)