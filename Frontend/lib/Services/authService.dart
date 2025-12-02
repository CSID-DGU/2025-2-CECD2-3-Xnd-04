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
  'loadIngredient' : 'api/ingredients/',
  'loadCart' : 'api/cart/',
  'addCart' : 'api/cart/add/',
  'savedRecipe' : 'api/savedRecipe/',
};

// 🔥 네트워크 정보 안전하게 가져오기 (Release 빌드에서도 작동)
Future<bool> isEmulator() async {
  try {
    final String? ip = await NetworkInfo().getWifiIP();
    return ip != null && ip.startsWith('10.0.2');
  } catch (e) {
    // network_info_plus 플러그인 에러 발생 시 실제 기기로 간주
    print('⚠️ NetworkInfo 플러그인 오류 - 실제 기기로 판단');
    return false;
  }
}

// 🔥 URL 빌더 헬퍼 함수
Future<String> buildApiUrl(String path, {String port = ':8000'}) async {
  final bool emulator = await isEmulator();

  if (emulator) {
    return 'http://10.0.2.2$port$path';
  } else {
    // HOST 끝의 슬래시와 path 시작의 슬래시 중복 제거
    String baseUrl = HOST!.endsWith('/') ? HOST!.substring(0, HOST!.length - 1) : HOST!;
    String cleanPath = path.startsWith('/') ? path : '/$path';
    return baseUrl + cleanPath;
  }
}

Future<bool> sendKakaoAccessToken(String accessToken) async {
  final dio = Dio();
  // final String? ip = await NetworkInfo().getWifiIP();
  // final String authURL = (ip!.startsWith('10.0.2')) ?
  // 'http://10.0.2.2:8000/api/auth/kakao-login/' :
  // HOST! + APIURLS['kakaoLogin']!;
  final String authURL = HOST! + APIURLS['kakaoLogin']!;

  print('🔗 카카오 로그인 요청 URL: $authURL');
  // print('📡 IP 주소: $ip');
  print('🏠 HOST 값: $HOST');

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

// 인증이 필요한 API 호출용 Dio 인스턴스 생성
Dio createAuthDio() {
  final dio = Dio();

  // 인터셉터 추가 - 401 에러 자동 처리
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (DioException error, ErrorInterceptorHandler handler) async {
        if (error.response?.statusCode == 401) {
          // 401 에러 발생 시 세션 만료 처리
          print('⚠️ 401 에러 감지 - 세션이 만료되었습니다.');
          await handle401Error();

          // 에러를 계속 전파하지 않고 종료
          return handler.resolve(
            Response(
              requestOptions: error.requestOptions,
              statusCode: 401,
              data: {'error': 'Session expired'},
            ),
          );
        }
        // 401이 아닌 다른 에러는 그대로 전파
        return handler.next(error);
      },
    ),
  );

  return dio;
}

// 세션 유효성 검사 함수
Future<bool> checkSession() async {
  final tokens = await getSavedTokens();
  final accessToken = tokens['access_token'];

  if (accessToken == null || accessToken.isEmpty) {
    return false;
  }

  // 토큰이 있으면 간단한 API 호출로 유효성 검사
  try {
    final dio = Dio();
    final String fridgeURL = await buildApiUrl('/api/fridge/');

    final response = await dio.get(
      fridgeURL,
      options: Options(
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        validateStatus: (status) => status! < 500, // 500 미만은 에러로 처리하지 않음
      ),
    );

    if (response.statusCode == 401) {
      await handle401Error();
      return false;
    }

    // responsedAccessToken 전역 변수 업데이트
    responsedAccessToken = accessToken;
    return true;
  } catch (e) {
    print('세션 체크 실패: $e');
    return false;
  }
}
