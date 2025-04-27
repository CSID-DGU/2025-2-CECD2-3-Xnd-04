import 'package:flutter/material.dart';
import 'package:Frontend/Login/kakaoLogin.dart';
import 'package:Frontend/Models/LoginModel.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:Frontend/Views/IngredientsView.dart';

bool isButtonClicked = false;

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => HomePage();
}

class HomePage extends State<HomeView> {
  static var Refrigerators = [-1];
  int numOfRefrigerator = Refrigerators.length - 1;
  int levelOfRefrigerator = 1;

  @override
  Widget build(BuildContext context) {

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    int boxSize = (numOfRefrigerator < 4)? 200 : 250;

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
            SizedBox(width: screenWidth * 0.8, height: screenHeight / 2 - boxSize),

            (!isButtonClicked) ?

              Container(
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        isButtonClicked = true;
                        numOfRefrigerator += 1;});
                      },
                    child: Image.asset('assets/images/plus.png', width: 200, height: 200),
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
                decoration: BoxDecoration(// Container의 배경색
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    width: 10,
                    color: Colors.black,// 테두리 두께
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
                              if(levelOfRefrigerator > 0){
                                levelOfRefrigerator -= 1;
                              }
                            });
                            },
                            child: Image.asset('assets/images/minus.png', width: 70, height: 70),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: const CircleBorder(),
                            ),
                          ),
                          SizedBox(width: 90, height: 70, child: Text(
                              levelOfRefrigerator.toString(),
                              style: const TextStyle(fontSize: 50), textAlign: TextAlign.center,)),
                          ElevatedButton(onPressed: () async {
                            setState(() {
                              if(levelOfRefrigerator < 6){
                                levelOfRefrigerator += 1;
                              }
                            });
                          },
                            child: Image.asset('assets/images/levelplus.png', width: 70, height: 70),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: const CircleBorder(),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 80,),
                      SizedBox(
                        height : 70,
                        width : 120,
                        child : ElevatedButton(onPressed: () {
                          setState(() {
                            Refrigerators.add(levelOfRefrigerator);
                            pages[1] = IngredientsView(levelOfRefrigerator: Refrigerators[numOfRefrigerator]);
                            print('현재 냉장고 수 : ${Refrigerators.length - 1}');
                            Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (i) => pages[0]
                                )
                            );
                            isButtonClicked = false;
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
                          child: Text('확  인', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))
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