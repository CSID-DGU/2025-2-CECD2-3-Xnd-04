import 'package:dio/dio.dart';
import 'package:Frontend/Services/authService.dart';

Future<List<Map<String, dynamic>>> getDailyExpenses(String date) async {
  try {
    final dio = createAuthDio();

    final String expenseURL = await buildApiUrl('/api/expenses/');

    final response = await dio.get(
      expenseURL,
      queryParameters: {'date': date},
      options: Options(
        headers: {
          'Authorization': 'Bearer $responsedAccessToken',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      print('지출 내역 조회 성공: ${response.data}');
      return List<Map<String, dynamic>>.from(response.data['expenses']);
    } else {
      throw Exception('지출 내역 조회 실패');
    }
  } catch (e) {
    print('지출 내역 조회 오류: $e');
    throw Exception('지출 내역 조회 실패: $e');
  }
}

Future<void> addExpense({
  required String date,
  required String itemName,
  required int amount,
  required String category,
  String? memo,
}) async {
  try {
    final dio = createAuthDio();

    final String expenseAddURL = await buildApiUrl('/api/expenses/add/');

    final response = await dio.post(
      expenseAddURL,
      data: {
        'date': date,
        'item_name': itemName,
        'amount': amount,
        'category': category,
        'memo': memo ?? '',
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $responsedAccessToken',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 201) {
      print('지출 내역 추가 성공: ${response.data}');
    } else {
      throw Exception('지출 내역 추가 실패');
    }
  } catch (e) {
    print('지출 내역 추가 오류: $e');
    throw Exception('지출 내역 추가 실패: $e');
  }
}

Future<void> deleteExpense(int expenseId) async {
  try {
    final dio = createAuthDio();

    final String expenseDeleteURL = await buildApiUrl('/api/expenses/$expenseId/');

    final response = await dio.delete(
      expenseDeleteURL,
      options: Options(
        headers: {
          'Authorization': 'Bearer $responsedAccessToken',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      print('지출 내역 삭제 성공: ${response.data}');
    } else {
      throw Exception('지출 내역 삭제 실패');
    }
  } catch (e) {
    print('지출 내역 삭제 오류: $e');
    throw Exception('지출 내역 삭제 실패: $e');
  }
}
