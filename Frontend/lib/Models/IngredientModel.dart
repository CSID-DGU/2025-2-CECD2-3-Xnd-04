import 'package:flutter/material.dart';
import 'package:Frontend/Abstracts/IngredientAbstract.dart';
import 'package:dio/dio.dart';

class IngredientModel implements IngredientAbstract {
  int? _id;
  String? _ingredientName;
  String? _imgUrl;
  bool? _inFridge;
  bool? _inCart;

  IngredientModel({int? id, String? ingredientName, String? imgUrl, bool? inFridge, bool? inCart,String? storageLocation}){
    this._id = id;
    this._ingredientName = ingredientName;
    this._imgUrl = imgUrl;
    this._inFridge = inFridge;
    this._inCart = inCart;
  }

  @override
  int? get id => _id;
  String? get ingredientName => _ingredientName;
  String? get imgUrl => _imgUrl;
  bool? get inFridge => _inFridge;
  bool? get inCart => _inCart;

  @override
  IngredientModel toIngredient(Response ingredientResponse, int idx){
    List<dynamic> data = ingredientResponse.data['ingredients'];
    this._id = data[idx]['id'];
    this._ingredientName = data[idx]['name'];
    // this._imgUrl = data[idx]['ingredient_pic'];
    this._inFridge = data[idx]['in_fridge'];
    this._inCart = data[idx]['in_cart'];
    return this;
  }
}
  

class FridgeIngredientModel extends IngredientModel implements FridgeIngredientAbstract{
  int? _layer;
  String? _stored_at;
  String? _storable_due;
  String? _storageLocation;

  FridgeIngredientModel({
    int? id,
    String? ingredientName,
    String? imgUrl,
    int? layer,
    String? stored_at,
    String? storable_due}) : super(id : id, ingredientName : ingredientName, imgUrl: imgUrl)
  {
    this._layer = layer;
    this._stored_at = stored_at;
    this._storable_due = storable_due;
    
  }

  @override
  int? get layer => _layer;
  String? get stored_at => _stored_at;
  String? get storable_due => _storable_due;
  String? get storageLocation => _storageLocation;

  @override
  FridgeIngredientModel toIngredient(Response ingredientResponse, int idx){
    List<dynamic> data = ingredientResponse.data['ingredients'];
    this._id = data[idx]['id'];
    this._ingredientName = data[idx]['ingredient_name'];
    this._imgUrl = data[idx]['ingredient_pic'];
    return this;
  }

  @override
  FridgeIngredientModel toFridgeIngredient(Response fridgeIngredientResponse, int idx){
    List<dynamic> data = fridgeIngredientResponse.data['ingredients'];
    this._layer = data[idx]['layer'];
    this._stored_at = data[idx]['stored_at'];
    this._storable_due = data[idx]['storable_due'];
    this._storageLocation = data[idx]['storage_location'];
    return this;
  }
}