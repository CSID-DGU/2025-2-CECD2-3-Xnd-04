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
  int levelOfRefrigerator = 0;

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
            const mainAppBar(),
            SizedBox(height: screenHeight / 2 - 200),

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
                height: 300,
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
                              if (levelOfRefrigerator > 0) {
                                levelOfRefrigerator -= 1;
                              }
                            });
                          },
                            child: Image.asset(
                                'assets/images/minus.png', width: 70,
                                height: 70),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: const CircleBorder(),
                            ),
                          ),
                          SizedBox(width: 90, height: 70, child: Text(
                            levelOfRefrigerator.toString(),
                            style: const TextStyle(fontSize: 50),
                            textAlign: TextAlign.center,)),
                          ElevatedButton(onPressed: () async {
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
                      SizedBox(height: 80,),
                      SizedBox(
                          height: 70,
                          width: 120,
                          child: ElevatedButton(onPressed: () {
                            setState(() {
                              refrigerators.add(Refrigerator(
                                  number: numOfRefrigerator + 1,
                                  level: levelOfRefrigerator,
                                  label: '${numOfRefrigerator + 1}번 냉장고',
                                  modelName: 'R${numOfRefrigerator + 1}')
                              );
                              pages[1] = IngredientsView(refrigerator: refrigerators[numOfRefrigerator]);
                              Navigator.of(context).pushNamed('/' + pages[5].toString());
                              numOfRefrigerator += 1;
                              isPlusButtonClicked = false;
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
                                  fontWeight: FontWeight.bold, fontSize: 20))
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
    double boxSize = screenHeight * 0.25;

    return Scaffold(
        appBar: basicBar(),
        backgroundColor: Colors.white,
        bottomNavigationBar: const MainBottomView(),
        body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const mainAppBar(),
            Container(
              height: screenHeight - 150,
              child: PageView.builder(
                  controller: PageController(),
                  itemCount: refrigerators.length + 1,
                  itemBuilder: (context, index) =>
                      Container(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(height: screenHeight / 3 - 50),

                              if (index != refrigerators.length) Text('${index + 1}번 냉장고',style: TextStyle(fontSize: 30))
                              else Text('냉장고 추가',style: TextStyle(fontSize: 30)),

                              SizedBox(height: 70),

                              if (index != refrigerators.length)
                                ElevatedButton(
                                  onPressed: () async {
                                    setState(() {
                                      isPlusButtonClicked = true;
                                      pages[1] = IngredientsView(refrigerator: refrigerators[index]);
                                      Navigator.of(context).pushNamed('/' + pages[1].toString());
                                    });
                                  },
                                  child: Image.asset('assets/refrigerators/R${index + 1}.png', width: 300, height: 300),
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