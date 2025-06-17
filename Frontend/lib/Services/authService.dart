import 'package:dio/dio.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
