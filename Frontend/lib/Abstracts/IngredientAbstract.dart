import 'package:dio/dio.dart';

abstract class IngredientAbstract{
  int? get id;
  String? get ingredientName;
  String? get imgUrl;

  dynamic toIngredient(Response ingredientResponse, int idx);
}

abstract class FridgeIngredientAbstract extends IngredientAbstract{
  int? get layer;
  String? get stored_at;
  String? get storable_due;

  @override
  dynamic toIngredient(Response ingredientResponse, int idx);
  dynamic toFridgeIngredient(Response fridgeIngredientResponse, int idx);
}