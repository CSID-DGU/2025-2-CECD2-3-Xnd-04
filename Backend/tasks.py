# tasks.py
from celery import shared_task
from django.utils import timezone
from XndApp.Models.notification import PushNotification
from fcm_services import send_push_notification, initialize_firebase

@shared_task
def schedule_push_notification(notification_id):
    print(f"=== 태스크 실행됨! notification_id: {notification_id} ===")

    # Firebase 초기화 확인
    if not initialize_firebase():
        print("[ERROR] Firebase 초기화 실패로 태스크 종료")
        return False

    try:
        notification = PushNotification.objects.get(id=notification_id)
        print(f"알림 찾음: {notification.title}")

        # 이미 처리된 알림은 스킵
        if notification.status != 'pending':
            print(f"[DEBUG] 알림 {notification_id} 이미 처리됨: {notification.status}")
            return False

        success = send_push_notification(
            notification.user,
            notification.title,
            notification.body
        )

        # 상태 업데이트
        notification.status = 'sent' if success else 'failed'
        notification.sent_at = timezone.now()
        notification.save()

        print(f"[DEBUG] 알림 {notification_id} {'전송 성공' if success else '전송 실패'}")
        return success

    except PushNotification.DoesNotExist:
        print(f"[DEBUG] 알림 {notification_id}를 찾을 수 없음")
        return False
    except Exception as e:
        print(f"[ERROR] 알림 전송 중 오류: {e}")
        return False