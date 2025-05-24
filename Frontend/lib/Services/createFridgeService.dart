import 'package:Frontend/Models/RefrigeratorModel.dart';
import 'package:dio/dio.dart';
import 'package:Frontend/Services/authService.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:Frontend/Services/loadFridgeService.dart';

// 모든 서비스는 함수로 관리함. 클래스 만들기 ㄱㅊ
Future<bool> createFridgeToServer({required Refrigerator refrigerator}) async {
  final dio = Dio();
  final String? ip = await NetworkInfo().getWifiIP();

  final String fridgeCreateURL = (ip!.startsWith('10.0.2')) ?
  'http://10.0.2.2:8000/api/fridge/create/' :
  'http://192.168.119.150:8000/api/fridge/create/';

  try {
    final response = await dio.post(
      fridgeCreateURL, // 👉 백엔드 API 주소
      data: refrigerator.toMap(),
      options: Options(
        headers: {
          'Authorization': 'Bearer ' + responsedAccessToken!,
          'Content-Type': 'application/json',
        },
      ),
    );
    print('응답 로그 : ${response.data}');
    numOfFridge = numOfFridge! + 1;
    return true;
  }
  catch(e){
    print('에러 로그 : ${e}');
    return false;
  }
}