import 'dart:math';

import 'package:Frontend/Models/RecipeModel.dart';
import 'package:dio/dio.dart';
import 'package:Frontend/Services/authService.dart';
import 'package:network_info_plus/network_info_plus.dart';

/// 레시피 URL로 요청 보낼 시 오는 정보 에서 id, 이름, url만 선별하여 저장
List<dynamic>? recipeUrlResponseResults;

/// 레시피 로드 여부 반환 in getRecipeInfo
bool recipeLoaded = false;

// 통신용 함수
Future<Response?> requestRecipe() async {
  final dio = Dio();
  final String? ip = await NetworkInfo().getWifiIP();

  final String recipeURL = (ip!.startsWith('10.0.2')) ?
  'http://10.0.2.2:8000/api/recipes/' :
  'http://' + HOST! + APIURLS['loadRecipe']!;
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

/// 날아오는 정보 : 레시피명,
/// 이미지,
/// 연관된 식재료들,
/// 레시피 step,

///Q. count랑 page가 날아오는 이유는? 추가적으로 serving_size, cooking_time, level, is_saved도 날아오는 이유
Future<List<List<dynamic>?>?> getRecipeInfoFromServer() async {
  Response<dynamic>? response = await requestRecipe();
  List<int> recipe_id = [];
  List<dynamic> food_names = [];
  List<dynamic> recipe_image_urls = [];

  List<List<dynamic>?> li = [recipe_id, food_names, recipe_image_urls];
  // 일단 응답이 있는 상황에선 이미지나 이름이 누락됬을지라도 추가하는 방향으로
  if (response != null) {
    print('레시피 로드를 진행합니다...');
    recipeUrlResponseResults = response.data['results'];
    for (int i = 0; i < 10; i++) {
      li[0]!.add(recipeUrlResponseResults![i]['recipe_id']);
      li[1]!.add(recipeUrlResponseResults![i]['food_name']);
      li[2]!.add(recipeUrlResponseResults![i]['recipe_image']);
    }
    recipeLoaded = true;
  }
  return li;
}