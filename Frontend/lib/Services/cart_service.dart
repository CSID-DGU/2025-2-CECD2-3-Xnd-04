import 'package:dio/dio.dart';
import 'package:Frontend/Services/authService.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../Models/cart_model.dart';

/// 장바구니 목록 조회
Future<List<CartItemModel>> loadCartItems() async {
  final dio = Dio();
  final String? ip = await NetworkInfo().getWifiIP();

  final String cartURL = (ip!.startsWith('10.0.2'))
      ? 'http://10.0.2.2:8000/api/cart/'
      : 'http://' + HOST! + ':8000/api/cart/';

  try {
    final response = await dio.get(
      cartURL,
      options: Options(
        headers: {
          'Authorization': 'Bearer ' + responsedAccessToken!,
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      List<dynamic> items = response.data['items'] ?? [];
      cartItems = items.map((item) => CartItemModel.fromJson(item)).toList();
      return cartItems!;
    }
    return [];
  } catch (e) {
    print('장바구니 조회 에러: $e');
    return [];
  }
}

/// 장바구니에 아이템 추가
Future<bool> addToCart({
  required int ingredientId,
  required int recipeId,
  required String quantity,
}) async {
  final dio = Dio();
  final String? ip = await NetworkInfo().getWifiIP();

  final String cartAddURL = (ip!.startsWith('10.0.2'))
      ? 'http://10.0.2.2:8000/api/cart/add/'
      : 'http://' + HOST! + ':8000/api/cart/add/';

  try {
    final response = await dio.post(
      cartAddURL,
      data: {
        'ingredient_id': ingredientId,
        'recipe_id': recipeId,
        'quantity': quantity,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer ' + responsedAccessToken!,
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('장바구니에 추가되었습니다.');
      return true;
    }
    return false;
  } catch (e) {
    print('장바구니 추가 에러: $e');
    return false;
  }
}

/// 장바구니 개별 아이템 삭제 (X 버튼)
Future<bool> deleteCartItem(int cartId) async {
  final dio = Dio();
  final String? ip = await NetworkInfo().getWifiIP();

  final String cartDeleteURL = (ip!.startsWith('10.0.2'))
      ? 'http://10.0.2.2:8000/api/cart/$cartId/'
      : 'http://' + HOST! + ':8000/api/cart/$cartId/';

  try {
    final response = await dio.delete(
      cartDeleteURL,
      options: Options(
        headers: {
          'Authorization': 'Bearer ' + responsedAccessToken!,
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      print('장바구니에서 삭제되었습니다.');
      return true;
    }
    return false;
  } catch (e) {
    print('장바구니 삭제 에러: $e');
    return false;
  }
}

/// 장바구니 선택 삭제
Future<bool> deleteSelectedCartItems(List<int> cartIds) async {
  final dio = Dio();
  final String? ip = await NetworkInfo().getWifiIP();

  final String bulkDeleteURL = (ip!.startsWith('10.0.2'))
      ? 'http://10.0.2.2:8000/api/cart/bulk-delete/'
      : 'http://' + HOST! + ':8000/api/cart/bulk-delete/';

  try {
    final response = await dio.post(
      bulkDeleteURL,
      data: {
        'cart_ids': cartIds,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer ' + responsedAccessToken!,
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      print('선택한 아이템이 삭제되었습니다.');
      return true;
    }
    return false;
  } catch (e) {
    print('선택 삭제 에러: $e');
    return false;
  }
}

/// 장바구니 전체 삭제
Future<bool> clearCart() async {
  final dio = Dio();
  final String? ip = await NetworkInfo().getWifiIP();

  final String clearURL = (ip!.startsWith('10.0.2'))
      ? 'http://10.0.2.2:8000/api/cart/clear/'
      : 'http://' + HOST! + ':8000/api/cart/clear/';

  try {
    final response = await dio.delete(
      clearURL,
      options: Options(
        headers: {
          'Authorization': 'Bearer ' + responsedAccessToken!,
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      print('장바구니가 비워졌습니다.');
      return true;
    }
    return false;
  } catch (e) {
    print('전체 삭제 에러: $e');
    return false;
  }
}
