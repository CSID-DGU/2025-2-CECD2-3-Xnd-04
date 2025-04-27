import 'package:flutter/material.dart';
import 'package:Frontend/Login/kakaoLogin.dart';
import 'package:Frontend/Models/LoginModel.dart';
import 'package:Frontend/Views/MainFrameView.dart';

class CartView extends StatefulWidget {
  const CartView({Key? key}) : super(key: key);

  @override
  State<CartView> createState() => CartPage();
}

class CartPage extends State<CartView> {
  final loginViewModel = LoginModel(KakaoLogin());

  @override
  void initState() {
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      // 냉장고 선택 페이지 UI
        appBar: basicBar(),
        backgroundColor: Colors.white,
        bottomNavigationBar: MainBottomView(),
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  const mainAppBar(),
                  Text('장바구니 뷰 입니다.', style: TextStyle(fontSize: 40))
                ]
            )
        )
    );
  }
}