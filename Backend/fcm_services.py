# fcm_service.py
# DB 알림 생성 + Celery에 태스크 예약

import firebase_admin
from firebase_admin import credentials, messaging
from datetime import timedelta
from django.utils import timezone
from django.conf import settings
import os
from XndApp.Models.notification import PushNotification, Device


# Firebase 초기화
def initialize_firebase():
    """Firebase 초기화"""
    if not firebase_admin._apps: ###테스트용###
        try:
            # 개발환경: 파일 경로
            if hasattr(settings, 'FIREBASE_CREDENTIALS_PATH') and os.path.exists(settings.FIREBASE_CREDENTIALS_PATH):
                cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
                firebase_admin.initialize_app(cred)
                print("[DEBUG] Firebase 초기화 완료 (로컬)")
                return True

            # 운영환경: 환경변수
            elif os.getenv('FIREBASE_CREDENTIALS_JSON'):
                import json
                firebase_config = json.loads(os.getenv('FIREBASE_CREDENTIALS_JSON'))
                cred = credentials.Certificate(firebase_config)
                firebase_admin.initialize_app(cred)
                print("[DEBUG] Firebase 초기화 완료 (운영)")
                return True

            else:
                print("[DEBUG] Firebase 미설정 - 더미 모드")
                return False

        except Exception as e:
            print(f"[ERROR] Firebase 초기화 실패: {e}")
            return False
    else:
        return True

# FCM 푸시 알림 전송
def send_push_notification(user, title, body):
    try:
        firebase_ready = initialize_firebase()

        # 활성 기기 조회 (사용자의 모든 기기에 알림 전송)
        devices = Device.objects.filter(user=user, is_active=True)

        if not devices.exists():
            print(f"[DEBUG] {user.user_id}의 활성 기기가 없습니다")
            return False

        print(f"[DEBUG] {user.user_id}에게 알림 전송: {title}")
        print(f"[DEBUG] 대상 기기: {devices.count()}개")

        # Firebase 미설정시 더미 전송
        if not firebase_ready:
            print("[DEBUG] 더미 전송 완료")
            return True

        # 알림 전송
        tokens = [device.fcm_token for device in devices]

        message = messaging.MulticastMessage(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            tokens=tokens,
        )

        response = messaging.send_multicast(message)
        print(f"[DEBUG] FCM 전송 결과: 성공 {response.success_count}개, 실패 {response.failure_count}개")

        # 실패한 토큰 비활성화
        if response.failure_count > 0:
            for idx, result in enumerate(response.responses):
                if not result.success:
                    failed_token = tokens[idx]
                    Device.objects.filter(fcm_token=failed_token).update(is_active=False)
                    print(f"[DEBUG] 실패 토큰 비활성화: {failed_token}")

        return response.success_count > 0

    except Exception as e:
        print(f"FCM 전송 실패: {e}")
        return False

# 유통기한 알림 생성
def create_expiry_notifications(fridge_ingredient):
    from tasks import schedule_push_notification

    try:
        user = fridge_ingredient.fridge.user
        ingredient_name = fridge_ingredient.ingredient_name
        storable_due = fridge_ingredient.storable_due

        if not storable_due or storable_due <= timezone.now():
            return []

        notifications = []

        # 48시간 전 알림
        if storable_due > timezone.now() + timedelta(hours=48):
            notification_48h = PushNotification.objects.create(
                user=user,
                fridge_ingredient=fridge_ingredient,
                title="2일 전 알림",
                body=f"{ingredient_name}의 보관기한이 48시간 남았습니다",
                schedule_time=storable_due - timedelta(hours=48),
                status='pending'
            )

            # Celery 에러가 나도 알림은 생성
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

        # 24시간 전 알림
        if storable_due > timezone.now() + timedelta(hours=24):
            notification_24h = PushNotification.objects.create(
                user=user,
                fridge_ingredient=fridge_ingredient,
                title="1일 전 알림",
                body=f"{ingredient_name}의 보관기한이 24시간 남았습니다",
                schedule_time=storable_due - timedelta(hours=24),
                status='pending'
            )

            # Celery 에러가 나도 알림은 생성
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
        return notifications

    except Exception as e:
        print(f"전체 알림 생성 실패: {e}")
        return []


# 알림 취소 (식재료 출고 시 알림 삭제하는 방식)
def cancel_expiry_notifications(fridge_ingredient):
    from celery import current_app

    pending_notifications = PushNotification.objects.filter(
        fridge_ingredient=fridge_ingredient,
        status='pending'
    )

    # 1. Celery 태스크 명시적 취소
    for notification in pending_notifications:
        if notification.celery_task_id:
            current_app.control.revoke(notification.celery_task_id, terminate=True)

    # 2. DB에서 삭제
    pending_notifications.delete()
