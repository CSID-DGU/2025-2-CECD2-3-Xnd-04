import 'package:Frontend/Models/IngredientModel.dart';
import 'package:dio/dio.dart';
import 'package:Frontend/Services/authService.dart';
import 'package:network_info_plus/network_info_plus.dart';

// 요청을 여러번 보내는 이유는 저장 냉장고 id에 대한 정보가 없기 때문
Future<Response?> requestRecipeModalIngredientInfo(int id, int fiid) async{
  final dio = Dio();
  final String? ip = await NetworkInfo().getWifiIP();

  final String ingredientDetailURL = (ip!.startsWith('10.0.2')) ?
  'http://10.0.2.2:8000/api/fridge/' + '${id}/' + 'ingredients/' + '${fiid}/':
  'http://' + HOST! + APIURLS['loadFridge']! + '${id}/' + 'ingredients/' + '${fiid}/';
  try {
    print('현재 인덱스 : ${id}');

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

/// 서버로부터 받은 응답을 통해 냉장고 객체에 식재료 정보 저장!! -> HomeView, NavBar[1]
Future<Map<String, dynamic>?> loadRecipeModalIngredientsInfo(int id, int fiid) async {
  Response<dynamic>? response = await requestRecipeModalIngredientInfo(id, fiid);

  if (response == null) return null;

  Map<String, dynamic> ingredientInfo = response.data;
  ingredientInfo.remove('id');
  ingredientInfo.remove('ingredient_name');
  ingredientInfo.remove('layer');

  return ingredientInfo;
}