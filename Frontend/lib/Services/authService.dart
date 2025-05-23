import 'package:dio/dio.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'dart:io';

// 디버깅용, 실제 코드에서는 삭제, 노트북 Wifi 상에서만 구동 가능
// 호스팅 기기를 안드로이드 애뮬레이터로 설정

String? responsedAccessToken;

Future<bool> sendKakaoAccessToken(String accessToken) async {
  final dio = Dio();
  final ip = await NetworkInfo().getWifiIP().toString();
  final String authURL = (ip.startsWith('10.0.2')) ?
  'http://10.0.2.2:8000/api/auth/kakao-login/' :
  'http://192.168.119.150:8000/api/auth/kakao-login/' ;
  try {
    final response = await dio.post(
      authURL, // 👉 백엔드 API 주소
      data: {
        'access_token': accessToken,
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    print('로그인 성공 ✅');
    print('Access Token: ${response.data['access']}');
    print('Refresh Token: ${response.data['refresh']}');
    print('Status: ${response.statusCode}');
    return true;

  } catch (e) {
    print('로그인 실패 ❌, 에러 로그: ${e}');
    if (e is DioError) {
      print('Status: ${e.response?.statusCode}');
      print('Message: ${e.response?.data}');
    } else {
      print(e.toString());
    }
    return false;
  }
}
