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

}

abstract class RecipesAbstract{}