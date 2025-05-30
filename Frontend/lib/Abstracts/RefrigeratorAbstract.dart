// https://velog.io/@ssh0407/Dart-abstract-Class-mixin
import 'package:flutter/material.dart';

abstract class RefrigeratorAbstract{
  int? get id;
  int? get level;
  String? get label;

  void modify({int? level, String? label});
  Map<String, dynamic> toMap();
  void setIngredientStorage();
  int getNumOfIngredientsFloor({required int floor});
}