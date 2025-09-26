# fcm_services.py - 수정된 전체 코드
import firebase_admin
from firebase_admin import credentials, messaging
from django.conf import settings
import os

# 전역 변수
_firebase_initialized = False


def initialize_firebase():
    """Firebase 초기화 - JSON 파일 사용"""
    global _firebase_initialized

    if _firebase_initialized:
        print("[DEBUG] Firebase 이미 초기화됨")
        return True

    try:
        # 기존 앱들 삭제
        for app in firebase_admin._apps.copy():
            firebase_admin.delete_app(firebase_admin._apps[app])

        # JSON 파일 사용 (간단!)
        cred_path = os.path.join(settings.BASE_DIR, 'firebase-service-account.json')
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)

        _firebase_initialized = True
        print("[DEBUG] Firebase 초기화 성공 (JSON 파일)")
        return True

    except Exception as e:
        print(f"[ERROR] Firebase 초기화 실패: {e}")
        return False

def send_push_notification(user, title, body):
    """새로운 FCM v1 API로 푸시 알림 전송"""

    # Firebase 초기화 확인
    print("[DEBUG] Firebase 초기화 시작...")
    if not initialize_firebase():
        print("[ERROR] Firebase 초기화 실패로 알림 전송 불가")
        return False

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

        # 각 기기별로 개별 전송
        for device in devices:
            try:
                message = messaging.Message(
                    notification=messaging.Notification(
                        title=title,
                        body=body,
                    ),
                    data={
                        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                        'sound': 'default'
                    },
                    token=device.fcm_token,
                    android=messaging.AndroidConfig(
                        notification=messaging.AndroidNotification(
                            sound='default',
                            channel_id='default'
                        )
                    ),
                    apns=messaging.APNSConfig(
                        payload=messaging.APNSPayload(
                            aps=messaging.Aps(sound='default')
                        )
                    )
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

        print(f"[DEBUG] 전송 결과: {success_count}/{devices.count()} 성공")
        return success_count > 0

    except Exception as e:
        print(f"[ERROR] FCM 전송 실패: {e}")
        return False