import 'package:flutter/material.dart';
import 'package:Frontend/Models/IngredientModel.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:flutter_colorful_tab/flutter_colorful_tab.dart';

import '../Models/RecipeModel.dart';

class IngredientsInfoView extends StatelessWidget{
  IngredientModel? _ingredient;
  /// DB의 냉장고에 식재료 정보가 있는가??
  Map<String, dynamic>? _inform;
  List<RecipeDetailModel>? _recipeDetails;

  IngredientsInfoView({Key? key, required List<RecipeDetailModel> recipedetails, required IngredientModel ingredient, Map<String, dynamic>? inform}) : super(key : key){
    this._ingredient = ingredient;
    this._inform = inform;
    this._recipeDetails = recipedetails;
  }

  /// 유통기한 구하기
  int getDueDate(){
    DateTime now = DateTime.now();
    DateTime dueDateParsed = DateTime.parse(this._inform!['storable_due'].substring(0, 10));
    return dueDateParsed.difference(now).inDays + 1;
  }

  Widget build(BuildContext context){

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    int dueDate = (_inform != null) ? getDueDate(): -1;
    List<MaterialColor> tabbarColor = [Colors.red, Colors.blue, Colors.yellow];

    Container recipeInfoDescription(RecipeDetailModel recipedetail){
      return Container(
          padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: (screenWidth - 80) * 0.8,
                    height: screenHeight * 0.05,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(recipedetail.recipeName!, style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold))
                    )
                  ),
                  Container(
                    width: (screenWidth - 80) * 0.2,
                    height: screenHeight * 0.05,
                    child: Align(
                        alignment: Alignment.centerRight,
                        child: Icon(Icons.star_border, size: screenWidth * 0.04)
                    )
                  )
                ],
              ),
              Container(
                height: 1.5,
                child: Divider(
                  color: Colors.grey[300]
                )
              ),
              Container(
                height: screenHeight * 0.02,
                color: Colors.grey[100],
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Icon(Icons.aspect_ratio, size: screenWidth * 0.03,)
                )
              ),
              Container(
                height: screenHeight * 0.38 - 152,
                width: screenWidth - 80,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('1. 양 : ${recipedetail.servingSize}',
                        style: TextStyle(fontSize: screenWidth * 0.03))
                    ),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text('2. 조리 시간 : ${recipedetail.cookingTime}',
                          style: TextStyle(fontSize: screenWidth * 0.03))
                    ),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text('3. 난이도 : ${recipedetail.difficulty}',
                          style: TextStyle(fontSize: screenWidth * 0.03))
                    )
                  ]
                )
              )
            ],
          )
      );
    }

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
                  width: screenWidth * 0.7 - 30,
                  height: screenHeight * 0.05,
                  margin: EdgeInsets.only(left: 30),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(this._ingredient!.ingredientName!,
                      style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold)
                    )
                  )
                ),
                Container(
                  width: screenWidth * 0.3 - 30,
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
                      child: (_inform != null) ? Align(
                          alignment: Alignment.center,
                          child: (dueDate < 0) ?
                            Text('폐기', style: TextStyle(fontWeight: FontWeight.bold)):
                            Text(dueDate.toString() + '일', style: TextStyle(fontWeight: FontWeight.bold))
                          ) : null
                    )
                  )
                ),
              ],
            ),
            Container(
              width: screenWidth * 0.6,
              height: screenHeight * 0.25,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(30)
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: (_inform != null) ? Image.network(_inform!['ingredient_pic'], fit: BoxFit.fill) : null
              )
            ),
            Container(
              width: screenWidth - 60,
              height: screenHeight * 0.07,
              margin: EdgeInsets.fromLTRB(30, 20, 30, 20),
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
                      child: (_inform != null) ?
                        Text(_inform!['stored_at'].substring(0, 10), style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold)) :
                        Text('미입고 상품', style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold))
                    )
                  )
                ],
              )
            ),
            Container(
              width: screenWidth - 60,
              height: screenHeight * 0.07,
              margin: EdgeInsets.fromLTRB(30, 0, 30, 20),
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
                        child: (_inform != null) ?
                        Text(_inform!['storable_due'].substring(0, 10), style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold)) :
                        Text('미입고 상품', style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold))
                    )
                  )
                ],
              )
            ),
            Container(
              height: screenHeight * 0.44 - 85,
              width: screenWidth - 60,
              child: DefaultTabController(
                length: this._recipeDetails!.length,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    ColorfulTabBar(
                      indicatorHeight: 0.1,
                      topPadding: 0,
                      alignment: TabAxisAlignment.start,
                      tabs: [
                        for (int i = 0; i < this._recipeDetails!.length; i++)
                          TabItem(
                              color: tabbarColor[i],
                              title: Text('${i + 1}번 레시피',
                                style: TextStyle(
                                    fontSize: screenWidth * 0.03,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold
                                )
                              )
                          )
                      ]
                    ),
                    Container(
                      height: screenHeight * 0.44 - 133,
                      width : screenWidth - 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10)
                      ),
                      child: TabBarView(
                        children: <Widget>
                        [
                          for (int i = 0; i < this._recipeDetails!.length; i++)
                            recipeInfoDescription(this._recipeDetails![i])
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

class FridgeIngredientsInfoView extends StatelessWidget{
  FridgeIngredientModel? _ingredient;
  List<RecipeDetailModel>? _recipeDetails;

  FridgeIngredientsInfoView({Key? key, required List<RecipeDetailModel> recipedetails, required ingredient}) : super(key : key){
    this._ingredient = ingredient;
    this._recipeDetails = recipedetails;
  }

  /// 유통기한 구하기
  int getDueDate(){
    DateTime now = DateTime.now();
    DateTime dueDateParsed = DateTime.parse(this._ingredient!.storable_due!.substring(0, 10));
    return dueDateParsed.difference(now).inDays + 1;
  }

  Widget build(BuildContext context){

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    int dueDate = getDueDate();
    List<MaterialColor> tabbarColor = [Colors.red, Colors.blue, Colors.yellow];

    Container recipeInfoDescription(RecipeDetailModel recipedetail){
      return Container(
          padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Container(
                      width: (screenWidth - 80) * 0.8,
                      height: screenHeight * 0.05,
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(recipedetail.recipeName!, style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold))
                      )
                  ),
                  Container(
                      width: (screenWidth - 80) * 0.2,
                      height: screenHeight * 0.05,
                      child: Align(
                          alignment: Alignment.centerRight,
                          child: Icon(Icons.star_border, size: screenWidth * 0.04)
                      )
                  )
                ],
              ),
              Container(
                  height: 1.5,
                  child: Divider(
                      color: Colors.grey[300]
                  )
              ),
              Container(
                  height: screenHeight * 0.02,
                  color: Colors.grey[100],
                  child: Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.aspect_ratio, size: screenWidth * 0.03,)
                  )
              ),
              Container(
                  height: screenHeight * 0.38 - 152,
                  width: screenWidth - 80,
                  // child: Text(rDesc, style: TextStyle(fontSize: screenWidth * 0.03, fontWeight: FontWeight.bold), textAlign: TextAlign.left,)
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Text('1. 양 : ${recipedetail.servingSize}', style: TextStyle(fontSize: screenWidth * 0.03))
                        ),
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Text('2. 조리 시간 : ${recipedetail.cookingTime}', style: TextStyle(fontSize: screenWidth * 0.03))
                        ),
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Text('3. 난이도 : ${recipedetail.difficulty}', style: TextStyle(fontSize: screenWidth * 0.03))
                        )
                      ]
                  )
              )
            ],
          )
      );
    }

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
                          width: screenWidth * 0.7 - 30,
                          height: screenHeight * 0.05,
                          margin: EdgeInsets.only(left: 30),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(this._ingredient!.ingredientName!,
                                  style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold)
                              )
                          )
                      ),
                      Container(
                          width: screenWidth * 0.3 - 30,
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
                                child: Align(
                                  alignment: Alignment.center,
                                  child: (dueDate < 0) ?
                                    Text('폐기', style: TextStyle(fontWeight: FontWeight.bold)):
                                    Text(dueDate.toString() + '일', style: TextStyle(fontWeight: FontWeight.bold))
                                )
                              )
                          )
                      ),
                    ],
                  ),
                  Container(
                      width: screenWidth * 0.6,
                      height: screenHeight * 0.25,
                      padding: EdgeInsets.all(20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(this._ingredient!.imgUrl!, fit: BoxFit.cover),
                      )
                  ),
                  Container(
                      width: screenWidth - 60,
                      height: screenHeight * 0.07,
                      margin: EdgeInsets.fromLTRB(30, 20, 30, 20),
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
                                  child: Text(this._ingredient!.stored_at!.substring(0, 10),
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
                      margin: EdgeInsets.fromLTRB(30, 0, 30, 20),
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
                                  child: Text(this._ingredient!.storable_due!.substring(0, 10),
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
                      height: screenHeight * 0.44 - 85,
                      width: screenWidth - 60,
                      child: DefaultTabController(
                          length: this._recipeDetails!.length,
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                ColorfulTabBar(
                                    indicatorHeight: 0.1,
                                    topPadding: 0,
                                    alignment: TabAxisAlignment.start,
                                    tabs: [
                                      for (int i = 0; i < this._recipeDetails!.length; i++)
                                        TabItem(
                                            color: tabbarColor[i],
                                            title: Text('${i + 1}번 레시피',
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.03,
                                                  color: Colors.orange,
                                                  fontWeight: FontWeight.bold
                                                )
                                            )
                                        )
                                    ]
                                ),
                                Container(
                                    height: screenHeight * 0.44 - 133,
                                    width : screenWidth - 60,
                                    decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(10)
                                    ),
                                    child: TabBarView(
                                        children: <Widget>
                                        [
                                          for (int i = 0; i < this._recipeDetails!.length; i++)
                                            recipeInfoDescription(this._recipeDetails![i])
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