import 'package:Frontend/Models/RecipeModel.dart';
import 'package:dio/dio.dart';
import 'package:Frontend/Services/authService.dart';
import 'package:network_info_plus/network_info_plus.dart';

/// 레시피 로드 여부 반환 in getRecipeInfo

// 통신용 함수
Future<Response?> requestRecipe() async {
  final dio = createAuthDio(); // 401 에러 자동 처리를 위한 인증 Dio 사용
  final String? ip = await NetworkInfo().getWifiIP();

  final String recipeURL = (ip!.startsWith('10.0.2')) ?
  'http://10.0.2.2:8000/api/recipes/' :
  'http://$HOST/${APIURLS['loadRecipe']}';
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

///Recipes = await getRecipeInfoFromServer();
Future<List<List<dynamic>?>?> getRecipeInfoFromServer() async {
  Response<dynamic>? response = await requestRecipe();
  List<int> recipe_id = [];
  List<dynamic> food_names = [];
  List<dynamic> recipe_image_urls = [];
  List<dynamic> is_saved = [];
  List<dynamic> cooking_times = [];
  List<dynamic> serving_sizes = [];
  List<dynamic> cooking_levels = [];
  List<dynamic> category2s = [];
  List<dynamic> category3s = [];
  List<dynamic> category4s = [];

  List<List<dynamic>?> li = [
    recipe_id,        // 0
    food_names,       // 1
    recipe_image_urls,// 2
    is_saved,         // 3
    cooking_times,    // 4
    serving_sizes,    // 5
    cooking_levels,   // 6
    category2s,       // 7
    category3s,       // 8
    category4s        // 9
  ];

  List<dynamic>? results;
  // 일단 응답이 있는 상황에선 이미지나 이름이 누락됬을지라도 추가하는 방향으로
  if (response != null) {
    print('레시피 로드를 진행합니다...');
    results = response.data['results'];
    if (results != null) {
      for (int i = 0; i < results.length; i++) {
        li[0]!.add(results[i]['recipe_id']);
        li[1]!.add(results[i]['food_name']);
        li[2]!.add(results[i]['recipe_image']);
        li[3]!.add(results[i]['is_saved']);
        li[4]!.add(results[i]['cooking_time'] ?? '50분');
        li[5]!.add(results[i]['serving_size'] ?? '4인분');
        li[6]!.add(results[i]['cooking_level'] ?? '쉬움');
        li[7]!.add(results[i]['category2'] ?? '');
        li[8]!.add(results[i]['category3'] ?? '');
        li[9]!.add(results[i]['category4'] ?? '');
      }
    }
  }
  return li;
}