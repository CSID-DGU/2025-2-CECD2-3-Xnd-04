import 'package:Frontend/Models/IngredientModel.dart';
import 'package:Frontend/Models/RecipeModel.dart';
import 'package:dio/dio.dart';
import 'package:Frontend/Services/authService.dart';
import 'package:network_info_plus/network_info_plus.dart';

// 통신용 함수
Future<Response?> requestDetailRecipe(IngredientModel ingredient) async {
  final dio = Dio();
  final String? ip = await NetworkInfo().getWifiIP();

  final String recipeURL = (ip!.startsWith('10.0.2')) ?
  'http://10.0.2.2:8000/api/recipes/?ingredient=${ingredient.ingredientName}' :
  'http://' + HOST! + APIURLS['loadRecipe']! + '/?ingredient=${ingredient.ingredientName}';
  try {
    final response = await dio.get(
      recipeURL, // 👉 백엔드 API 주소
      options: Options(
        headers: {
          'Authorization': 'Bearer ' + responsedAccessToken!,
          'Content-Type': 'application/json',
        },
      ),
    );
    return response;
  }
  catch(e){
    print('에러 로그 레시피 요청 응답 실패: ${e}');
    return null;
  }
}

/// 서버에서 받은 응답으로 객체를 추가해서 반환
Future <List<RecipeDetailModel>?> getRecipeDetailInfoFromServer(IngredientModel ingredient) async {
  final response = await requestDetailRecipe(ingredient);
  if (response == null) return null;

  List <RecipeDetailModel> recipes = [];
  int maxIndex = (response.data['count'] < 3) ? response.data['count'] - 1 : 2;
  for (int i = 0; i <= maxIndex; i++)
    recipes.add(RecipeDetailModel().toRecipeDetail(response, i));

  return recipes;
}