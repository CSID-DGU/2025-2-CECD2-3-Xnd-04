import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:Frontend/Services/shoppingListService.dart';
import 'package:Frontend/Services/expenseService.dart';

class DailyExpenseView extends StatefulWidget {
  final DateTime selectedDate;

  const DailyExpenseView({Key? key, required this.selectedDate}) : super(key: key);

  @override
  State<DailyExpenseView> createState() => _DailyExpenseViewState();
}

class _DailyExpenseViewState extends State<DailyExpenseView> {
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  List<Map<String, dynamic>> expenses = [];
  bool isLoadingExpenses = true; // 지출 내역 로딩 상태

  // 장보기 목록 관련 상태
  List<Map<String, dynamic>> shoppingList = [];
  Map<int, bool> selectedShoppingItems = {};
  bool showShoppingList = false;
  int dailyShoppingSpending = 0; // 해당 날짜의 장보기 지출

  @override
  void initState() {
    super.initState();
    // TODO: API에서 해당 날짜의 지출 내역 불러오기
    _loadExpenses();
    _initializeShoppingList();
    _loadDailySpending();
  }

  // API에서 장보기 목록 불러오기
  Future<void> _initializeShoppingList() async {
    try {
      print('DailyExpenseView: 장보기 목록 불러오기 시작 - 날짜: ${widget.selectedDate}');
      final items = await getShoppingList(widget.selectedDate);

      print('DailyExpenseView: 조회된 항목 수: ${items.length}');

      setState(() {
        shoppingList.clear();
        selectedShoppingItems.clear();

        for (var item in items) {
          shoppingList.add({
            'id': item['id'],
            'ingredient_id': item['ingredient_id'],
            'name': item['ingredient_name'],
            'completed': item['is_bought'] ?? false,
            'price': item['price'],
          });
          selectedShoppingItems[item['id']] = false;
        }
      });

      print('DailyExpenseView: 장보기 목록 로드 완료');
    } catch (e) {
      print('장보기 목록 불러오기 실패: $e');
      // 에러 발생 시 빈 목록으로 처리 (사용자가 직접 추가할 수 있도록)
      setState(() {
        shoppingList.clear();
        selectedShoppingItems.clear();
      });
    }
  }

  // 해당 날짜의 장보기 지출 불러오기
  Future<void> _loadDailySpending() async {
    try {
      final spending = await getDailySpending(widget.selectedDate);
      setState(() {
        dailyShoppingSpending = spending;
      });
    } catch (e) {
      print('날짜별 지출 불러오기 실패: $e');
      setState(() {
        dailyShoppingSpending = 0;
      });
    }
  }

  // 재료 가격 입력 다이얼로그
  Future<void> _showPriceInputDialog(int itemId, String itemName) async {
    TextEditingController priceController = TextEditingController();

    // 기존 가격이 있으면 표시
    int index = shoppingList.indexWhere((item) => item['id'] == itemId);
    if (index != -1 && shoppingList[index]['price'] != null) {
      priceController.text = shoppingList[index]['price'].toString();
    }

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('가격 입력'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                itemName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '가격',
                  hintText: '0',
                  suffixText: '원',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                if (priceController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('가격을 입력해주세요')),
                  );
                  return;
                }

