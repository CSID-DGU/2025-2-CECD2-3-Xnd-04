# fcm_services.py
# Firebase 초기화 + FCM 푸시 전송

import firebase_admin
from firebase_admin import credentials, messaging
from django.conf import settings
import os
from XndApp.Models.notification import Device


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
    """사용자의 모든 활성 기기에 푸시 알림 전송"""
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