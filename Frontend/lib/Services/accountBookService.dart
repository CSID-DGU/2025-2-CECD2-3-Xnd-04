import 'package:dio/dio.dart';
import 'package:Frontend/Services/authService.dart';
import 'package:network_info_plus/network_info_plus.dart';

/// 가계부 설정 조회
Future<Map<String, dynamic>?> getAccountBookSettings() async {
  final dio = createAuthDio();
  final String? ip = await NetworkInfo().getWifiIP();

  final String url = (ip!.startsWith('10.0.2'))
      ? 'http://10.0.2.2:8000/api/account-book/settings/'
      : 'http://$HOST/api/account-book/settings/';

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
      print('가계부 설정 조회 성공: ${response.data}');
      return response.data;
    }
    return null;
  } catch (e) {
    print('가계부 설정 조회 실패: $e');
    return null;
  }
}

/// 가계부 설정 수정
Future<bool> updateAccountBookSettings({
  int? monthlyBudget,
  int? budgetResetDay,
}) async {
  final dio = createAuthDio();
  final String? ip = await NetworkInfo().getWifiIP();

  final String url = (ip!.startsWith('10.0.2'))
      ? 'http://10.0.2.2:8000/api/account-book/settings/'
      : 'http://$HOST/api/account-book/settings/';

  try {
    Map<String, dynamic> data = {};
    if (monthlyBudget != null) data['monthly_budget'] = monthlyBudget;
    if (budgetResetDay != null) data['budget_reset_day'] = budgetResetDay;

    final response = await dio.patch(
      url,
      data: data,
      options: Options(
        headers: {
          'Authorization': 'Bearer $responsedAccessToken',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      print('가계부 설정 수정 성공: ${response.data}');
      return true;
    }
    return false;
  } catch (e) {
    print('가계부 설정 수정 실패: $e');
    return false;
  }
}

/// 지출 추가
Future<bool> addExpense(int amount) async {
  final dio = createAuthDio();
  final String? ip = await NetworkInfo().getWifiIP();

  final String url = (ip!.startsWith('10.0.2'))
      ? 'http://10.0.2.2:8000/api/account-book/expense/'
      : 'http://$HOST/api/account-book/expense/';

  try {
    final response = await dio.post(
      url,
      data: {'amount': amount},
      options: Options(
        headers: {
          'Authorization': 'Bearer $responsedAccessToken',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      print('지출 추가 성공: ${response.data}');
      return true;
    }
    return false;
  } catch (e) {
    print('지출 추가 실패: $e');
    return false;
  }
}

/// 예산 수동 초기화
Future<bool> resetBudget() async {
  final dio = createAuthDio();
  final String? ip = await NetworkInfo().getWifiIP();

  final String url = (ip!.startsWith('10.0.2'))
      ? 'http://10.0.2.2:8000/api/account-book/reset/'
      : 'http://$HOST/api/account-book/reset/';

  try {
    final response = await dio.post(
      url,
      options: Options(
        headers: {
          'Authorization': 'Bearer $responsedAccessToken',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      print('예산 초기화 성공: ${response.data}');
      return true;
    }
    return false;
  } catch (e) {
    print('예산 초기화 실패: $e');
    return false;
  }
}
