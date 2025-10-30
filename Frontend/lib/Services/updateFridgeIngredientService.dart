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
  int? layer,
  String? storageLocation,
}) async {
  final dio = createAuthDio(); // 401 에러 자동 처리를 위한 인증 Dio 사용
  final String? ip = await NetworkInfo().getWifiIP();

  final String updateURL = (ip!.startsWith('10.0.2'))
      ? 'http://10.0.2.2:8000/api/fridge/$fridgeId/ingredients/$ingredientId/'
      : 'http://$HOST/api/fridge/$fridgeId/ingredients/$ingredientId/';

  try {
    Map<String, dynamic> data = {};
    if (ingredientName != null) data['ingredient_name'] = ingredientName;
    if (storableDue != null) data['storable_due'] = storableDue;
    if (memo != null) data['memo'] = memo;
    if (layer != null) data['layer'] = layer;
    if (storageLocation != null) data['storage_location'] = storageLocation;

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