                setState(() {
                  int price = int.parse(priceController.text);
                  int index = shoppingList.indexWhere((item) => item['id'] == itemId);
                  if (index != -1) {
                    shoppingList[index]['price'] = price;
                    selectedShoppingItems[itemId] = true;
                  }
                });

                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
              ),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadExpenses() async {
    setState(() {
      isLoadingExpenses = true;
    });

    try {
      String dateString = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
      print('지출 내역 조회 시작: $dateString');
      final expensesList = await getDailyExpenses(dateString);

      setState(() {
        expenses = expensesList.map((expense) => {
          'id': expense['id'],
          'item': expense['item_name'],
          'amount': expense['amount'],
          'memo': expense['memo'] ?? '',
          'category': expense['category'] ?? '기타',
          'date': widget.selectedDate,
        }).toList();
        isLoadingExpenses = false;
      });

      print('지출 내역 로드 완료: ${expenses.length}개');
    } catch (e) {
      print('지출 내역 불러오기 실패: $e');
      setState(() {
        expenses = [];
        isLoadingExpenses = false;
      });
    }
  }

  void _addExpense() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('지출 추가'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _itemNameController,
                  decoration: const InputDecoration(
                    labelText: '항목명',
                    hintText: '예: 마트 장보기',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: '금액',
                    hintText: '0',
                    suffixText: '원',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _memoController,
                  decoration: const InputDecoration(
                    labelText: '메모 (선택)',
                    hintText: '간단한 메모를 입력하세요',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _itemNameController.clear();
                _amountController.clear();
                _memoController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_itemNameController.text.isEmpty || _amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('항목명과 금액을 입력해주세요')),
                  );
                  return;
                }

                try {
                  String dateString = DateFormat('yyyy-MM-dd').format(widget.selectedDate);

                  // API로 지출 저장
                  await addExpense(
                    date: dateString,
                    itemName: _itemNameController.text,
                    amount: int.parse(_amountController.text),
                    category: '기타',
                    memo: _memoController.text,
                  );

                  // 지출 목록 새로고침
                  await _loadExpenses();

                  _itemNameController.clear();
                  _amountController.clear();
                  _memoController.clear();

                  if (!mounted) return;
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('지출이 추가되었습니다'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('지출 추가 실패: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
  }

  void _deleteExpense(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('지출 삭제'),
          content: const Text('이 지출 내역을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                final expenseId = expenses[index]['id'];

                Navigator.of(context).pop();

                try {
                  // API로 지출 삭제
                  await deleteExpense(expenseId);

                  // 지출 목록 새로고침
                  await _loadExpenses();

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('지출이 삭제되었습니다'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('지출 삭제 실패: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  String _formatCurrency(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  int _getTotalAmount() {
    return expenses.fold(0, (sum, item) => sum + (item['amount'] as int));
  }

  // 선택된 장보기 항목 삭제
  Future<void> _deleteSelectedShoppingItems() async {
    List<int> selectedIds = selectedShoppingItems.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();

    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제할 항목을 선택해주세요')),
      );
      return;
    }

    try {
      // API로 장보기 항목 삭제
      final result = await deleteShoppingItems(selectedIds);

      setState(() {
        // 선택된 항목들을 삭제
        shoppingList.removeWhere((item) => selectedIds.contains(item['id']));
        // 선택 상태 초기화
        for (var id in selectedIds) {
          selectedShoppingItems.remove(id);
        }
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? '항목이 삭제되었습니다'),
          backgroundColor: Colors.green,
        ),
      );
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

  // 선택된 장보기 항목 완료 처리
  Future<void> _completeSelectedShoppingItems() async {
    List<int> selectedIds = selectedShoppingItems.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();

    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('완료 처리할 항목을 선택해주세요')),
      );
      return;
    }

    // 모든 선택된 항목에 가격이 입력되었는지 확인
    List<String> itemsWithoutPrice = [];
    int totalPrice = 0;
    Map<String, int> prices = {};

    for (var id in selectedIds) {
      int index = shoppingList.indexWhere((item) => item['id'] == id);
      if (index != -1) {
        if (shoppingList[index]['price'] == null) {
          itemsWithoutPrice.add(shoppingList[index]['name']);
        } else {
          int price = shoppingList[index]['price'] as int;
          totalPrice += price;
          prices[id.toString()] = price;
        }
      }
    }

    if (itemsWithoutPrice.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('가격이 입력되지 않은 항목이 있습니다: ${itemsWithoutPrice.join(", ")}'),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // 총 지출 표시 및 API 호출
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
              const SizedBox(width: 8),
              Text('장보기 완료'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${selectedIds.length}개의 재료를 구매했습니다',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Divider(),
              const SizedBox(height: 8),
              Text(
                '총 지출',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_formatCurrency(totalPrice)}원',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();

                try {
                  // API로 장보기 완료 처리 (가격 저장 + is_bought 업데이트 + 지출 추가)
                  final result = await completeShoppingList(
                    shoppingListIds: selectedIds,
                    prices: prices,
                    shoppingDate: widget.selectedDate,
                  );

                  // 완료 처리된 항목들을 completed=true로 업데이트
                  setState(() {
                    for (var id in selectedIds) {
                      int index = shoppingList.indexWhere((item) => item['id'] == id);
                      if (index != -1) {
                        shoppingList[index]['completed'] = true;
                      }
                      selectedShoppingItems[id] = false;
                    }
                  });

                  // 장보기 목록과 지출 새로고침
                  await _initializeShoppingList();
                  await _loadDailySpending();
                  await _loadExpenses(); // 지출 내역도 새로고침 (장보기 완료 시 자동으로 expense가 생성됨)

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? '장보기가 완료되었습니다'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
              ),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String dateString = DateFormat('yyyy년 MM월 dd일').format(widget.selectedDate);
    int totalAmount = _getTotalAmount();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          dateString,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: _addExpense,
          ),
        ],
      ),
      body: Column(
        children: [
          // 총 지출 요약
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이날의 총 지출',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatCurrency(totalAmount + dailyShoppingSpending)}원',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                ),
                if (dailyShoppingSpending > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.shopping_basket, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '장보기: ${_formatCurrency(dailyShoppingSpending)}원',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // 장보기 목록 섹션 (재료가 있을 때만 표시)
          if (shoppingList.isNotEmpty)
            Column(
              children: [
                // 장보기 목록 토글 버튼
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shopping_basket, color: Color(0xFF4CAF50)),
                          const SizedBox(width: 8),
                          Text(
                            '장보기 목록 (${shoppingList.length}개)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          showShoppingList ? Icons.expand_less : Icons.expand_more,
                          color: Colors.grey[700],
                        ),
                        onPressed: () {
                          setState(() {
                            showShoppingList = !showShoppingList;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // 장보기 목록 내용
                if (showShoppingList)
                  Container(
                    color: Colors.green[50],
                    child: Column(
                      children: [
                        // 장보기 목록 아이템들
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: shoppingList.length,
                          itemBuilder: (context, index) {
                            final item = shoppingList[index];
                            final isCompleted = item['completed'] ?? false;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isCompleted ? Colors.grey[200] : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: selectedShoppingItems[item['id']] ?? false,
                                    onChanged: isCompleted ? null : (bool? value) async {
                                      if (value == true) {
                                        // 체크박스를 선택하면 가격 입력 다이얼로그 표시
                                        await _showPriceInputDialog(item['id'], item['name']);
                                      } else {
                                        // 체크박스 해제
                                        setState(() {
                                          selectedShoppingItems[item['id']] = false;
                                        });
                                      }
                                    },
                                    shape: const CircleBorder(),
                                    activeColor: const Color(0xFF4CAF50),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'],
                                          style: TextStyle(
                                            fontSize: 15,
                                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                                            color: isCompleted ? Colors.grey[600] : Colors.black,
                                          ),
                                        ),
                                        if (item['price'] != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              '${_formatCurrency(item['price'])}원',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF2196F3),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isCompleted)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '완료',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green[800],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),

                        // 선택 삭제 / 장보기 완료 버튼
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _deleteSelectedShoppingItems,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.red,
                                    elevation: 1,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(color: Colors.red[300]!),
                                    ),
                                  ),
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  label: const Text('선택 삭제'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _completeSelectedShoppingItems,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4CAF50),
                                    foregroundColor: Colors.white,
                                    elevation: 1,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(Icons.check_circle_outline, size: 20),
                                  label: const Text('장보기 완료'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

          // 지출 목록
          Expanded(
            child: isLoadingExpenses
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : expenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              '지출 내역이 없습니다',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '+ 버튼을 눌러 지출을 추가하세요',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      final category = expense['category'] ?? '기타';

                      // 카테고리별 아이콘과 색상
                      IconData categoryIcon;
                      Color categoryColor;

                      if (category == '장보기') {
                        categoryIcon = Icons.shopping_basket;
                        categoryColor = const Color(0xFF4CAF50);
                      } else {
                        categoryIcon = Icons.shopping_cart;
                        categoryColor = const Color(0xFF2196F3);
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              categoryIcon,
                              color: categoryColor,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  expense['item'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (category == '장보기')
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '장보기',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: expense['memo'] != null && expense['memo'].isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    expense['memo'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '-${_formatCurrency(expense['amount'])}원',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _deleteExpense(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExpense,
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.add),
      ),
    );
  }
}
