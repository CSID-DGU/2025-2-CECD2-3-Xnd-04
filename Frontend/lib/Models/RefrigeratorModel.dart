import 'package:Frontend/Abstracts/RefrigeratorAbstract.dart';
import 'package:Frontend/Models/IngredientModel.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:flutter/material.dart';

class Refrigerator implements RefrigeratorAbstract{
  int? _id;
  int? _level;
  String? _label;
  String? _modelName;
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
  String? get modelName => _modelName;
  get ingredientStorage => _ingredientStorage;

  @override
  void modify({int? level, String? label}){
    if (level != null)
      this._level = level;
    if (label != null)
      this._label = label;
  }

  // 단순 객체 리턴(필요할 지는 모르겠음)
  @override
  Refrigerator getRefrigerator(){
    return this;
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
  void makeIngredientStorage(){
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

  // 이걸 이제 DB에 식재료가 추가될때 마다 수정하는 방식 ㄱㄱ
  @override
  void addNumOfIngredientsFloor(BuildContext context, {required int floor}) async {
    if(_ingredientStorage![floor - 1][16] < 16) {
      _ingredientStorage![floor - 1][16] += 1;

      int num = this.getNumOfIngredientsFloor(floor: floor);
      _ingredientStorage![floor - 1][num - 1] = Ingredient(number: num, ingredientName: '식재료 ${num}');
    }
    else{
      await Future.delayed(Duration.zero); // 안정화 타이밍 삽입
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Emergency~~ Paging Dr.Beat'),     // 이멀전씨~~ 페이징 닥털 빝~!!
          content: Text('${floor}층은 현재 최대 수용가능 재료 수를 초과했습니다. 최대 재료 수 : 16'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('돌아가기'),
            ),
          ],
        ),
      );
    }
  }
}
