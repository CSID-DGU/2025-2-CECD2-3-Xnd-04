import 'package:Frontend/Models/RefrigeratorModel.dart';
import 'package:dio/dio.dart';
import 'package:Frontend/Services/authService.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:Frontend/Views/HomeView.dart';

int? numOfFridge;
List<dynamic>? fridges;

// 모든 서비스는 함수로 관리함. 클래스 만들기 ㄱㅊ
Future<bool> checkFridgeNumAreNonZero() async {
  final dio = Dio();
  final String? ip = await NetworkInfo().getWifiIP();

  final String fridgeURL = (ip!.startsWith('10.0.2')) ?
  'http://10.0.2.2:8000/api/fridge/' :
  'http://' + HOST! + APIURLS['loadFridge']!;
  try {
    final response = await dio.get(
      fridgeURL, // 👉 백엔드 API 주소
      options: Options(
        headers: {
          'Authorization': 'Bearer ' + responsedAccessToken!,
          'Content-Type': 'application/json',
        },
      ),
    );
    numOfFridge = response.data['fridge_count'];
    fridges = response.data['fridges'];

    if (numOfFridge == 0)
      return false;
    else {
      // 프로그램을 실행시킬 때마다 DB에서 현재 저장된 냉장고 정보 로드
      for(int i = 0; i < numOfFridge!; i++){
        refrigerators.add(
          Refrigerator(
            number: i + 1,
            level: fridges![i]['layer_count'],
            label: fridges![i]['model_label'],
            modelName: 'R${i + 1}'
          )
        );
        refrigerators[i].makeIngredientStorage();
      }
    }
      return true;
  }

  catch(e){
    print('에러 로그 : ${e}');
    return false;
  }
}