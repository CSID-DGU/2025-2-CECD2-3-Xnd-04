import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:Frontend/Services/authService.dart';
import 'dart:io';

class FCMService {
  static FCMService? _instance;
  static FCMService get instance => _instance ??= FCMService._();
  FCMService._();

  String? _currentToken;

  // 로컬 알림 플러그인
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // FCM 초기화 (main.dart에서 한 번만 호출)
  static Future<void> initialize() async {
    await Firebase.initializeApp();
    await FCMService.instance._setupFCM();
  }

  // FCM 설정
  Future<void> _setupFCM() async {
    // 로컬 알림 초기화
    await _initializeLocalNotifications();

    // 권한 요청
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ 알림 권한 허용됨');

      // Android 알림 채널 생성
      if (Platform.isAndroid) {
        await _createNotificationChannel();
      }

      // 토큰 받기
      _currentToken = await FirebaseMessaging.instance.getToken();
      if (_currentToken != null) {
        print("🔥 FCM Token: $_currentToken");
      }

      // 토큰 갱신 리스너
      FirebaseMessaging.instance.onTokenRefresh.listen((String token) {
        print("🔄 Token refreshed: $token");
        _currentToken = token;
        registerDeviceToServer();
      });

      // 포그라운드 메시지 처리 (실제 알림 표시)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📱 포그라운드 메시지: ${message.notification?.title}');
        print('📱 메시지 내용: ${message.notification?.body}');

        // 포그라운드에서도 알림 표시
        _showLocalNotification(message);
      });

      // 백그라운드에서 앱을 탭해서 열었을 때
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('📱 백그라운드에서 앱 열림: ${message.notification?.title}');
      });

    } else {
      print('❌ 알림 권한 거부됨');
    }
  }

  // 로컬 알림 초기화
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);
  }

  // Android 알림 채널 생성
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'food_notification_channel', // 채널 ID
      '식품 알림', // 채널 이름
      description: '식품 유통기한 알림을 받습니다', // 채널 설명
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    print('✅ 알림 채널 생성 완료');
  }

  // 로컬 알림 표시
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'food_notification_channel',
      '식품 알림',
      channelDescription: '식품 유통기한 알림을 받습니다',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title ?? '알림',
      message.notification?.body ?? '',
      details,
    );

    print('🔔 로컬 알림 표시 완료');
  }

  // 서버에 기기 등록 (로그인 후 호출)
  Future<void> registerDeviceToServer() async {
    if (_currentToken == null) {
      print('❌ FCM 토큰이 없음');
      return;
    }

    // 저장된 토큰 불러오기
    String? accessToken = responsedAccessToken;
    if (accessToken == null) {
      final tokens = await getSavedTokens();
      accessToken = tokens['access_token'];
      if (accessToken == null) {
        print('❌ 저장된 인증 토큰이 없음');
        return;
      }
      responsedAccessToken = accessToken;
    }

    try {
      final dio = Dio();
      final String? ip = await NetworkInfo().getWifiIP();

      final String deviceURL = (ip!.startsWith('10.0.2')) ?
      'http://10.0.2.2:8000/api/devices/register/' :
      'http://$HOST' + 'api/devices/register/';

      final response = await dio.post(
        deviceURL,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
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

      // 401 에러 처리 (토큰 만료)
      if (e is DioException && e.response?.statusCode == 401) {
        await handle401Error();
      }
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