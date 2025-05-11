import 'package:Frontend/Models/IngredientModel.dart';
import 'package:Frontend/Models/RecipeModel.dart';
import 'package:Frontend/Views/IngredientsInfoView.dart';
import 'package:flutter/material.dart';

import '../Views/MainFrameView.dart';

class RecipeDialog extends Dialog{
  RecipeModel? _recipe;

  RecipeDialog({required RecipeModel? recipe}){
    this._recipe = recipe;
  }


  Dialog recipeDialog(BuildContext context){
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double mainContainerWidth = screenWidth * 0.85;
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
              height: screenHeight * 0.04,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: (mainContainerWidth - 40) * 0.5,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(_recipe!.recipeName!,
                          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)
                      )
                    )
                  ),
                  Container(
                    width: (mainContainerWidth - 40) * 0.5,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                          onPressed: (){
                            Navigator.of(context).pop();
                          },
                          icon: Icon(Icons.clear, size: 25),
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
                // 이미지 추가
              ),
            ),
            Container(
              height: 45,
              margin: EdgeInsets.only(top: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text('식재료',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                      width: mainContainerWidth - 40,
                      child: Divider(color: Colors.black, thickness: 2.5),
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
                  for(Ingredient ingredient in _recipe!.ingredients!)
                    ElevatedButton(
                      onPressed: (){
                        pages[6] = IngredientsInfoView(ingredient: ingredient);
                        // 식재료 소개 페이지로 이동
                        Navigator.of(context).pushNamed('/' + pages[6].toString());
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,              // 이미지 + 텍스트 사이즈에 버튼 크기 맞추기
                        children: <Widget>[
                          Text(ingredient.ingredientName!,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)
                          ),
                          SizedBox(width: 10),
                          Image.asset('assets/images/cart.png', width: 20, height: 20, fit: BoxFit.cover),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.fromLTRB(5, 0, 5, 0)
                      )
                    ),
                ],
              ),
            ),
            Container(
              height: 45,
              margin: EdgeInsets.only(top: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Align(
                    alignment: Alignment.topLeft,
                    child:
                    Text('레시피',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    width: mainContainerWidth - 40,
                    child: Divider(color: Colors.black, thickness: 2.5),
                  ),
                ],
              )
            ),
            Flexible(
                fit: FlexFit.tight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    for (int idx = 0; idx < _recipe!.descriptions!.length; idx++)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(width: 10),
                          Flexible(
                              child: Text((idx + 1).toString() + '. ' + _recipe!.descriptions![idx],
                                  style: TextStyle(color: Colors.black, fontSize: 20)
                              )
                          )
                        ]
                      )
                  ],
                )
            ),
          ]
        ),
      )
    );
  }
}