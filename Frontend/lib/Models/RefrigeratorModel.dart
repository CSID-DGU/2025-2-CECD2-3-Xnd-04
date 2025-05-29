import 'package:Frontend/Abstracts/RefrigeratorAbstract.dart';
import 'package:Frontend/Models/IngredientModel.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:flutter/material.dart';

int? numOfFridge;
List<dynamic> fridges = [];

class Refrigerator implements RefrigeratorAbstract{
  int? _id;
  int? _level;
  String? _label;
  List<List<dynamic>>? _ingredientStorage;            // 층수에 들어온 순서대로 식재료를 인덱스에 저장, 층수별로 식재료가 없는 인덱스는 null값

  Refrigerator({int? id, int? level, String? label}){
    this._id = id;
    this._level = level;
    this._label = label;
  }

  @override
  int? get id => _id;
  int? get level => _level;
  String? get label => _label;
  List<List<dynamic>>? get ingredientStorage => _ingredientStorage;

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

  @override
  void setIngredientStorage(){
    this._ingredientStorage = List.generate(
        level!,
        (i) => List.generate(17, (i) => null),
        growable: false
    );
    for(int i = 0; i < level!; i++)
      _ingredientStorage![i][16] = 0;
    // 남은 인덱스는 현재 있는 식재료의 수로 처리함
  }

  @override
  int getNumOfIngredientsFloor({required int floor}){
    return _ingredientStorage![floor - 1][16];
  }
}
