# fcm_services.py
import firebase_admin
from firebase_admin import credentials, messaging
from django.conf import settings
import os


def initialize_firebase():
    """Firebase 초기화"""
    if not firebase_admin._apps:
        try:
            # settings.py에서 이미 초기화됨을 확인
            return True
        except Exception as e:
            print(f"[ERROR] Firebase 초기화 실패: {e}")
            return False
    return True


def send_push_notification(user, title, body):
    """새로운 FCM v1 API로 푸시 알림 전송"""
    try:
        from XndApp.Models.notification import Device

        # 활성 기기 조회
        devices = Device.objects.filter(user=user, is_active=True)

        if not devices.exists():
            print(f"[DEBUG] {user.user_id}의 활성 기기가 없습니다")
            return False

        print(f"[DEBUG] {user.user_id}에게 알림 전송: {title}")
        print(f"[DEBUG] 대상 기기: {devices.count()}개")

        success_count = 0

        # 각 기기별로 개별 전송 (MulticastMessage 대신)
        for device in devices:
            try:
                message = messaging.Message(
                    notification=messaging.Notification(
                        title=title,
                        body=body,
                    ),
                    token=device.fcm_token,
                )

                # 개별 메시지 전송
                response = messaging.send(message)
                print(f"[DEBUG] 기기 {device.id} 전송 성공: {response}")
                success_count += 1

            except Exception as device_error:
                print(f"[ERROR] 기기 {device.id} 전송 실패: {device_error}")
                # 잘못된 토큰 비활성화
                if "not-registered" in str(device_error) or "invalid-registration-token" in str(device_error):
                    device.is_active = False
                    device.save()
                    print(f"[DEBUG] 기기 {device.id} 비활성화됨")

        return success_count > 0

    except Exception as e:
        print(f"[ERROR] FCM 전송 실패: {e}")
        return False