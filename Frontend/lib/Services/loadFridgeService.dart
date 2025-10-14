import 'package:Frontend/Models/RefrigeratorModel.dart';
import 'package:dio/dio.dart';
import 'package:Frontend/Services/authService.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:Frontend/Views/HomeView.dart';
import 'package:Frontend/Models/RefrigeratorModel.dart';
import 'dart:convert';

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

  // 1. 서버에서 받은 데이터를 일단 dynamic 타입으로 받습니다.
  final dynamic fridgeCountData = response.data['fridge_count'];
  final List<dynamic>? fridgeResponses = response.data['fridges'];
  final List<dynamic>? ids = response.data['fridge_id'];

  // 2. 데이터가 유효한지 검사하면서, 동시에 타입을 int로 변환합니다.
  if (fridgeCountData is int && ids != null && fridgeResponses != null) {
    // 이 if 블록 안에서는 fridgeCountData가 확실히 int 타입임이 보장됩니다.
    numOfFridge = fridgeCountData; // ✅ 안전하게 할당

    if (programStarts) {
      for (int i = 0; i < numOfFridge!; i++) { // numOfFridge가 null일 수 있으므로 '!' 사용 유지
        Fridges.add(
          RefrigeratorModel(
            id: ids[i],
            level: fridgeResponses[i]['layer_count'],
            label: fridgeResponses[i]['model_label'],
          ),
        );
      }
      programStarts = false;
      if (numOfFridge == 0) return false;
      return true;
    } else {
      // (이하 로직은 동일)
      if (ids.isNotEmpty && fridgeResponses.isNotEmpty) {
        Fridges.add(RefrigeratorModel());
        for (int i = numOfFridge! - 2; i > -1; i--) {
          Fridges[i + 1] = Fridges[i];
        }
        Fridges[0] = RefrigeratorModel(
          id: ids[0],
          level: fridgeResponses[0]['layer_count'],
          label: fridgeResponses[0]['model_label'],
        );
        return true;
      }
    }
  }

  // 데이터가 유효하지 않은 경우
  return false;
}
