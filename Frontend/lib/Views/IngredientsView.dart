import 'package:flutter/material.dart';
import 'package:Frontend/Abstracts/kakaoLogin.dart';
import 'package:Frontend/Models/LoginModel.dart';
import 'package:Frontend/Views/MainFrameView.dart';

class IngredientsView extends StatefulWidget {
  final int levelOfRefrigerator;
  const IngredientsView({Key? key, required this.levelOfRefrigerator}) : super(key: key);

  @override
  State<IngredientsView> createState() => IngredientsPage(levelOfRefrigerator: levelOfRefrigerator);
}

class IngredientsPage extends State<IngredientsView> {
  late ScrollController _scrollController;
  final int levelOfRefrigerator;

  IngredientsPage({required this.levelOfRefrigerator}){
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
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
        body: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          trackVisibility: true,
          interactive: true,

          child: ListView(
            controller: _scrollController,
            children: [
              mainAppBar(),
              Text('냉장고 뷰 입니다.', style: TextStyle(fontSize: 40)),
              Text('현재 냉장고 단수 : ${levelOfRefrigerator}', style: TextStyle(fontSize: 40))
            ],
          ),
        ),
    );
  }
}