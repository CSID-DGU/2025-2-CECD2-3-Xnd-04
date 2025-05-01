// https://velog.io/@ssh0407/Dart-abstract-Class-mixin
import 'package:flutter/material.dart';

abstract class RefrigeratorAbstract{
  int? get number;
  int? get level;
  String? get label;
  String? get modelName;

  void getRefrigerator();
  void modify({int? number, int? level, String? label, String? modelName});
  Map<String, dynamic> toMap();
  void makeIngredientStorage();
  int getNumOfIngredientsFloor({required int floor});
  void addNumOfIngredientsFloor(BuildContext context, {required int floor});
}