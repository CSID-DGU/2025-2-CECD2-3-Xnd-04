import 'package:dio/dio.dart';
import 'package:Frontend/Services/authService.dart';
import 'package:intl/intl.dart';

// 장보기 목록에 추가 (캘린더에 추가)
Future<Map<String, dynamic>> addShoppingList({
  required List<int> cartItemIds,
  required DateTime shoppingDate,
}) async {
  try {
    final dio = createAuthDio();

    if (responsedAccessToken == null) {
      throw Exception('로그인이 필요합니다');
    }

    final String baseUrl = await buildApiUrl('', port: '');

    final dateString = DateFormat('yyyy-MM-dd').format(shoppingDate);

    final response = await dio.post(
      '$baseUrl/api/shopping-list/add/',
      data: {
        'cart_item_ids': cartItemIds,
        'shopping_date': dateString,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $responsedAccessToken',
          'Content-Type': 'application/json',
        },
      ),
    );

    return response.data;
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      throw Exception('세션이 만료되었습니다');
    }
    throw Exception(e.response?.data['error'] ?? '장보기 목록 추가 실패');
  }
}

// 특정 날짜의 장보기 목록 조회
Future<List<Map<String, dynamic>>> getShoppingList(DateTime date) async {
  try {
    final dio = createAuthDio();

    if (responsedAccessToken == null) {
      throw Exception('로그인이 필요합니다');
    }

    final String baseUrl = await buildApiUrl('', port: '');

    final dateString = DateFormat('yyyy-MM-dd').format(date);

    print('장보기 목록 조회 요청: $baseUrl/api/shopping-list/?date=$dateString');

    final response = await dio.get(
      '$baseUrl/api/shopping-list/',
      queryParameters: {'date': dateString},
      options: Options(
        headers: {
          'Authorization': 'Bearer $responsedAccessToken',
        },
      ),
    );

    print('장보기 목록 조회 응답: ${response.data}');

    List<Map<String, dynamic>> items = [];
    for (var item in response.data['items']) {
      items.add({
        'id': item['id'],
        'ingredient_id': item['ingredient_id'],
        'ingredient_name': item['ingredient_name'],
        'shopping_date': item['shopping_date'],
      });
    }

    return items;
  } on DioException catch (e) {
    print('장보기 목록 조회 DioException: ${e.response?.statusCode}');
    print('에러 데이터: ${e.response?.data}');
    print('에러 메시지: ${e.message}');

    if (e.response?.statusCode == 401) {
      throw Exception('세션이 만료되었습니다');
    }

    String errorMessage = '장보기 목록 조회 실패';
    if (e.response?.data != null && e.response?.data is Map && e.response?.data['error'] != null) {
      errorMessage = e.response?.data['error'];
    }
    throw Exception(errorMessage);
  } catch (e) {
    print('장보기 목록 조회 기타 에러: $e');
    throw Exception('장보기 목록 조회 실패: $e');
  }
}

// 장보기 완료 처리 (삭제 + 지출 추가)
Future<Map<String, dynamic>> completeShoppingList({
  required List<int> shoppingListIds,
  required Map<String, int> prices,
  required DateTime shoppingDate,
}) async {
  try {
    final dio = createAuthDio();

    if (responsedAccessToken == null) {
      throw Exception('로그인이 필요합니다');
    }

    final String baseUrl = await buildApiUrl('', port: '');

    final dateString = DateFormat('yyyy-MM-dd').format(shoppingDate);

    final response = await dio.post(
      '$baseUrl/api/shopping-list/complete/',
      data: {
        'shopping_list_ids': shoppingListIds,
        'prices': prices,
        'shopping_date': dateString,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $responsedAccessToken',
          'Content-Type': 'application/json',
        },
      ),
    );

    return response.data;
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      throw Exception('세션이 만료되었습니다');
    }
    throw Exception(e.response?.data['error'] ?? '장보기 완료 처리 실패');
  }
}

// 특정 날짜의 장보기 지출 조회
Future<int> getDailySpending(DateTime date) async {
  try {
    final dio = createAuthDio();

    if (responsedAccessToken == null) {
      throw Exception('로그인이 필요합니다');
    }

    final String baseUrl = await buildApiUrl('', port: '');

    final dateString = DateFormat('yyyy-MM-dd').format(date);

    final response = await dio.get(
      '$baseUrl/api/shopping-list/daily-spending/',
      queryParameters: {'date': dateString},
      options: Options(
        headers: {
          'Authorization': 'Bearer $responsedAccessToken',
        },
      ),
    );

    return response.data['total_spending'] ?? 0;
  } on DioException catch (e) {
    print('날짜별 지출 조회 DioException: ${e.response?.statusCode}');
    if (e.response?.statusCode == 401) {
      throw Exception('세션이 만료되었습니다');
    }
    return 0; // 에러 발생 시 0 반환
  } catch (e) {
    print('날짜별 지출 조회 에러: $e');
    return 0;
  }
}

// 월별 날짜별 장보기 지출 조회 (캘린더용)
Future<Map<String, int>> getMonthlySpending(int year, int month) async {
  try {
    final dio = createAuthDio();

    if (responsedAccessToken == null) {
      throw Exception('로그인이 필요합니다');
    }

    final String baseUrl = await buildApiUrl('', port: '');

    final response = await dio.get(
      '$baseUrl/api/shopping-list/monthly-spending/',
      queryParameters: {'year': year.toString(), 'month': month.toString()},
      options: Options(
        headers: {
          'Authorization': 'Bearer $responsedAccessToken',
        },
      ),
    );

    Map<String, int> dailySpending = {};
    if (response.data['daily_spending'] != null) {
      (response.data['daily_spending'] as Map<String, dynamic>).forEach((key, value) {
        dailySpending[key] = value as int;
      });
    }

    return dailySpending;
  } on DioException catch (e) {
    print('월별 지출 조회 DioException: ${e.response?.statusCode}');
    if (e.response?.statusCode == 401) {
      throw Exception('세션이 만료되었습니다');
    }
    return {};
  } catch (e) {
    print('월별 지출 조회 에러: $e');
    return {};
  }
}

// 장보기 항목 삭제 (완료 없이 그냥 삭제)
Future<Map<String, dynamic>> deleteShoppingItems(List<int> shoppingListIds) async {
  try {
    final dio = createAuthDio();

    if (responsedAccessToken == null) {
      throw Exception('로그인이 필요합니다');
    }

    final String baseUrl = await buildApiUrl('', port: '');

    final response = await dio.delete(
      '$baseUrl/api/shopping-list/delete/',
      data: {
        'shopping_list_ids': shoppingListIds,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $responsedAccessToken',
          'Content-Type': 'application/json',
        },
      ),
    );

    return response.data;
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      throw Exception('세션이 만료되었습니다');
    }
    throw Exception(e.response?.data['error'] ?? '장보기 항목 삭제 실패');
  }
}
