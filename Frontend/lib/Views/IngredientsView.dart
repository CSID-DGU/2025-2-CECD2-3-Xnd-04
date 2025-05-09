import 'package:flutter/material.dart';
import 'package:Frontend/Models/RefrigeratorModel.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'dart:math';

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

    // 변동성있는 냉장고의 전체 사이즈를 구하는 알고리즘(20 더한건 모든 층에서 전부 20만큼 오버플로우 나서 더한거임)
    double getRefrigeratorSize(){
      double size = 20 + 0.05 * screenHeight * refrigerator.level!;
      for(int floor = 1; floor <= refrigerator.level!; floor++) {
        (refrigerator.getNumOfIngredientsFloor(floor: floor) == 0) ?
        size += screenHeight * 0.125
            :
        size += screenHeight * 0.125 *
            (refrigerator.getNumOfIngredientsFloor(floor: floor) * 0.25).ceil();
      }
      return size;
    }

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

          // 그리드 뷰 구축 예정
          child: ListView(
            controller: _scrollController,
            children: <Widget>[
              mainAppBar(name:'${refrigerator.number}번 냉장고'),
              Container(
                height : getRefrigeratorSize(),           //교체
                margin : EdgeInsets.all(20),
                decoration: BoxDecoration
                (
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color:Colors.grey,
                      style: BorderStyle.solid,
                      width: 10)
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    for (int floor = refrigerator.level!; floor > 0; floor--)
                      // 이 부분 그리드 형식으로 사이즈 어떻게 들어가는 지 예상하기
                      Container(
                        height: (refrigerator.getNumOfIngredientsFloor(floor: floor) == 0) ?
                          screenHeight * 0.175
                        :
                          screenHeight * 0.125 *
                            (refrigerator.getNumOfIngredientsFloor(floor: floor) * 0.25).ceil() +
                            screenHeight * 0.05,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              margin : EdgeInsets.fromLTRB(20, 0, 20, 0),
                              height: screenHeight * 0.03,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    width: (screenWidth - 100) * 0.15,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.grey,
                                        style: BorderStyle.solid,
                                        width: 3
                                      )
                                    ),
                                    child: Text('${floor}층',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenHeight * 0.01),
                                      textAlign: TextAlign.center,)
                                  ),
                                  Container(
                                    width: (screenWidth - 100) * 0.6,
                                  ),
                                  Container(
                                    width: (screenWidth - 100) * 0.25,
                                    child: ElevatedButton(
                                        onPressed: () async {
                                        setState(() {
                                          refrigerator.addNumOfIngredientsFloor(context, floor: floor);
                                          Navigator.of(context).pushNamed('/' + pages[1].toString());
                                        });
                                      },
                                        style: ElevatedButton.styleFrom(
                                          shape: const CircleBorder(),
                                          backgroundColor: Colors.yellow,
                                        ),
                                        child: Image.asset('assets/images/levelplus.png')
                                    ),
                                  )
                                ],
                              )
                            ),          // 층수 안내 컨테이너
                            Container(
                              margin : EdgeInsets.fromLTRB(20, 0, 20, 0),
                              height: (refrigerator.getNumOfIngredientsFloor(floor: floor) == 0) ?
                                screenHeight * 0.125
                                  :
                                screenHeight * 0.125 *
                                  (refrigerator.getNumOfIngredientsFloor(floor: floor) * 0.25).ceil(), //교체
                              child:
                                GridView.builder(
                                  physics: NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: 1/((0.5 * screenHeight - 40)/(screenWidth - 130))
                                  ),
                                    itemCount: refrigerator.getNumOfIngredientsFloor(floor: floor),
                                    itemBuilder: (context, index) => Container(
                                      decoration: BoxDecoration(
                                        color: Colors.primaries[Random().nextInt(Colors.primaries.length)],
                                        borderRadius: BorderRadius.circular(30)
                                      ),
                                    ),
                                  ),
                            ), // 식재료 컨테이너
                            Container(
                                margin : EdgeInsets.fromLTRB(20, 0, 20, 0),
                                height: screenHeight * 0.02,
                                decoration: BoxDecoration(
                                  color: Color(0x809E9E9E),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                            ),          // 층별로 쪼개는 컨테이너
                          ], // 프레임을 쪼개는 곳, 즉 여기에 들어가야 할 위젯은 3개
                        )
                      )  // 냉장고 한 층에 적용되는 위젯 사이즈
                  ],  // 층수를 나누는 즉, 여기에 들어가야 할 위젯은 RL개
                )
              )     // 전체 냉장고
            ],
          ),
        ),
    );
  }
}