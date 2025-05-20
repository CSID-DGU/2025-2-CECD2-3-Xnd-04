import 'package:flutter/material.dart';
import 'package:Frontend/Models/IngredientModel.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:flutter_colorful_tab/flutter_colorful_tab.dart';

class IngredientsInfoView extends StatelessWidget{
  Ingredient? _ingredient;

  IngredientsInfoView({Key? key, required ingredient}) : super(key : key){
    this._ingredient = ingredient;
  }

  Widget build(BuildContext context){

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
            backBar(),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: screenWidth * 0.5 - 30,
                  height: screenHeight * 0.05,
                  margin: EdgeInsets.only(left: 30),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_ingredient!.ingredientName!,
                      style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold)
                    )
                  )
                ),
                Container(
                  width: screenWidth * 0.5 - 30,
                  height: screenHeight * 0.05,
                  margin: EdgeInsets.only(right: 30),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: screenWidth * 0.15,
                      height: screenHeight * 0.03,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(20)
                      ),
                    )
                  )
                ),
              ],
            ),
            Container(
              width: screenWidth * 0.6,
              height: screenHeight * 0.25,
              padding: EdgeInsets.all(20),
              child: Image.asset('assets/refrigerators/R1.png', fit: BoxFit.fill)
            ),
            Container(
              width: screenWidth - 60,
              height: screenHeight * 0.07,
              margin: EdgeInsets.fromLTRB(30, 30, 30, 25),
              padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20)
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.add_card_rounded, size: screenWidth * 0.05),
                  SizedBox(width : screenWidth * 0.05),
                  Text('입고일', style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.05)),
                  Container(
                    width: screenWidth * 0.75 - 100,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('2025년 4월 8일',
                        style: TextStyle(
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold,
                        )
                      )
                    )
                  )
                ],
              )
            ),
            Container(
              width: screenWidth - 60,
              height: screenHeight * 0.07,
              margin: EdgeInsets.fromLTRB(30, 0, 30, 25),
              padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
              decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20)
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.access_time_filled, size: screenWidth * 0.05),
                  SizedBox(width : screenWidth * 0.05),
                  Text('보관일', style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.05)),
                  Container(
                    width: screenWidth * 0.75 - 100,
                    child: Align(
                        alignment: Alignment.centerRight,
                        child: Text('2025년 4월 20일', style: TextStyle(
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold,
                        )
                      )
                    )
                  )
                ],
              )
            ),
            Container(
              height: screenHeight * 0.44 - 105,
              width: screenWidth - 60,
              child: DefaultTabController(
                length: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    ColorfulTabBar(
                      indicatorHeight: 0.1,
                      topPadding: 0,
                      alignment: TabAxisAlignment.start,
                      tabs: [
                        TabItem(color: Colors.red, title: Text('Home', style: TextStyle(fontSize: screenWidth * 0.03),)),
                        TabItem(color: Colors.green, title: Text('Favorite', style: TextStyle(fontSize: screenWidth * 0.03),)),
                        TabItem(color: Colors.orange, title: Text('Search', style: TextStyle(fontSize: screenWidth * 0.03),)),
                      ]
                    ),
                    Container(
                      height: screenHeight * 0.2,
                      width : screenWidth - 60,
                      child: TabBarView(
                        children: <Widget>
                        [
                          Container(
                            width: screenWidth - 60,
                            height: screenHeight * 0.15,
                            color: Colors.red,
                          ),
                          Container(
                            width: screenWidth - 60,
                            height: screenHeight * 0.15,
                            color: Colors.green,
                          ),
                          Container(
                            width: screenWidth - 60,
                            height: screenHeight * 0.15,
                            color: Colors.orange,
                          ),
                        ]
                      )
                    )
                  ]
                )
              )
            )
          ]
        )
      )
    );
  }
}