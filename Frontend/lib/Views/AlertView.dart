import 'package:flutter/material.dart';
import 'package:Frontend/Views/LoginView.dart';


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
    return Scaffold();
  }
}