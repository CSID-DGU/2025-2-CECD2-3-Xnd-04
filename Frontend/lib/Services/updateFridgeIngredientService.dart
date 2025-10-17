import 'package:dio/dio.dart';
import 'package:Frontend/Services/authService.dart';
import 'package:network_info_plus/network_info_plus.dart';

/// 식재료 정보 수정 API
Future<bool> updateFridgeIngredient({
  required int fridgeId,
  required int ingredientId,
  String? ingredientName,
  String? storableDue,
  String? memo,
}) async {
  final dio = Dio();
  final String? ip = await NetworkInfo().getWifiIP();

  final String updateURL = (ip!.startsWith('10.0.2'))
      ? 'http://10.0.2.2:8000/api/fridge/$fridgeId/ingredients/$ingredientId/'
      : 'http://$HOST/api/fridge/$fridgeId/ingredients/$ingredientId/';

  try {
    Map<String, dynamic> data = {};
    if (ingredientName != null) data['ingredient_name'] = ingredientName;
    if (storableDue != null) data['storable_due'] = storableDue;
    if (memo != null) data['memo'] = memo;

    final response = await dio.patch(
      updateURL,
      data: data,
      options: Options(
        headers: {
          'Authorization': 'Bearer $responsedAccessToken',
          'Content-Type': 'application/json',
        },
      ),
    );

    return response.statusCode == 200;
  } catch (e) {
    print('식재료 수정 API 에러: $e');
    return false;
  }
}
