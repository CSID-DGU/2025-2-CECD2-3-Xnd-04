import 'package:dio/dio.dart';
import 'package:Frontend/Services/authService.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:Frontend/Models/RecipeModel.dart';

/// query : included in xndapp_recipes.recipeName
Future<Response?> requestRecipeQuery({required String query}) async {
  final dio = createAuthDio(); // 401 에러 자동 처리를 위한 인증 Dio 사용
  final String? ip = await NetworkInfo().getWifiIP();

  final String recipeURL = (ip!.startsWith('10.0.2')) ?
  'http://10.0.2.2:8000/api/recipes/?query=${query}' :
  'http://$HOST/${APIURLS['loadRecipe']}?query=${query}';
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

/// query : included in xndapp_recipes.recipeName
Future<Response?> requestRecipeKeyword({required String keyword}) async {
  final dio = createAuthDio(); // 401 에러 자동 처리를 위한 인증 Dio 사용
  final String? ip = await NetworkInfo().getWifiIP();
  // 해시태그 정규화
  keyword = keyword.replaceFirst('#', '');

  final String recipeURL = (ip!.startsWith('10.0.2')) ?
  'http://10.0.2.2:8000/api/recipes/?keyword=${keyword}' :
  'http://' + HOST! + APIURLS['loadRecipe']! + '?keyword=${keyword}';
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

///Recipes = await getRecipeQueryInfoFromServer();
Future<List<List<dynamic>?>?> getRecipeQueryInfoFromServer({required String query}) async {
  query = query.trimLeft();
  Response<dynamic>? response = (query[0] == '#') ? await requestRecipeKeyword(keyword: query): await requestRecipeQuery(query:query);
  // 띄워줄 레시피의 수는 최대 10개
  int count = (response!.data['count'] < 10) ? response.data['count'] : 10;

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

  List<List<dynamic>?> li = [recipe_id, food_names, recipe_image_urls, is_saved, cooking_times, serving_sizes, cooking_levels, category2s, category3s, category4s];

  List<dynamic>? recipeResponse;
  // 일단 응답이 있는 상황에선 이미지나 이름이 누락됬을지라도 추가하는 방향으로
  if (response != null) {
    print('레시피 로드를 진행합니다... 쿼리레시피');
    recipeResponse = response.data['results'];
    if (recipeResponse != null) {
      for (int i = 0; i < count; i++) {
        li[0]!.add(recipeResponse[i]['recipe_id']);
        li[1]!.add(recipeResponse[i]['food_name']);
        li[2]!.add(recipeResponse[i]['recipe_image']);
        li[3]!.add(recipeResponse[i]['is_saved']);
        li[4]!.add(recipeResponse[i]['cooking_time']);
        li[5]!.add(recipeResponse[i]['serving_size']);
        li[6]!.add(recipeResponse[i]['cooking_level']);
        li[7]!.add(recipeResponse[i]['category2']);
        li[8]!.add(recipeResponse[i]['category3']);
        li[9]!.add(recipeResponse[i]['category4']);
      }
    }
  }
  return li;
}

///Recipes = await getSavedRecipeQueryInfoFromServer(); 즐겨찾기는 키워드 기반 검색 적용 X
Future<List<List<dynamic>?>?> getSavedRecipeQueryInfoFromServer({required String query}) async {
  Response<dynamic>? response = await requestRecipeQuery(query:query);
  // 띄워줄 레시피의 수는 최대 10개
  int count = (response!.data['count'] < 10) ? response.data['count'] : 10;

  List<int> recipe_id = [];
  List<dynamic> food_names = [];
  List<dynamic> recipe_image_urls = [];
  List<dynamic> is_saved = [];

  List<List<dynamic>?> li = [recipe_id, food_names, recipe_image_urls, is_saved];

  List<dynamic>? recipeResponse;
  // 일단 응답이 있는 상황에선 이미지나 이름이 누락됬을지라도 추가하는 방향으로
  if (response != null) {
    print('레시피 로드를 진행합니다... 쿼리레시피');
    recipeResponse = response.data['results'];
    if (recipeResponse != null) {
      for (int i = 0; i < count; i++) {
        if (recipeResponse[i]['is_saved']) {
          li[0]!.add(recipeResponse[i]['recipe_id']);
          li[1]!.add(recipeResponse[i]['food_name']);
          li[2]!.add(recipeResponse[i]['recipe_image']);
          li[3]!.add(recipeResponse[i]['is_saved']);
        }
      }
    }
  }
  return li;
}