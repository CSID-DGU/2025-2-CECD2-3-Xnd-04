import 'package:Frontend/Models/RefrigeratorModel.dart';
import 'package:dio/dio.dart';
import 'package:Frontend/Services/authService.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:Frontend/Views/HomeView.dart';
import 'package:Frontend/Models/RefrigeratorModel.dart';

bool programStarts = true;

// 모든 서비스는 함수로 관리함. 클래스 만들기 ㄱㅊ
Future<Response?> requestFridge() async {
  final dio = Dio();
  final String? ip = await NetworkInfo().getWifiIP();

  final String fridgeURL = (ip!.startsWith('10.0.2')) ?
  'http://10.0.2.2:8000/api/fridge/' :
  'http://' + HOST! + APIURLS['loadFridge']!;

  try {
    final response = await dio.get(
      fridgeURL,
      options: Options(
        headers: {
          'Authorization': 'Bearer ' + responsedAccessToken!,
          'Content-Type': 'application/json',
        },
      ),
    );
    return response;
  } catch (e) {
    print('에러 로그 냉장고 요청 실패 ❌: $e');
    return null;
  }
}

Future<bool> getFridgesInfo() async {
  final response = await requestFridge();

  if (response == null) return false;

  numOfFridge = response.data['fridge_count'];
  List<dynamic>? fridgeResponses = response.data['fridges'];
  List<dynamic>? ids = response.data['fridge_id'];

  if (programStarts) {
    for (int i = 0; i < numOfFridge!; i++) {
      Fridges.add(
        RefrigeratorModel(
          id: ids![i],
          level: fridgeResponses![i]['layer_count'],
          label: fridgeResponses[i]['model_label'],
        ),
      );
    }
    programStarts = false;
    if (numOfFridge == 0)
      return false;
    return true;
  }
  else {
    Fridges.add(
      RefrigeratorModel()
    );

    for(int i = numOfFridge! - 2; i > -1; i--)
      Fridges[i + 1] = Fridges[i];

    Fridges[0] = RefrigeratorModel(
      id: ids![0],
      level: fridgeResponses![0]['layer_count'],
      label: fridgeResponses[0]['model_label'],
    );
    return true;
  }
}
