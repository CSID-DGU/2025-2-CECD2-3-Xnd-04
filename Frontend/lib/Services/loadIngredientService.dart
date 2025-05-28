import 'package:Frontend/Models/RefrigeratorModel.dart';
import 'package:dio/dio.dart';
import 'package:Frontend/Services/authService.dart';
import 'package:Frontend/Services/loadRecipeService.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:Frontend/Models/RecipeModel.dart';
import '../Models/IngredientModel.dart';

/// 레시피 URL로 요청 보낼 시 오는 정보 에서 id, 이름, url만 선별하여 저장
List<dynamic>? recipeDetailUrlResponseResults;

/// 레시피, 즐겨찾기 페이지의 버튼 클릭 시 얻어야 할 정보 요청
// 특정 레시피!! 에 대한 식재료 정보를 로드
Future<Response?> requestIngredient(RecipeModel recipe) async{
  final dio = Dio();
  final String? ip = await NetworkInfo().getWifiIP();

  final String recipeDetailURL = (ip!.startsWith('10.0.2')) ?
  'http://10.0.2.2:8000/api/recipes/' + '${recipe.id}/':
  'http://' + HOST! + APIURLS['loadRecipe']! + '${recipe.id}/';
  try {
    final response = await dio.get(
      recipeDetailURL, // 👉 백엔드 API 주소
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
/// 날아오는 정보 : ???,
/// ???,
/// ???,
/// ???,

///ID 기반 탐색, 레시피 이름이 적힌 버튼을 클릭하면 레시피의 id값을 활용해서 그곳에 저장된 식재료를 로드,
///한 번 로드된 레시피는 이후에 다시 로드되지 않음
Future<int> getIngredientInfoFromServer(RecipeModel recipe) async {
  Response<dynamic>? response = await requestIngredient(recipe);
  try {
    List<List<dynamic>?>? li = RecipeInfo;
    int recipeIdx = 0;

    if (li!.length < 4) {
      li.add([]);
      li.add([]);
      for (int idx = 0; idx < 10; idx++){
        li[3]!.add(null);
      }
      for (int idx = 0; idx < 10; idx++){
        li[4]!.add(null);
      }
    }

    for (int idx = 0; idx < 10; idx++){
      if(li[0]![idx] == recipe.id) {
        recipeIdx = idx;
        li[3]![recipeIdx] = response!.data['ingredients'];
        // li[4]![recipeIdx] = response!.data['steps'];
        break;
      }
    }
    return recipeIdx;
  }
  catch(e){
    print('에러 로그 : ${e}');
    return -1;
  }
}