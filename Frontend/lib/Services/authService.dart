import 'package:dio/dio.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Frontend/global_navigator.dart'; // 전역 네비게이션 키 import

// 디버깅용, 실제 코드에서는 삭제, 노트북 Wifi 상에서만 구동 가능
// 호스팅 기기를 안드로이드 애뮬레이터로 설정

String? responsedAccessToken;

// 핫스팟 IP 변경될 때마다 이 부분 수정하기
final HOST = dotenv.env['HOST'];

final APIURLS = {
  'kakaoLogin' : 'api/auth/kakao-login/',
  'naverLogin' : 'api/auth/naver-login/',
  'createFridge' : 'api/fridge/create/',
  'loadFridge' : 'api/fridge/',
  'loadRecipe' : 'api/recipes/',
  'loadIngredient' : 'api/ingredients',
  'loadCart' : 'api/cart/',
  'addCart' : 'api/cart/add/',
  'savedRecipe' : 'api/savedRecipe/',
};

Future<bool> sendKakaoAccessToken(String accessToken) async {
  final dio = Dio();
  final String? ip = await NetworkInfo().getWifiIP();
  final String authURL = (ip!.startsWith('10.0.2')) ?
  'http://10.0.2.2:8000/api/auth/kakao-login/' :
  'http://' + HOST! + APIURLS['kakaoLogin']!;
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
    responsedAccessToken = response.data['access'];
    print('Access Token: ${response.data['access']}');
    print('Refresh Token: ${response.data['refresh']}');
    print('Status: ${response.statusCode}');

    // 토큰을 로컬에 저장
    await saveTokens(response.data['access'], response.data['refresh']);

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

// 토큰 저장 함수
Future<void> saveTokens(String accessToken, String refreshToken) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('access_token', accessToken);
  await prefs.setString('refresh_token', refreshToken);
  await prefs.setBool('is_logged_in', true);
  print('토큰 저장 완료');
}

// 저장된 토큰 가져오기
Future<Map<String, String?>> getSavedTokens() async {
  final prefs = await SharedPreferences.getInstance();
  return {
    'access_token': prefs.getString('access_token'),
    'refresh_token': prefs.getString('refresh_token'),
  };
}

// 로그인 상태 확인
Future<bool> isLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('is_logged_in') ?? false;
}

// 토큰 삭제 (로그아웃 시)
Future<void> clearTokens() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('access_token');
  await prefs.remove('refresh_token');
  await prefs.setBool('is_logged_in', false);
  responsedAccessToken = null;
  print('토큰 삭제 완료');
}

// 401 에러 처리 (토큰 만료 시)
Future<bool> handle401Error() async {
  print('⚠️ 401 인증 오류 - 토큰이 만료되었습니다.');
  await clearTokens();

  // 전역 네비게이션 키를 사용하여 로그인 페이지로 이동
  navigatorKey.currentState?.pushNamedAndRemoveUntil(
    '/login',
    (route) => false, // 모든 이전 라우트 제거
  );

  return true;
}
