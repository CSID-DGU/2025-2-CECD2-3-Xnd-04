import 'package:Frontend/Models/RefrigeratorModel.dart';
import 'package:dio/dio.dart';
import 'package:Frontend/Services/authService.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:Frontend/Services/loadFridgeService.dart';

// 모든 서비스는 함수로 관리함. 클래스 만들기 ㄱㅊ
Future<bool> createFridgeToServer({required RefrigeratorModel refrigerator}) async {
  final dio = createAuthDio(); // 401 에러 자동 처리를 위한 인증 Dio 사용
  final String? ip = await NetworkInfo().getWifiIP();

  final String fridgeCreateURL = (ip!.startsWith('10.0.2')) ?
  'http://10.0.2.2:8000/api/fridge/create/' :
  'http://' + HOST! + APIURLS['createFridge']!;
  try {
    // 저장된 토큰 불러오기
    String? accessToken = responsedAccessToken;
    if (accessToken == null) {
      final tokens = await getSavedTokens();
      accessToken = tokens['access_token'];
      if (accessToken == null) {
        print('❌ 저장된 토큰이 없습니다. 다시 로그인해주세요.');
        return false;
      }
      responsedAccessToken = accessToken;
    }

    final response = await dio.post(
      fridgeCreateURL, // 👉 백엔드 API 주소
      data: refrigerator.toMap(),
      options: Options(
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      ),
    );
    print('응답 로그 : ${response.data}');
    numOfFridge = numOfFridge! + 1;
    return true;
  }
  catch(e){
    print('에러 로그 : $e');
    // 401 에러는 인터셉터에서 자동 처리됨
    return false;
  }
}