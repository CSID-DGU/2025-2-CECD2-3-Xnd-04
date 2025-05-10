import 'package:dio/dio.dart';

// 호스팅 기기를 안드로이드 애뮬레이터로 설정
final String authURL = 'http://10.0.2.2:8000/api/auth/kakao-login/';

Future<bool> sendKakaoAccessToken(String accessToken) async {
  final dio = Dio();

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
