import 'package:Frontend/Models/IngredientModel.dart';
import 'package:Frontend/Models/RefrigeratorModel.dart';
import 'package:dio/dio.dart';
import 'package:Frontend/Services/authService.dart';
import 'package:network_info_plus/network_info_plus.dart';

Future<Response?> requestFridgeIngredientInfo(RefrigeratorModel refrigerator) async{
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

/// 서버로부터 받은 응답을 통해 냉장고 객체에 식재료 정보 저장!! -> HomeView, NavBar[1]
Future<bool> loadFridgeIngredientsInfo(RefrigeratorModel refrigerator, int idx) async {
  Response<dynamic>? response = await requestFridgeIngredientInfo(refrigerator);

  if (response == null) {
    return false;
  }

  List<dynamic> ingredientsInfo = response.data['ingredients'];
  List<FridgeIngredientModel> ingredients = [];

  for (int i = 0; i < ingredientsInfo.length; i++){
    var ingredient = FridgeIngredientModel()
        .toIngredient(response, i)
        .toFridgeIngredient(response, i);
    ingredients.add(ingredient);
  }

  refrigerator.setIngredientStorage(ingredients);
  refrigerator.toMainFridgeIngredientsInfo(idx);

  return true;
}

/// 냉장고 식재료 ID를 구하는 과정
Future<int> getFIID(RefrigeratorModel refrigerator, IngredientModel ingredient) async {
  Response<dynamic>? response = await requestFridgeIngredientInfo(refrigerator);

  if (response == null) return -1;

  List<dynamic> ingredientsInfo = response.data['ingredients'];

  for(int i = 0; i < ingredientsInfo.length; i++){
    if(ingredientsInfo[i]['ingredient_name'] == ingredient.ingredientName)
      return ingredientsInfo[i]['id'];
  }

  return 0;
}