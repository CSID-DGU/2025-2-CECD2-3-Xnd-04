// https://velog.io/@ssh0407/Dart-abstract-Class-mixin

abstract class RefrigeratorAbstract{
  int? get number;
  int? get level;
  String? get label;
  String? get modelName;

  void getRefrigerator();
  void modify({int? number, int? level, String? label, String? modelName});
}