# test_fcm.py
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'Xnd.settings')
django.setup()


def test_firebase_connection():
    print("=== Firebase 연결 테스트 ===")

    try:
        # settings.py에서 이미 Firebase가 초기화됨
        import firebase_admin
        from firebase_admin import messaging

        if firebase_admin._apps:
            print("✅ Firebase 초기화 성공!")

            # 더미 메시지 구조 테스트
            dummy_message = messaging.Message(
                notification=messaging.Notification(
                    title="테스트 알림",
                    body="Firebase 연동 테스트입니다"
                ),
                token="dummy_token_for_structure_test"
            )

            print("✅ 메시지 구조 생성 성공!")
            print(f"   제목: {dummy_message.notification.title}")
            print(f"   내용: {dummy_message.notification.body}")

            return True
        else:
            print("❌ Firebase 초기화 실패")
            return False

    except Exception as e:
        print(f"❌ 테스트 실패: {e}")
        return False


if __name__ == "__main__":
    success = test_firebase_connection()
    print(f"\n=== 테스트 결과: {'성공' if success else '실패'} ===")