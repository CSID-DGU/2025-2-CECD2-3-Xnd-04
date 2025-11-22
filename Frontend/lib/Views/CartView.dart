import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Frontend/Abstracts/kakaoLogin.dart';
import 'package:Frontend/Models/LoginModel.dart';
import 'package:Frontend/Models/cart_model.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:Frontend/Views/DailyExpenseView.dart';
import 'package:Frontend/Widgets/CommonAppBar.dart';
import 'package:Frontend/Services/cart_service.dart';
import 'package:Frontend/Services/purchaseService.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class CartView extends StatefulWidget {
  const CartView({Key? key}) : super(key: key);

  @override
  State<CartView> createState() => CartPage();
}

class CartPage extends State<CartView> {
  final loginViewModel = LoginModel(KakaoLogin());
  List<CartItemModel> items = [];
  Map<int, bool> selectedItems = {}; // 체크박스 상태 관리
  bool isLoading = true;
  String userName = 'User';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadCartData();
  }

  // 사용자 정보 로드
  Future<void> _loadUserInfo() async {
    try {
      User user = await UserApi.instance.me();
      setState(() {
        userName = user.kakaoAccount?.profile?.nickname ?? 'User';
      });
    } catch (e) {
      print('사용자 정보 로드 에러: $e');
    }
  }

  // 장바구니 데이터 로드
  Future<void> _loadCartData() async {
    setState(() {
      isLoading = true;
    });

    List<CartItemModel> loadedItems = await loadCartItems();

    setState(() {
      items = loadedItems;
      // 모든 아이템을 체크 해제 상태로 초기화
      selectedItems = {for (var item in items) item.id!: false};
      isLoading = false;
    });
  }

  // 개별 아이템 삭제 (X 버튼)
  Future<void> _deleteItem(int cartId) async {
    bool success = await deleteCartItem(cartId);
    if (success) {
      _loadCartData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('장바구니에서 삭제되었습니다.')),
      );
    }
  }

  // 선택 삭제
  Future<void> _deleteSelected() async {
    List<int> selectedIds = selectedItems.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();

    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제할 아이템을 선택해주세요.')),
      );
      return;
    }

    bool success = await deleteSelectedCartItems(selectedIds);
    if (success) {
      _loadCartData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selectedIds.length}개의 아이템이 삭제되었습니다.')),
      );
    }
  }

  // 전체 삭제
  Future<void> _clearCart() async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('장바구니가 비어있습니다.')),
      );
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('전체 삭제'),
        content: Text('장바구니의 모든 아이템을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      bool success = await clearCart();
      if (success) {
        _loadCartData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('장바구니가 비워졌습니다.')),
        );
      }
    }
  }

  // 캘린더로 추가
  Future<void> _addToCalendar() async {
    // 선택된 항목이 있는지 확인
    List<CartItemModel> selectedCartItems = items.where((item) {
      return selectedItems[item.id] == true;
    }).toList();

    if (selectedCartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('장보기 일정에 추가할 재료를 선택해주세요')),
      );
      return;
    }

    // 날짜 선택 다이얼로그
    String? selectedOption = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('장보기 일정 선택'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.today, color: Color(0xFF2196F3)),
                title: Text('오늘'),
                onTap: () => Navigator.pop(context, 'today'),
              ),
              ListTile(
                leading: Icon(Icons.calendar_month, color: Color(0xFF2196F3)),
                title: Text('다른 날'),
                onTap: () => Navigator.pop(context, 'other'),
              ),
            ],
          ),
        );
      },
    );

    if (selectedOption == null) return;

    DateTime selectedDate;
    if (selectedOption == 'today') {
      selectedDate = DateTime.now();
    } else {
      // 다른 날 선택 - DatePicker 표시
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(), // 오늘 이후만 선택 가능
        lastDate: DateTime.now().add(Duration(days: 365)),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Color(0xFF2196F3),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedDate == null) return;
      selectedDate = pickedDate;
    }

    // API로 장보기 일정 추가 (Purchase 테이블 사용)
    try {
      List<int> cartItemIds = selectedCartItems.map((item) => item.id!).toList();
      String shoppingDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

      final result = await addToShoppingList(
        cartIds: cartItemIds,
        shoppingDate: shoppingDateStr,
      );

      if (result != null) {
        // 장바구니 목록 새로고침 (이미 백엔드에서 삭제됨)
        await _loadCartData();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? '장보기 일정에 추가되었습니다'),
            backgroundColor: Colors.green,
          ),
        );

        // DailyExpenseView로 이동
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DailyExpenseView(
              selectedDate: selectedDate,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('장보기 일정 추가에 실패했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 장바구니 뷰 - 하단바 3번 활성화
    currentBottomNavIndex = 3;

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: const CommonAppBar(title: 'Xnd'),
      backgroundColor: Colors.white,
      bottomNavigationBar: const MainBottomView(),
      body: Column(
        children: [
          // 상단 헤더
          Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '$userName님의 장바구니',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                // 전체 선택 / 선택 삭제 / 전체 삭제 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          bool allSelected = selectedItems.values.every((selected) => selected);
                          for (var key in selectedItems.keys) {
                            selectedItems[key] = !allSelected;
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Text(
                        selectedItems.values.every((selected) => selected) ? '전체 해제' : '전체 선택',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _deleteSelected,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Text(
                        '선택 삭제',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _clearCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Color(0xFFFF4500),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Text(
                        '전체 삭제',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 장바구니 아이템 리스트
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text(
                              '장바구니가 비어있습니다',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          CartItemModel item = items[index];
                          return _buildCartItem(item, screenWidth, screenHeight);
                        },
                      ),
          ),

          // 캘린더에 추가 버튼
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: items.isEmpty ? null : _addToCalendar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF87CEEB),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                () {
                  int selectedCount = selectedItems.values.where((selected) => selected).length;
                  return selectedCount > 0 ? '$selectedCount개 캘린더에 추가' : '캘린더에 추가';
                }(),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 장바구니 아이템 카드 위젯
  Widget _buildCartItem(CartItemModel item, double screenWidth, double screenHeight) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // 체크박스
          Checkbox(
            value: selectedItems[item.id] ?? false,
            onChanged: (bool? value) {
              setState(() {
                selectedItems[item.id!] = value ?? false;
              });
            },
            shape: CircleBorder(),
            activeColor: Color(0xFF87CEEB),
          ),
          SizedBox(width: 12),

          // 아이템 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 재료명
                Text(
                  item.ingredientName ?? '재료',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),

                // 중량
                Text(
                  item.quantity ?? '1',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),

                // 레시피명 (있을 경우)
                if (item.recipeName != null && item.recipeName!.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFF87CEEB).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.recipeName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4A90E2),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // X 버튼
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey[700]),
            onPressed: () => _deleteItem(item.id!),
          ),
        ],
      ),
    );
  }
}