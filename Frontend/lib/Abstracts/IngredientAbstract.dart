abstract class IngredientAbstract{
  int? get id;
  String? get ingredientName;
  String? get img;
  DateTime? get storedAt;
  DateTime? get storableDue;
  bool? get inCart;

  // void modify({int? number, String? ingredientName, Image? img});
}