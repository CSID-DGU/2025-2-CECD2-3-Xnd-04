import 'package:Frontend/Models/IngredientModel.dart';
import 'package:Frontend/Models/RefrigeratorModel.dart';
import 'package:dio/dio.dart';
import 'package:Frontend/Services/authService.dart';
import 'package:network_info_plus/network_info_plus.dart';

/// 레시피 로드 여부 반환 in getRecipeInfo
bool fridgeIngredientLoaded = false;

Future<Response?> requestFridgeIngredientInfo(Refrigerator refrigerator) async{
  final dio = Dio();
  final String? ip = await NetworkInfo().getWifiIP();

  final String ingredientDetailURL = (ip!.startsWith('10.0.2')) ?
  'http://10.0.2.2:8000/api/fridge/' + '${refrigerator.id}/':
  'http://' + HOST! + APIURLS['loadFridge']! + '${refrigerator.id}/';
  try {
    final response = await dio.get(
      ingredientDetailURL, // 👉 백엔드 API 주소
      options: Options(
        headers: {
          'Authorization': 'Bearer ' + responsedAccessToken!,
          'Content-Type': 'application/json',
        },
      ),
    );
    return response;
  }
  catch(e) {
    print('에러 로그 식재료 요청 응답 실패: ${e}');
    return null;
  }
}

Future<bool> getFridgeIngredientInfoFromServer(Refrigerator refrigerator) async {
  Response<dynamic>? response = await requestFridgeIngredientInfo(refrigerator);
  print(response!.data);

  fridgeIngredientLoaded = true;
  return true;
}