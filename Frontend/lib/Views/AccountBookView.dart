import 'package:flutter/material.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:Frontend/Widgets/CommonAppBar.dart';
import 'package:table_calendar/table_calendar.dart';

class AccountBookView extends StatefulWidget {
  const AccountBookView({Key? key}) : super(key: key);

  @override
  State<AccountBookView> createState() => AccountBookPage();
}

class AccountBookPage extends State<AccountBookView> {
  bool isCalendarView = false;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final String userName = 'user';
  final int budget = 100000;
  final int totalSpent = 75400;

  final List<Map<String, dynamic>> expenses = [
    {
      'date': '10월 20일',
      'items': [
        {'name': '초록마을 무농약 깐양파', 'amount': -4900, 'remaining': 75400},
        {'name': '토종 의성 깐마늘', 'amount': -9800, 'remaining': 80300},
        {'name': '유기농 대파', 'amount': -2900, 'remaining': 90100},
      ]
    },
    {
      'date': '10월 19일',
      'items': [
        {'name': '스파게티 면', 'amount': -4900, 'remaining': 93000},
        {'name': '저당 콜슬로스', 'amount': -7900, 'remaining': 97900},
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    currentBottomNavIndex = 2;
    int currentMonth = DateTime.now().month;

    return Scaffold(
      appBar: CommonAppBar(title: 'Xnd', curveColor: Colors.grey[100]),
      backgroundColor: Colors.grey[100],
      bottomNavigationBar: const MainBottomView(),
      body: Column(
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
                                Text('이번 달 식비 예산', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                SizedBox(height: 4),
                                Text(
                                  '${budget.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
