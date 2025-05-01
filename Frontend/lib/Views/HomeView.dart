import 'package:flutter/material.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:Frontend/Views/IngredientsView.dart';
import 'package:Frontend/Models/RefrigeratorModel.dart';

bool isPlusButtonClicked = false;
List<Refrigerator> refrigerators = [];
int numOfRefrigerator = refrigerators.length;

class InitialHomeView extends StatefulWidget {
  const InitialHomeView({Key? key}) : super(key: key);

  @override
  State<InitialHomeView> createState() => InitialHomePage();
}

class InitialHomePage extends State<InitialHomeView> {
  int levelOfRefrigerator = 1;

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
            SizedBox(height: screenHeight * 0.35),

            (!isPlusButtonClicked) ?

            Container(
              child: ElevatedButton(
                onPressed: () async {
                  setState(() {
                    isPlusButtonClicked = true;
                  });
                },
                child: Image.asset(
                    'assets/images/plus.png', width: 200, height: 200),
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
                    width: 10,
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
                          SizedBox(width: screenWidth * 0.15, height: 60, child: Text(
                            levelOfRefrigerator.toString(),
                            style: const TextStyle(fontSize: 50),
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
                                'assets/images/levelplus.png', width: 70,
                                height: 70),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: const CircleBorder(),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 50,),
                      SizedBox(
                          height: screenHeight * 0.05,
                          width: screenWidth * 0.2,
                          child: ElevatedButton(onPressed: () {
                            setState(() {
                              refrigerators.add(Refrigerator(
                                  number: numOfRefrigerator + 1,
                                  level: levelOfRefrigerator,
                                  label: '${numOfRefrigerator + 1}번 냉장고',
                                  modelName: 'R${numOfRefrigerator + 1}')
                              );    // 냉장고 추가
                              refrigerators[numOfRefrigerator].makeIngredientStorage();    // 냉장고 식재료 저장소 생성
                              pages[1] = IngredientsView(refrigerator: refrigerators[numOfRefrigerator]);    // 위젯 갱신
                              Navigator.of(context).pushNamed('/' + pages[5].toString());
                              numOfRefrigerator += 1;
                              isPlusButtonClicked = false;    // + 버튼 체크 여부
                            });
                          },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pinkAccent[100],
                                side:
                                BorderSide(
                                  width: 5,
                                ),
                                shape:
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text('확  인', style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 30))
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
              height: screenHeight * 0.88,
              child: PageView.builder(
                  controller: PageController(),
                  itemCount: refrigerators.length + 1,
                  itemBuilder: (context, index) =>
                      Container(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(height: screenHeight * 0.28),

                              if (index != refrigerators.length) Text('${index + 1}번 냉장고',style: TextStyle(fontSize: 30))
                              else Text('냉장고 추가',style: TextStyle(fontSize: 30)),

                              SizedBox(height: screenHeight * 0.05),

                              if (index != refrigerators.length)
                                ElevatedButton(
                                  onPressed: () async {
                                    setState(() {
                                      isPlusButtonClicked = true;
                                      pages[1] = IngredientsView(refrigerator: refrigerators[index]);
                                      Navigator.of(context).pushNamed('/' + pages[1].toString());
                                    });
                                  },
                                  child: Image.asset('assets/refrigerators/R${index + 1}.png', width: 250, height: 250),
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
                                  child: Image.asset('assets/images/plus.png', width: 200, height: 200),
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