import 'package:flutter/material.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:Frontend/Views/IngredientsView.dart';
import 'package:Frontend/Models/RefrigeratorModel.dart';
import 'package:Frontend/Services/createFridgeService.dart';
import 'package:Frontend/Services/loadFridgeService.dart';

bool isPlusButtonClicked = false;
List<Refrigerator> refrigerators = [];
int numOfRefrigerator = refrigerators.length;

class InitialHomeView extends StatefulWidget {
  const InitialHomeView({Key? key}) : super(key: key);

  @override
  State<InitialHomeView> createState() => InitialHomePage();
}

class InitialHomePage extends State<InitialHomeView> {
  int levelOfRefrigerator = 1;             // 냉장고 추가할 때 사용하는 변수

  @override
  Widget build(BuildContext context) {

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // 냉장고가 0개인 경우 UI
    return Scaffold(
      // 냉장고 선택 페이지 UI
      appBar: basicBar(),
      backgroundColor: Colors.white,
      bottomNavigationBar: const MainBottomView(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            mainAppBar(name:'   Xnd'),
            SizedBox(height: screenHeight * 0.3),

            (!isPlusButtonClicked) ?

            Container(
              child: ElevatedButton(
                onPressed: () async {
                  setState(() {
                    isPlusButtonClicked = true;
                  });
                },
                child: Image.asset(
                    'assets/images/plus.png', width: screenHeight * 0.15, height: screenHeight * 0.15),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: const CircleBorder(),
                ),
              ),
            )
                :

            Container(
                width: screenWidth * 0.7,
                height: screenHeight * 0.2,
                decoration: BoxDecoration( // Container의 배경색
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    width: 5,
                    color: Colors.black, // 테두리 두께
                  ),
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          ElevatedButton(onPressed: () async {
                            setState(() {
                              if (levelOfRefrigerator > 1) {
                                levelOfRefrigerator -= 1;
                              }
                            });
                          },
                            child: Image.asset(
                                'assets/images/minus.png', width: screenWidth * 0.11,
                                height: screenWidth * 0.11),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: const CircleBorder(),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.15, height: screenHeight * 0.062, child: Text(
                            levelOfRefrigerator.toString(),
                            style: TextStyle(fontSize: screenHeight * 0.06),
                            textAlign: TextAlign.center,)),
                          ElevatedButton(
                            onPressed: () async {
                            setState(() {
                              if (levelOfRefrigerator < 6) {
                                levelOfRefrigerator += 1;
                              }
                            });
                          },
                            child: Image.asset(
                                'assets/images/levelplus.png', width: screenWidth * 0.11,
                                height: screenWidth * 0.11),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: const CircleBorder(),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.05),
                      SizedBox(
                          height: screenHeight * 0.05,
                          width: screenWidth * 0.2,
                          child: ElevatedButton(
                              onPressed: () {
                                setState(() async {
                                  // 냉장고 추가
                                  bool sendCreateToServer = await createFridgeToServer(refrigerator: Refrigerator(level: levelOfRefrigerator, label: '${numOfFridge! + 1}번 냉장고'));      // 냉장고 추가 요청
                                  if (sendCreateToServer) {
                                    bool isArrivedFridgesInfo = await getFridgesInfo();                    // 냉장고 정보 수령 요청
                                    if (isArrivedFridgesInfo) {
                                      refrigerators[numOfFridge! - 1].makeIngredientStorage(); // 냉장고 식재료 저장소 생성
                                      pages[1] = IngredientsView(refrigerator: refrigerators[numOfFridge! - 1]); // 위젯 갱신
                                      Navigator.of(context).pushNamed('/' + pages[5].toString());
                                      isPlusButtonClicked = false; // + 버튼 체크 여부
                                    }
                                    else{
                                      await Future.delayed(Duration.zero);
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text('냉장고 정보 수령 불가'),     // 이멀전씨~~ 페이징 닥털 빝~!!
                                          content: Text('서버 오류로 인해 냉장고를 로드할 수 없습니다.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(),
                                              child: Text('돌아가기'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  }
                                  else{
                                    await Future.delayed(Duration.zero);
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('서버 요청 불가'),     // 이멀전씨~~ 페이징 닥털 빝~!!
                                        content: Text('서버 오류로 인해 요청이 불가합니다.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: Text('돌아가기'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pinkAccent[100],
                                side: BorderSide(width: 2.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: Text('확 인', style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: screenHeight * 0.015))
                          )
                      )
                    ]
                )
            )
          ],
        ),
      ),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => HomePage();
}

class HomePage extends State<HomeView> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
        appBar: basicBar(),
        backgroundColor: Colors.white,
        bottomNavigationBar: const MainBottomView(),
        body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            mainAppBar(name:'   Xnd'),
            Container(
              height: screenHeight * 0.84,
              child: PageView.builder(
                  controller: PageController(),
                  itemCount: refrigerators.length + 1,
                  itemBuilder: (context, index) =>
                      Container(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(height: screenHeight * 0.28),

                              if (index != refrigerators.length)
                                Text('${refrigerators[index].id}번 냉장고',
                                  style: TextStyle(fontSize: screenHeight * 0.025))
                              else
                                Text('냉장고 추가',
                                  style: TextStyle(fontSize: screenHeight * 0.025)),

                              SizedBox(height: screenHeight * 0.05),

                              if (index != refrigerators.length)
                                ElevatedButton(
                                  onPressed: () async {
                                    setState(() {
                                      pages[1] = IngredientsView(refrigerator: refrigerators[index]);
                                      Navigator.of(context).pushNamed('/' + pages[1].toString());
                                    });
                                  },
                                  child: Image.asset('assets/refrigerators/R1.png',
                                      width: screenHeight * 0.23,
                                      height: screenHeight * 0.23),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shape: const CircleBorder(),
                                  ),
                                )

                              else
                                ElevatedButton(
                                  onPressed: () async {
                                    setState(() {
                                      isPlusButtonClicked = true;
                                      Navigator.of(context).pushNamed('/' + pages[0].toString());
                                    });
                                  },
                                  child: Image.asset('assets/images/plus.png',
                                      width: screenHeight * 0.15,
                                      height: screenHeight * 0.15),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shape: const CircleBorder(),
                                  ),
                                )
                            ]
                        ),
                      ),
              ),
            ),
          ]
        )
      )
    );
  }
}