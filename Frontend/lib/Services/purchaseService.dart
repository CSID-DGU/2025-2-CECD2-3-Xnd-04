import 'package:dio/dio.dart';
import 'package:Frontend/Services/authService.dart';
import 'package:network_info_plus/network_info_plus.dart';

/// 구매 내역 조회
Future<Map<String, dynamic>?> getPurchaseHistory({int? year, int? month}) async {
  final dio = createAuthDio();
  final String? ip = await NetworkInfo().getWifiIP();

  // 현재 날짜 기본값
  final now = DateTime.now();
  final queryYear = year ?? now.year;
  final queryMonth = month ?? now.month;

  final String url = (ip!.startsWith('10.0.2'))
      ? 'http://10.0.2.2:8000/api/purchases/?year=$queryYear&month=$queryMonth'
      : 'http://$HOST/api/purchases/?year=$queryYear&month=$queryMonth';

  try {
    final response = await dio.get(
      url,
      options: Options(
        headers: {
          'Authorization': 'Bearer $responsedAccessToken',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      print('구매 내역 조회 성공: ${response.data}');
      return response.data;
    }
    return null;
  } catch (e) {
    print('구매 내역 조회 실패: $e');
    return null;
  }
}

/// 장바구니 -> 장보기 일정 추가
Future<Map<String, dynamic>?> addToShoppingList({
  required List<int> cartIds,
  String? shoppingDate,
}) async {
  final dio = createAuthDio();
  final String? ip = await NetworkInfo().getWifiIP();

  final String url = (ip!.startsWith('10.0.2'))
      ? 'http://10.0.2.2:8000/api/purchases/create/'
      : 'http://$HOST/api/purchases/create/';

  try {
    final Map<String, dynamic> requestData = {'cart_ids': cartIds};
    if (shoppingDate != null) {
      requestData['shopping_date'] = shoppingDate;
    }

    final response = await dio.post(
      url,
      data: requestData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $responsedAccessToken',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 201) {
      print('장보기 일정 추가 성공: ${response.data}');
      return response.data;
    }
    return null;
  } catch (e) {
    print('장보기 일정 추가 실패: $e');
    return null;
  }
}

/// 장보기 완료 처리
Future<Map<String, dynamic>?> completeShopping({
  required List<Map<String, int>> purchases,
}) async {
  final dio = createAuthDio();
  final String? ip = await NetworkInfo().getWifiIP();

  final String url = (ip!.startsWith('10.0.2'))
      ? 'http://10.0.2.2:8000/api/purchases/complete/'
      : 'http://$HOST/api/purchases/complete/';

  try {
    final response = await dio.patch(
      url,
      data: {'purchases': purchases},
      options: Options(
        headers: {
          'Authorization': 'Bearer $responsedAccessToken',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      print('장보기 완료 성공: ${response.data}');
      return response.data;
    }
    return null;
  } catch (e) {
    print('장보기 완료 실패: $e');
    return null;
  }
}

/// 장보기 일정 조회 (미완료)
Future<Map<String, dynamic>?> getPendingPurchases({String? date}) async {
  final dio = createAuthDio();
  final String? ip = await NetworkInfo().getWifiIP();

  String url = (ip!.startsWith('10.0.2'))
      ? 'http://10.0.2.2:8000/api/purchases/pending/'
      : 'http://$HOST/api/purchases/pending/';

  if (date != null) {
    url += '?date=$date';
  }

  try {
    final response = await dio.get(
      url,
      options: Options(
        headers: {
          'Authorization': 'Bearer $responsedAccessToken',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      print('장보기 일정 조회 성공: ${response.data}');
      return response.data;
    }
    return null;
  } catch (e) {
    print('장보기 일정 조회 실패: $e');
    return null;
  }
}

/// 구매 내역 삭제
Future<bool> deletePurchase({required int purchaseId}) async {
  final dio = createAuthDio();
  final String? ip = await NetworkInfo().getWifiIP();

  final String url = (ip!.startsWith('10.0.2'))
      ? 'http://10.0.2.2:8000/api/purchases/$purchaseId/'
      : 'http://$HOST/api/purchases/$purchaseId/';

  try {
    final response = await dio.delete(
      url,
      options: Options(
        headers: {
          'Authorization': 'Bearer $responsedAccessToken',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      print('구매 내역 삭제 성공');
      return true;
    }
    return false;
  } catch (e) {
    print('구매 내역 삭제 실패: $e');
    return false;
  }
}
