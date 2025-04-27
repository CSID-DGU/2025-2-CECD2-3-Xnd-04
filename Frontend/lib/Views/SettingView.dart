import 'dart:math';

import 'package:flutter/material.dart';
import 'package:Frontend/Models/LoginModel.dart';
import 'package:Frontend/Views/LoginView.dart';
import 'package:Frontend/Login/kakaoLogin.dart';
import 'package:Frontend/Views/MainFrameView.dart';

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
      appBar: basicBar(),
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 200,),
            ElevatedButton(onPressed: () async {setState(() {
                Navigator.push(context,
                    MaterialPageRoute(
                      builder: (i) => const LoginView(),
                    )
                );
            }
            );
              },
                child: Text('로그아웃', style: TextStyle(fontSize: 30)),
            )
          ],
        ),
      ),
    );
  }
}
