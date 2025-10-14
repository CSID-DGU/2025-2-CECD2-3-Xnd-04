import 'dart:math';

import 'package:flutter/material.dart';
import 'package:Frontend/Models/LoginModel.dart';
import 'package:Frontend/Views/LoginView.dart';
import 'package:Frontend/Abstracts/kakaoLogin.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:Frontend/Widgets/CommonAppBar.dart';

class SettingView extends StatefulWidget {
  const SettingView({Key? key}) : super(key: key);
  static String routeName = "/Setting_page";

  @override
  State<SettingView> createState() => SettingPage();
}

class SettingPage extends State<SettingView> {

  @override
  void initState() {
    super.initState();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'Xnd'),
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text('설정 페이지', style: TextStyle(fontSize: 24, color: Colors.grey)),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  Navigator.push(context,
                    MaterialPageRoute(
                      builder: (i) => const LoginView(),
                    )
                  );
                });
              },
              child: Text('로그아웃', style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            )
          ],
        ),
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
            Navigator.of(context).pushReplacementNamed('/' + pages[11].toString());
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
