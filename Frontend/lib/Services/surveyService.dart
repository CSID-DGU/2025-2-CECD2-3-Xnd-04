import 'package:dio/dio.dart';
import 'package:Frontend/Services/authService.dart';

/// 설문조사 결과 제출
Future<bool> submitSurvey(Map<String, dynamic> surveyData) async {
  final dio = createAuthDio(); // 401 에러 자동 처리를 위한 인증 Dio 사용
  final String surveyURL = await buildApiUrl('/api/survey/');

  try {
    final response = await dio.post(
      surveyURL,
      data: {
        'ingredients': surveyData['ingredients'],
        'favorite_recipe': surveyData['favoriteRecipe'],
        'serving_size': surveyData['servingSize'],
        'cooking_frequency': surveyData['cookingFrequency'],
        'dietary_restrictions': surveyData['dietaryRestrictions'],
        'skill_level': surveyData['skillLevel'],
        'cooking_equipment': surveyData['cookingEquipment'],
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer ' + responsedAccessToken!,
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      print('설문조사 결과가 저장되었습니다.');
      return true;
    }
    return false;
  } catch (e) {
    print('설문조사 제출 에러: $e');
    return false;
  }
}

/// 설문조사 결과 조회
Future<Map<String, dynamic>?> getSurveyResults() async {
  final dio = createAuthDio();
  final String surveyURL = await buildApiUrl('/api/survey/');

  try {
    final response = await dio.get(
      surveyURL,
      options: Options(
        headers: {
          'Authorization': 'Bearer ' + responsedAccessToken!,
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      return response.data;
    }
    return null;
  } catch (e) {
    print('설문조사 조회 에러: $e');
    return null;
  }
}
