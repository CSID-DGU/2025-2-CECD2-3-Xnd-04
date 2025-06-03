// https://velog.io/@ssh0407/Dart-abstract-Class-mixin
import 'package:flutter/material.dart';

import '../Models/IngredientModel.dart';

abstract class RefrigeratorAbstract{
  int? get id;
  int? get level;
  String? get label;
  List<FridgeIngredientModel>? get ingredients;

  void modify({int? level, String? label});
  Map<String, dynamic> toMap();

  /// 전역변수에 냉장고의 ID, 이름, 라벨의 정보를 저장, return : RefrigeratorModel(this)
  dynamic getFridge(int index);
  void toMainFridgeIngredientsInfo(int index);

  void setIngredientStorage(List<FridgeIngredientModel> ingredients);
  int getNumOfIngredientsFloor({required int floor});
}

abstract class RefrigeratorsAbstract{

}