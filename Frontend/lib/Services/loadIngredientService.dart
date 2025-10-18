import 'package:Frontend/Models/RefrigeratorModel.dart';
import 'package:dio/dio.dart';
import 'package:Frontend/Services/authService.dart';
import 'package:Frontend/Services/loadRecipeService.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:Frontend/Models/RecipeModel.dart';
import '../Models/IngredientModel.dart';

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
Future<int> getIngredientInfoFromServer(RecipeModel recipe, bool fromFavoritePage) async {
  Response<dynamic>? response = await requestIngredient(recipe);
  try {
    List<List<dynamic>?>? li = (fromFavoritePage) ? SavedRecipes : Recipes;
    List<dynamic> Ingredients = [];
    List<dynamic> Descriptions = [];
    
    String description = response!.data['steps'];

    Descriptions = postProcessing(description);

    int recipeIdx = 0;
    int len = response!.data['ingredients'].length;
    
    // 식재료 추가
    for (int iidx = 0; iidx < len; iidx++)
      Ingredients.add(IngredientModel().toIngredient(response, iidx));

    // 일치하는 레시피 찾기
    for (int idx = 0; idx < li![0]!.length; idx++){
      if(li[0]![idx] == recipe.id) {
        recipeIdx = idx;
        break;
      }
    }
    // 레시피 상세 정보 초기화 && 추가
    if (li.length < 12) {
      // 기본 필드가 10개이므로, 10, 11번 인덱스 추가
      while (li.length < 12) {
        li.add([]);
      }
      // 초기화 - 현재 레시피 개수만큼 null로 채우기
      int recipeCount = li[0]?.length ?? 0;
      for (int idx = 0; idx < recipeCount; idx++) {
        li[10]!.add(null);
        li[11]!.add(null);
      }
    }

    // 인덱스 범위 확인 후 추가
    if (recipeIdx < li[10]!.length) {
      li[10]![recipeIdx] = Ingredients;
      li[11]![recipeIdx] = Descriptions;
    } else {
      // 인덱스가 범위를 벗어나면 확장
      while (li[10]!.length <= recipeIdx) {
        li[10]!.add(null);
        li[11]!.add(null);
      }
      li[10]![recipeIdx] = Ingredients;
      li[11]![recipeIdx] = Descriptions;
    }

    return recipeIdx;
  }
  catch(e){
    print('에러 로그 : ${e}');
    return -1;
  }
}

List<dynamic> postProcessing(String description){
  List<dynamic> Descriptions = [];

  String postprocessed = description;
  postprocessed = postprocessed.replaceAll(RegExp(r'[\[\]\(\),]'), '');

  bool processing = false;
  String chunk = '';
  for(int i = 0; i < postprocessed.length; i++){
    if (postprocessed[i] == "'") {
      if (processing){
        processing = false;
        Descriptions.add(chunk);
        chunk = '';
      }
      else
        processing = true;
      continue;
    }
    if(processing)
      chunk += postprocessed[i];
    else
      continue;
  }
  return Descriptions;
}