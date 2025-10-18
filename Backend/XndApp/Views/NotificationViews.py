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
from celery import current_app

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

    def post(self, request):

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

            user = request.user
            ingredient_name = ingredient.ingredient_name
            storable_due = ingredient.storable_due

            if not storable_due or storable_due <= timezone.now():
                return Response({
                    'error': '유통기한이 현재 시간보다 이전입니다'
                }, status=status.HTTP_400_BAD_REQUEST)

            notifications = []

            # 48시간 전 알림 생성
            if storable_due > timezone.now() + timedelta(hours=48):
                notification_48h = PushNotification.objects.create(
                    user=user,
                    fridge_ingredient=ingredient,
                    title="2일 전 알림",
                    body=f"{ingredient_name}의 보관기한이 48시간 남았습니다",
                    schedule_time=storable_due - timedelta(hours=48),
                    status='pending'
                )

                # Celery 예약
                try:
                    task = schedule_push_notification.apply_async(
                        args=[notification_48h.id],
                        eta=notification_48h.schedule_time
                    )
                    notification_48h.celery_task_id = task.id
                    notification_48h.save()
                    print(f"48시간 전 알림 Celery 예약 성공")
                except Exception as celery_error:
                    print(f"48시간 전 알림 Celery 에러 (알림은 생성됨): {celery_error}")

                notifications.append(notification_48h)

            # 24시간 전 알림 생성
            if storable_due > timezone.now() + timedelta(hours=24):
                notification_24h = PushNotification.objects.create(
                    user=user,
                    fridge_ingredient=ingredient,
                    title="1일 전 알림",
                    body=f"{ingredient_name}의 보관기한이 24시간 남았습니다",
                    schedule_time=storable_due - timedelta(hours=24),
                    status='pending'
                )

                # Celery 예약
                try:
                    task = schedule_push_notification.apply_async(
                        args=[notification_24h.id],
                        eta=notification_24h.schedule_time
                    )
                    notification_24h.celery_task_id = task.id
                    notification_24h.save()
                    print(f"24시간 전 알림 Celery 예약 성공")
                except Exception as celery_error:
                    print(f"24시간 전 알림 Celery 에러 (알림은 생성됨): {celery_error}")

                notifications.append(notification_24h)

            print(f"총 {len(notifications)}개 알림 생성 완료")

            return Response({
                'message': f'{ingredient_name} 유통기한 알림 설정 완료',
                'ingredient_name': ingredient_name,
                'storable_due': storable_due,
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


# 개별 알림 읽음 처리 및 삭제
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

    def delete(self, request, notification_id):
        try:
            notification = PushNotification.objects.get(
                id=notification_id,
                user=request.user
            )

            # Celery 태스크 취소
            # if notification.celery_task_id:
            #    current_app.control.revoke(notification.celery_task_id, terminate=True)

            notification.delete()
            return Response({'message': '알림 삭제 완료'})
        except PushNotification.DoesNotExist:
            return Response({'error': '알림을 찾을 수 없습니다'}, status=404)


# 식재료별 알림 일괄 삭제 (출고 시 사용)
class IngredientNotificationView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, ingredient_id):
        # 해당 식재료의 예약된 알림들만 삭제
        notifications = PushNotification.objects.filter(
            fridge_ingredient_id=ingredient_id,
            user=request.user,
            status='pending'  # 예약된 것만
        )

        # Celery 태스크 취소
        for notification in notifications:
            if notification.celery_task_id:
                current_app.control.revoke(notification.celery_task_id, terminate=True)

        count = notifications.count()
        notifications.delete()

        return Response({
            'message': f'{count}개 알림 삭제 완료'
        })