import 'package:Frontend/Abstracts/RefrigeratorAbstract.dart';

class Refrigerator implements RefrigeratorAbstract{
  int? _number;
  int? _level;
  String? _label;
  String? _modelName;

  Refrigerator(int? number, int? level, String? label, String? modelName){
    this._number = number;
    this._level = level;
    this._label = label;
    this._modelName = modelName;
  }

  @override
  int? get number => _number;
  int? get level => _level;
  String? get label => _label;
  String? get modelName => _modelName;

  @override
  void modify({int? number, int? level, String? label, String? modelName}){
    if (number != null)
      this._number = number;
    if (level != null)
      this._level = level;
    if (label != null)
      this._label = label;
    if (modelName != null)
      this._modelName = modelName;
  }

  @override
  Refrigerator getRefrigerator(){
    return this;
  }
}
