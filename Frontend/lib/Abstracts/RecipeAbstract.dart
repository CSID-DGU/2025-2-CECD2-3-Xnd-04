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
  dynamic getRecipe(int idx);
  /// 전역변수에 레시피에 사용되는 식재료와 상세정보를 저장, return : RecipeModel(this)
  dynamic getDetailRecipe(int idx);
}

abstract class RecipeDetailAbstract extends RecipeAbstract{
  String? get servingSize;
  String? get cookingTime;
  String? get difficulty;
  bool? get isSaved;

  /// 레시피의 상세정보를 저장하여 관련 데이터를 담은 객체 반환, return : RecipeDetailModel(this)
  dynamic toRecipeDetail(Response recipeDetailResponse, int idx);
}

abstract class RecipesAbstract{

}