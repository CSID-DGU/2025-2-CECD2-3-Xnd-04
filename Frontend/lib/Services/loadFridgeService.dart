import 'package:Frontend/Models/RefrigeratorModel.dart';
import 'package:dio/dio.dart';
import 'package:Frontend/Services/authService.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:Frontend/Views/HomeView.dart';

int? numOfFridge;
List<dynamic>? fridges;
List<dynamic>? ids;
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
  fridges = response.data['fridges'];
  ids = response.data['id'];

  if (numOfFridge == 0) return false;

  if (programStarts) {
    for (int i = 0; i < numOfFridge!; i++) {
      refrigerators.add(
        Refrigerator(
          id: ids![i],
          level: fridges![i]['layer_count'],
          label: fridges![i]['model_label'],
        ),
      );
      refrigerators[i].makeIngredientStorage();
    }
    programStarts = false;
  } else {
    refrigerators.add(
      Refrigerator(
        id: ids![numOfFridge! - 1],
        level: fridges![numOfFridge! - 1]['layer_count'],
        label: fridges![numOfFridge! - 1]['model_label'],
      ),
    );
  }
  return true;
}
