import 'package:flutter/material.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:Frontend/Widgets/CommonAppBar.dart';
import 'package:Frontend/Services/accountBookService.dart';
import 'package:Frontend/Services/shoppingListService.dart';
import 'package:Frontend/Services/purchaseService.dart';
import 'package:Frontend/Views/DailyExpenseView.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class AccountBookView extends StatefulWidget {
  const AccountBookView({Key? key}) : super(key: key);

  @override
  State<AccountBookView> createState() => AccountBookPage();
}

class AccountBookPage extends State<AccountBookView> {
  bool isCalendarView = false;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;

  final String userName = 'user';
  int monthlyBudget = 100000; // 월 예산
  int totalSpent = 0; // 누적 지출
  int remainingBudget = 100000; // 남은 예산

  List<Map<String, dynamic>> expenses = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAccountBookData();
  }

  Future<void> _loadAccountBookData() async {
    setState(() {
      _isLoading = true;
    });

    // 가계부 설정 조회
    final settings = await getAccountBookSettings();

    if (settings != null) {
      monthlyBudget = settings['monthly_budget'] ?? 100000;
      totalSpent = settings['monthly_spent'] ?? 0;
      remainingBudget = settings['budget'] ?? 100000;
    }

    // 구매 내역 조회
    final purchaseData = await getPurchaseHistory(
      year: _focusedDay.year,
      month: _focusedDay.month,
    );

    if (purchaseData != null) {
      final expensesData = purchaseData['expenses'] as List<dynamic>? ?? [];
      expenses = expensesData.map((e) => e as Map<String, dynamic>).toList();
    } else {
      expenses = [];
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    currentBottomNavIndex = 2;
    int currentMonth = DateTime.now().month;

    return Scaffold(
      appBar: CommonAppBar(title: 'Xnd', curveColor: Colors.grey[100]),
      backgroundColor: Colors.grey[100],
      bottomNavigationBar: const MainBottomView(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 사용자 정보 헤더
                Container(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
                  color: Colors.grey[100],
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.blue[200],
                        child: Icon(Icons.person, size: 40, color: Colors.white),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$userName님',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('이번 달 식비 지출', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                      SizedBox(height: 4),
                                      Text(
                                        '${totalSpent.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('남은 식비 예산', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                      SizedBox(height: 4),
                                      Text(
                                        '${remainingBudget.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: remainingBudget < 0 ? Colors.red : Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isCalendarView ? Icons.filter_list : Icons.calendar_today,
                          color: Colors.grey[700],
                        ),
                        onPressed: () {
                          setState(() {
                            isCalendarView = !isCalendarView;
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.settings_outlined,
                          color: Colors.grey[700],
                        ),
                        onPressed: () async {
                          // 설정 페이지로 이동 후 돌아오면 데이터 새로고침
                          await Navigator.of(context).pushNamed('/AccountBookSettingView');
                          _loadAccountBookData();
                        },
                      ),
                    ],
                  ),
                ),

                // 스크롤 가능한 영역
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            color: Colors.white,
                            child: Text(
                              '$currentMonth월의 식비 가계부',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (isCalendarView) _buildCalendarView() else _buildListView(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildListView() {
    if (expenses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40.0),
        child: Center(
          child: Text(
            '이번 달 구매 내역이 없습니다',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Column(
      children: expenses.map((dateGroup) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                dateGroup['date'],
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
            ),
            ...((dateGroup['items'] as List).map((item) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(item['name'], style: TextStyle(fontSize: 14)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item['amount']}원',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${item['remaining'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList()),
            SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCalendarView() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });

          // 날짜 선택 시 해당 날짜의 지출 편집 페이지로 이동
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DailyExpenseView(selectedDate: selectedDay),
            ),
          ).then((_) {
            // 지출 편집 페이지에서 돌아오면 데이터 새로고침
            _loadAccountBookData();
          });
        },
        calendarFormat: CalendarFormat.month,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(color: Colors.blue[200], shape: BoxShape.circle),
          selectedDecoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
          weekendTextStyle: TextStyle(color: Colors.red),
        ),
        eventLoader: (day) => [],
      ),
    );
  }
}
