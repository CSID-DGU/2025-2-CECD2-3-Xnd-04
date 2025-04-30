import 'package:flutter/material.dart';
import 'package:Frontend/Models/RefrigeratorModel.dart';
import 'package:Frontend/Views/MainFrameView.dart';

class IngredientsView extends StatefulWidget {
  // 냉장고 객체 자체 변경 x
  final Refrigerator refrigerator;
  const IngredientsView({Key? key, required this.refrigerator}) : super(key: key);

  @override
  State<IngredientsView> createState() => IngredientsPage(refrigerator: refrigerator);
}

class IngredientsPage extends State<IngredientsView> {
  late ScrollController _scrollController;
  final Refrigerator refrigerator;

  IngredientsPage({required this.refrigerator}){
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
        bottomNavigationBar: const MainBottomView(),
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
              Text('${refrigerator.number}', style: TextStyle(fontSize: 20)),
              Text('단수 : ${refrigerator.level}', style: TextStyle(fontSize: 20)),
              Text('사용자 설정명 : ${refrigerator.label}', style: TextStyle(fontSize: 20)),
              Text('모델명 : ${refrigerator.modelName}', style: TextStyle(fontSize: 20))
            ],
          ),
        ),
    );
  }
}