import 'package:Frontend/Abstracts/RefrigeratorAbstract.dart';
import 'package:Frontend/Models/IngredientModel.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:flutter/material.dart';

int? numOfFridge;
List<RefrigeratorModel> Fridges = [];

class RefrigeratorModel implements RefrigeratorAbstract{
  int? _id;
  int? _level;
  String? _label;
  List<FridgeIngredientModel>? _ingredients;            // 층수에 들어온 순서대로 식재료를 인덱스에 저장, 층수별로 식재료가 없는 인덱스는 null값

  RefrigeratorModel({int? id, int? level, String? label}){
    this._id = id;
    this._level = level;
    this._label = label;
  }

  @override
  int? get id => _id;
  int? get level => _level;
  String? get label => _label;
  List<FridgeIngredientModel>? get ingredients => _ingredients;

  @override
  void modify({int? level, String? label}){
    if (level != null)
      this._level = level;
    if (label != null)
      this._label = label;
  }

  // 단일 냉장고 데이터 JSON 형식으로 매핑
  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> mapRefrigerator = {};
    mapRefrigerator['layer_count'] = _level;
    mapRefrigerator['model_label'] = _label;
    return mapRefrigerator;
  }
  /// 전역변수로 저장된 냉장고의 데이터 로드하기!
  @override
  RefrigeratorModel getFridge(int index){
    this._id = Fridges[index].id;
    this._level = Fridges[index].level;
    this._label = Fridges[index].label;
    this._ingredients = Fridges[index].ingredients;
    return this;
  }

  /// 냉장고 전역변수로 냉장고의 식재료 정보 전달
  @override
  void toMainFridgeIngredientsInfo(int index){
    Fridges[index]._ingredients = this._ingredients;
  }

  // 냉장고의 식재료 저장소를 세팅
  @override
  void setIngredientStorage(List<FridgeIngredientModel> ingredients){
    this._ingredients = ingredients;
  }

  @override
  int getNumOfIngredientsFloor({required int floor}){
    int count = 0;
    if (this._ingredients != null) {
      for (int i = 0; i < this._ingredients!.length; i++)
        if (this._ingredients![i]!.layer == floor)
          count += 1;
    }
    return count;
  }
}
