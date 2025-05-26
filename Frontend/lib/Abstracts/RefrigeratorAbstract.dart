// https://velog.io/@ssh0407/Dart-abstract-Class-mixin
import 'package:flutter/material.dart';

abstract class RefrigeratorAbstract{
  int? get id;
  int? get level;
  String? get label;
  String? get modelName;

  void getRefrigerator();
  void modify({int? level, String? label});
  Map<String, dynamic> toMap();
  void makeIngredientStorage();
  int getNumOfIngredientsFloor({required int floor});
  void addNumOfIngredientsFloor(BuildContext context, {required int floor});
}