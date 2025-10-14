import 'package:flutter/material.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:Frontend/Widgets/CommonAppBar.dart';

class AccountBookView extends StatefulWidget {
  const AccountBookView({Key? key}) : super(key: key);

  @override
  State<AccountBookView> createState() => AccountBookPage();
}

class AccountBookPage extends State<AccountBookView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: const CommonAppBar(title: 'Xnd'),
      backgroundColor: Colors.white,
      bottomNavigationBar: const MainBottomView(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text('가계부 뷰 입니다.', style: TextStyle(fontSize: 40, color: Colors.grey))
          ]
        )
      )
    );
  }
}
