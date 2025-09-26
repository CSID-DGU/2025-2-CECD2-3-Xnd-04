import 'package:flutter/material.dart';
import 'package:Frontend/Abstracts/kakaoLogin.dart';
import 'package:Frontend/Models/LoginModel.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:Frontend/Services/loadFridgeService.dart';



import '../PushService/fcmService.dart';

/* 남은 Task
1. 자동 로그인 시, 로그인을 스킵하는 기능 추가(데이터베이스에서 따와야됨)
*/

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => LoginPage();
}

class LoginPage extends State<LoginView>{
  @override
  void initState(){
    super.initState();
  }
  final loginViewModel = LoginModel(KakaoLogin());

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: basicBar(),
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: screenHeight / 2 - 150),
            Text(
              '냉장고를 부탁해',
              style: TextStyle(fontSize: screenWidth / 10),
            ),
            SizedBox(height: screenHeight / 6),
            // ✅ 로그인 상태가 false일 때만 로그인 버튼 표시
            SizedBox(
              width: screenWidth * 0.6,
              height: screenHeight / 20,
              child: ElevatedButton(
                onPressed: () async {
                  // 로그인 시, 로그인 여부 확인하고 냉장고의 수를 체크하여 냉장고 수에 따라 다른 화면으로 이동
                  await loginViewModel.login();

                  // 🔥 FCM 기기 등록 (로그인 성공 후)
                  if (loginViewModel.isLogined) {
                    await FCMService.instance.registerDeviceToServer();
                  }

                  bool fridgeNonZero = await getFridgesInfo();

                  if (loginViewModel.isLogined)
                    await FCMService.instance.registerDeviceToServer();

                  (fridgeNonZero) ?
                  Navigator.push(context, MaterialPageRoute(builder: (i) => pages[5])):
                  Navigator.push(context, MaterialPageRoute(builder: (i) => pages[0]));
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset('assets/images/kakaotalk_icon.png'),
                    SizedBox(width: screenWidth * 0.015),
                    const Text('카카오계정으로 로그인'),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.yellow,
                  textStyle: TextStyle(
                    color: Colors.black,
                    fontSize: (screenWidth * 0.6) / 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
