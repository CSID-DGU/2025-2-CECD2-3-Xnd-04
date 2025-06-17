import 'package:Frontend/Models/IngredientModel.dart';
import 'package:Frontend/Models/RecipeModel.dart';
import 'package:Frontend/Views/IngredientsInfoView.dart';
import 'package:flutter/material.dart';
import '../Services/loadDetailRecipeService.dart';
import '../Services/loadRViewIngredientInfoService.dart';
import '../Views/MainFrameView.dart';
import 'package:Frontend/Models/RefrigeratorModel.dart';
import 'package:Frontend/Services/loadFridgeIngredientInfoService.dart';
import 'package:Frontend/Services/loadRViewIngredientInfoService.dart';
class RecipeDialog extends Dialog{
  RecipeModel? recipe;

  RecipeDialog({required RecipeModel? recipe}){
    this.recipe = recipe;
  }

  /// 기존 위젯에서 팝업 형태로 위젯을 띄움
  /// 위젯이 실시간으로 값을 받아 갱신할 필요가 없기 때문에 Stateless 값을 반환 -> 이 말인 즉슨 setState문을 박을 수 없음
  /// But, 현재 넣어야 하는 함수가 Future 클래스 내부에 없으면 작동하지 않는 함수다!
  /// 그래서 이 문제를 어떻게 해결할까...? 고민중
  Dialog recipeDialog(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double mainContainerWidth = screenWidth * 0.75;
    double mainContainerHeight = screenHeight * 0.8;

    return Dialog(
      child: Container(
        height: mainContainerHeight,
        width: mainContainerWidth,
        padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20)
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              height: screenHeight * 0.07,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: (mainContainerWidth - 40) * 0.8,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(recipe!.recipeName!,
                          style: TextStyle(fontSize: screenHeight * 0.02, fontWeight: FontWeight.bold)
                      )
                    )
                  ),
                  Container(
                    width: (mainContainerWidth - 40) * 0.2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                          onPressed: (){
                            Navigator.of(context).pop();
                          },
                          icon: Icon(Icons.clear, size: screenHeight * 0.02),
                          padding: EdgeInsets.zero
                      )
                    )
                  )
                ]
              )
            ),
            Container(
              height: screenHeight * 0.2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                color: Colors.grey[300],
              ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Image.network(recipe!.imgUrl!, fit: BoxFit.cover),
                )
            ),
            Container(
              height: screenHeight * 0.042,
              margin: EdgeInsets.only(top: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text('식재료',
                      style: TextStyle(fontSize: screenHeight * 0.015, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                      width: mainContainerWidth - 40,
                      child: Divider(color: Colors.black, thickness: 1.5),
                  ),
                ],
              )
            ),
            // 가변적인 크기의 위젯을 자동으로 개행해줌
            Container(
              width: mainContainerWidth - 40,
              child: Wrap(
                direction: Axis.horizontal,
                alignment: WrapAlignment.start,
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  for(IngredientModel ingredient in recipe!.ingredients!)
                    Container(
                      height: screenHeight * 0.015,
                      child: ElevatedButton(
                        onPressed: () async {
                          Map<String, dynamic>? ingredientDetailInfo;

                          // 식재료가 냉장고에 있는 경우

                          if (ingredient.inFridge == true){
                            int fiid = 0;
                            int fridgeIndex = 0;
                            while(fiid == 0 && fridgeIndex < numOfFridge!){
                              fiid = await getFIID(RefrigeratorModel().getFridge(fridgeIndex), ingredient);
                              fridgeIndex += 1;
                            }
                            fridgeIndex -= 1;
                            ingredientDetailInfo = await loadRecipeModalIngredientsInfo(
                                RefrigeratorModel().getFridge(fridgeIndex).id!, fiid
                            );
                          }

                          List<RecipeDetailModel>? recipedetails = await getRecipeDetailInfoFromServer(ingredient);
                          pages[6] = IngredientsInfoView(
                              recipedetails : recipedetails!,
                              ingredient: ingredient,
                              inform: ingredientDetailInfo
                          );
                          // 식재료 소개 페이지로 이동
                          Navigator.of(context).pushNamed('/' + pages[6].toString());
                        },
                        style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                            // (0, 255, 212, 1)
                            backgroundColor:
                              (ingredient.inFridge == true) ?
                              Color.fromRGBO(255, 183, 77, 1) :
                              Color.fromRGBO(255, 183, 77, 0.5)
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,              // 이미지 + 텍스트 사이즈에 버튼 크기 맞추기
                          children: <Widget>[
                            Text(ingredient.ingredientName!,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenHeight * 0.01)
                            ),
                            SizedBox(width: 10),
                            Image.asset('assets/images/cart.png', width: screenHeight * 0.01, height: screenHeight * 0.01, fit: BoxFit.cover),
                          ],
                        ),
                      ),
                    )
                ],
              ),
            ),
            Container(
              height: screenHeight * 0.042,
              margin: EdgeInsets.only(top: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Align(
                    alignment: Alignment.topLeft,
                    child:
                    Text('레시피',
                      style: TextStyle(fontSize: screenHeight * 0.015, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    width: mainContainerWidth - 40,
                    child: Divider(color: Colors.black, thickness: 2.5),
                  ),
                ],
              )
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    for (int idx = 0; idx < recipe!.descriptions!.length; idx++)
                      Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(width: 10),
                            Flexible(
                                child: Text((idx + 1).toString() + '. ' + recipe!.descriptions![idx],
                                    style: TextStyle(color: Colors.black, fontSize: screenHeight * 0.013)
                                )
                            )
                          ]
                      )
                  ],
                ),
              )
            )
          ]
        ),
      )
    );
  }
}