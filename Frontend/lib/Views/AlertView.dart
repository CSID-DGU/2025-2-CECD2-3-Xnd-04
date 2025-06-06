import 'package:flutter/material.dart';
import 'package:Frontend/Views/LoginView.dart';
import 'package:Frontend/Views/MainFrameView.dart';

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
      appBar: basicBar(),
      body: Container(
          height: screenHeight - 100,
          width: screenWidth,
          color: Colors.orangeAccent,
          child: Container(
            height: screenHeight - 50,
            width: screenWidth,
          )
      )
    );
  }
}