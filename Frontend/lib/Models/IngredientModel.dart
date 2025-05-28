import 'package:flutter/material.dart';
import 'package:Frontend/Abstracts/IngredientAbstract.dart';

class Ingredient implements IngredientAbstract {
  int? _id;
  int? _number;
  String? _ingredientName;
  Image? _img;

  Ingredient({int? id, int? number, String? ingredientName, Image? img = null}){
    this._id = id;
    this._number = number;
    this._ingredientName = ingredientName;
    this._img = img;
  }

  @override
  int? get id => _id;
  int? get number => _number;
  String? get ingredientName => _ingredientName;
  Image? get img => _img;

  @override
  void modify({int? number, String? ingredientName, Image? img}){
    if(number != null)
      this._number = number;
    if(ingredientName != null)
      this._ingredientName = ingredientName;
    if(img != null)
      this._img = img;
  }

  @override
  Map<String, dynamic> toMap(){
    Map<String, dynamic> mapIngredient = {};
    mapIngredient['number'] = _number;
    mapIngredient['ingredientName'] = _ingredientName;
    mapIngredient['img'] = _img;

    return mapIngredient;
  }
}