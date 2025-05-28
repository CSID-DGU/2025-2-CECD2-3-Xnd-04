import 'dart:math';

import 'package:Frontend/Models/RecipeModel.dart';
import 'package:dio/dio.dart';
import 'package:Frontend/Services/authService.dart';
import 'package:network_info_plus/network_info_plus.dart';

// 따올 정보 네비게이션 바 클릭 -> 레시피 이미지, 레시피 이름, 관련된 식재료 정보
// 레시피 클릭 시 레시피 몇개를 보내는가? 210개 다 보냄(왠진 모르겠는데 나주엥 추릴듯)
//results[{}, {}, {}]... recipe_image, food_name,
List<dynamic>? results;
bool recipeLoaded = false;
// 이 때 상세 식재료도 같이 따올지 X -> 버튼 클릭하믄 ㄱㄱ

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

Future<List<List<dynamic>?>?> getRecipeInfo() async {
  Response<dynamic>? response = await requestRecipe();
  List<dynamic> food_names = [];
  List<dynamic> recipe_image_urls = [];

  List<List<dynamic>?> li = [food_names, recipe_image_urls];
  // 일단 응답이 있는 상황에선 이미지나 이름이 누락됬을지라도 추가하는 방향으로
  if (response != null) {
    print('레시피 로드를 진행합니다...');
    results = response.data['results'];
    for (int i = 0; i < 10; i++) {
      li[0]!.add(results![i]['food_name']);
      li[1]!.add(results![i]['recipe_image']);
    }
    recipeLoaded = true;
  }
  return li;
}