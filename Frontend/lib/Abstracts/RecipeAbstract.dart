import 'package:Frontend/Models/IngredientModel.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
// 제작된 음식의 종류에 따라 상속하여 레시피 확장
abstract class RecipeAbstract{
  int? get id;
  String? get recipeName;
  List<dynamic> get ingredients;
  List<dynamic> get descriptions;
  String? get imgUrl;

  /// 전역변수에 레시피의 ID, 이름, 이미지 URL의 정보를 저장, return : RecipeModel(this)
  dynamic setRecipe(int idx);
  /// 전역변수에 레시피에 사용되는 식재료와 상세정보를 저장, return : RecipeModel(this)
  dynamic setDetailRecipe(int idx);
}

abstract class RecipesAbstract{

}