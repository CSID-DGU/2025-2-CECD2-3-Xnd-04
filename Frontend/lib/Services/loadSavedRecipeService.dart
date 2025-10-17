import 'package:dio/dio.dart';
import 'package:Frontend/Services/authService.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../Models/RecipeModel.dart';

// 모든 서비스는 함수로 관리함. 클래스 만들기 ㄱㅊ
Future<Response?> requestSavedRecipesFromServer() async {
  final dio = Dio();
  final String? ip = await NetworkInfo().getWifiIP();

  final String createSavedRecipeURL = (ip!.startsWith('10.0.2')) ?
  'http://10.0.2.2:8000/api/savedRecipe/' :
  'http://' + HOST! + APIURLS['savedRecipe']!;
  try {
    final response = await dio.get(
      createSavedRecipeURL, // 👉 백엔드 API 주소
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
    print('에러 로그 : ${e}');
    return null;
  }
}

Future<List<List<dynamic>?>?> getSavedRecipesFromServer() async {
  Response<dynamic>? response = await requestSavedRecipesFromServer();
  List<List<dynamic>> li = [[], [], [], [], [], [], [], [], [], [], [], []];

  if (response == null) return li;

  List<dynamic>? data;

  data = response.data;

  if (data != null) {
    print('저장된 레시피 로드를 진행합니다...');
    for(int i = 0; i < data.length; i++){
      li[0].add(data[i]['recipe_id']);
      li[1].add(data[i]['food_name']);
      li[2].add(data[i]['recipe_image']);
      li[3].add(data[i]['is_saved']);
      li[4].add(data[i]['cooking_time']);
      li[5].add(data[i]['serving_size']);
      li[6].add(data[i]['cooking_level']);
      li[7].add(data[i]['category2']);
      li[8].add(data[i]['category3']);
      li[9].add(data[i]['category4']);
    }

    print('객체 ${li}');
  }

  return li;
}