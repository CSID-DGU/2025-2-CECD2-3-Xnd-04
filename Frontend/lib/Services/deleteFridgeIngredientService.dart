import 'package:dio/dio.dart';
import 'package:Frontend/Services/authService.dart';

/// 냉장고 식재료 삭제 API
Future<bool> deleteFridgeIngredient({
  required int fridgeId,
  required int ingredientId,
}) async {
  final dio = createAuthDio(); // 401 에러 자동 처리를 위한 인증 Dio 사용

  final String deleteURL = await buildApiUrl('/api/fridge/$fridgeId/ingredients/$ingredientId/');

  try {
    final response = await dio.delete(
      deleteURL,
      options: Options(
        headers: {
          'Authorization': 'Bearer $responsedAccessToken',
          'Content-Type': 'application/json',
        },
      ),
    );

    // 204 No Content 또는 200 OK 응답이면 성공
    if (response.statusCode == 204 || response.statusCode == 200) {
      print('식재료 삭제 성공: Ingredient ID $ingredientId');
      return true;
    }

    return false;
  } catch (e) {
    print('식재료 삭제 실패: $e');
    return false;
  }
}
