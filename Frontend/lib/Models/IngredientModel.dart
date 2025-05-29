import 'package:flutter/material.dart';
import 'package:Frontend/Abstracts/IngredientAbstract.dart';
import 'package:dio/dio.dart';

class Ingredient implements IngredientAbstract {
  int? _id;
  String? _ingredientName;
  String? _img;
  DateTime? _storedAt;
  DateTime? _storableDue;
  bool? _inCart;

  Ingredient({int? id, String? ingredientName, bool? inCart}){
    this._id = id;
    this._ingredientName = ingredientName;
    this._inCart = inCart;
  }

  @override
  int? get id => _id;
  String? get ingredientName => _ingredientName;
  String? get img => _img;
  DateTime? get storedAt => _storedAt;
  DateTime? get storableDue => _storableDue;
  bool? get inCart => _inCart;

  Ingredient toIngredient(Response ingredientResponse, int idx){
    List<dynamic> data = ingredientResponse!.data['ingredients'];
    this._id = data[idx]['id'];
    this._ingredientName = data[idx]['name'];
    this._inCart = data[idx]['in_cart'];
    return this;
  }
}