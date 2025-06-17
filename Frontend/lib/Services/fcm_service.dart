// fcm_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:Frontend/Services/authService.dart';

class FCMService {
  static FCMService? _instance;
  static FCMService get instance => _instance ??= FCMService._();
  FCMService._();

  String? _currentToken;

  // FCM 초기화 (main.dart에서 한 번만 호출)
  static Future<void> initialize() async {
    await Firebase.initializeApp();
    await FCMService.instance._setupFCM();
  }

  // FCM 설정
  Future<void> _setupFCM() async {
    // 권한 요청
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ 알림 권한 허용됨');

      // 토큰 받기
      _currentToken = await FirebaseMessaging.instance.getToken();
      if (_currentToken != null) {
        print("🔥 FCM Token: $_currentToken");
      }

      // 토큰 갱신 리스너
      FirebaseMessaging.instance.onTokenRefresh.listen((String token) {
        print("🔄 Token refreshed: $token");
        _currentToken = token;
        // 토큰이 갱신되면 자동으로 서버에 업데이트
        registerDeviceToServer();
      });

      // 포그라운드 메시지 처리
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📱 포그라운드 메시지: ${message.notification?.title}');
        print('📱 메시지 내용: ${message.notification?.body}');
        // 여기서 앱 내 알림 UI 표시 가능
      });

      // 백그라운드에서 앱을 탭해서 열었을 때
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('📱 백그라운드에서 앱 열림: ${message.notification?.title}');
        // 여기서 특정 화면으로 이동 가능
      });

    } else {
      print('❌ 알림 권한 거부됨');
    }
  }

  // 서버에 기기 등록 (로그인 후 호출)
  Future<void> registerDeviceToServer() async {
    if (_currentToken == null) {
      print('❌ FCM 토큰이 없음');
      return;
    }

    if (responsedAccessToken == null) {
      print('❌ 인증 토큰이 없음');
      return;
    }

    try {
      final dio = Dio();
      final String? ip = await NetworkInfo().getWifiIP();

      final String deviceURL = (ip!.startsWith('10.0.2')) ?
        'http://10.0.2.2:8000/api/devices/register/' :
        'http://' + HOST! + '/api/devices/register/';

      final response = await dio.post(
        deviceURL,
        options: Options(
          headers: {
            'Authorization': 'Bearer ' + responsedAccessToken!,
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'fcm_token': _currentToken,
          'device_type': 'android',
          'device_name': 'Flutter Android Device',
        },
      );

      if (response.statusCode == 201) {
        print("✅ 장고 서버에 FCM 토큰 등록 성공");
        print("📱 서버 응답: ${response.data['message']}");
      } else {
        print("❌ FCM 토큰 등록 실패: ${response.statusCode}");
        print("❌ 응답: ${response.data}");
      }
    } catch (e) {
      print("❌ 서버 연결 오류: $e");
    }
  }

  // 현재 FCM 토큰 가져오기 (디버깅용)
  String? getCurrentToken() {
    return _currentToken;
  }

  // 알림 설정 on/off (나중에 설정 화면에서 사용)
  Future<void> toggleNotification(bool isActive) async {
    if (_currentToken == null || responsedAccessToken == null) return;

    try {
      final dio = Dio();
      final String? ip = await NetworkInfo().getWifiIP();

      final String toggleURL = (ip!.startsWith('10.0.2')) ?
        'http://10.0.2.2:8000/api/devices/toggle/' :
        'http://' + HOST! + '/api/devices/toggle/';

      final response = await dio.patch(
        toggleURL,
        options: Options(
          headers: {
            'Authorization': 'Bearer ' + responsedAccessToken!,
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'fcm_token': _currentToken,
          'is_active': isActive,
        },
      );

      if (response.statusCode == 200) {
        print("✅ 알림 설정 변경: ${isActive ? '활성화' : '비활성화'}");
      }
    } catch (e) {
      print("❌ 알림 설정 변경 실패: $e");
    }
  }
}