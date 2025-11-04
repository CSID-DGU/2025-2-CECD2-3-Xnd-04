import 'package:dio/dio.dart';
import 'package:Frontend/Services/authService.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../Models/RecipeModel.dart';

// 모든 서비스는 함수로 관리함. 클래스 만들기 ㄱㅊ
Future<bool> createSavedRecipe({required RecipeModel recipe}) async {
  final dio = createAuthDio(); // 401 에러 자동 처리를 위한 인증 Dio 사용
  final String? ip = await NetworkInfo().getWifiIP();

  final String createSavedRecipeURL = (ip!.startsWith('10.0.2')) ?
  'http://10.0.2.2:8000/api/savedRecipe/' :
  'http://' + HOST! + APIURLS['savedRecipe']!;
  try {
    final response = await dio.post(
      createSavedRecipeURL, // 👉 백엔드 API 주소
      data:{
        'recipe_id' : recipe.id
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer ' + responsedAccessToken!,
          'Content-Type': 'application/json',
        },
      ),
    );
    print('응답 로그 : ${response.data}');
    return true;
  }
  catch(e){
    print('에러 로그 : ${e}');
    return false;
  }
}