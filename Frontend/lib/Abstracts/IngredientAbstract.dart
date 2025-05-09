import 'package:flutter/material.dart';

abstract class IngredientAbstract{
  int? get number;
  String? get ingredientName;
  Image? get img;

  void modify({int? number, String? ingredientName, Image? img});

  Map<String, dynamic> toMap();
}