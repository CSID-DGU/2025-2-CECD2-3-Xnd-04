import 'package:flutter/material.dart';
import 'package:Frontend/Views/LoginView.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:Frontend/Widgets/CommonAppBar.dart';

// 이거 모달창으로 수정
class AlertView extends StatefulWidget {
  const AlertView({Key? key}) : super(key: key);
  static String routeName = "/Alert_page";

  @override
  State<AlertView> createState() => AlertPage();
}

class AlertPage extends State<AlertView> {

  void initState(){
    super.initState();
  }

  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: const CommonAppBar(title: 'Xnd'),
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text('알림이 없습니다.', style: TextStyle(fontSize: 20, color: Colors.grey)),
          ],
        )
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          // 하단바 아이콘 클릭 시 해당 페이지로 이동
          if (index == 0) {
            currentBottomNavIndex = 0;
            Navigator.of(context).pushReplacementNamed('/' + pages[1].toString());
          } else if (index == 1) {
            currentBottomNavIndex = 1;
            Navigator.of(context).pushReplacementNamed('/' + pages[2].toString());
          } else if (index == 2) {
            currentBottomNavIndex = 2;
            Navigator.of(context).pushReplacementNamed('/' + pages[10].toString());
          } else if (index == 3) {
            currentBottomNavIndex = 3;
            Navigator.of(context).pushReplacementNamed('/' + pages[4].toString());
          } else if (index == 4) {
            currentBottomNavIndex = 4;
            Navigator.of(context).pushReplacementNamed('/' + pages[3].toString());
          }
        },
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFFFFFFF),
        selectedItemColor: Colors.grey,
        unselectedItemColor: Colors.grey,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ingredients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'recipe',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'accountbook',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_mall),
            label: 'cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'favorites',
          ),
        ],
      ),
    );
  }
}