class CartItemModel {
  int? id;
  int? ingredientId;
  String? ingredientName;
  int? recipeId;
  String? recipeName;
  String? quantity;

  CartItemModel({
    this.id,
    this.ingredientId,
    this.ingredientName,
    this.recipeId,
    this.recipeName,
    this.quantity,
  });

  // JSON에서 CartItemModel로 변환
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'],
      ingredientId: json['ingredient_id'],
      ingredientName: json['ingredient_name'],
      recipeId: json['recipe_id'],
      recipeName: json['recipe_name'],
      quantity: json['quantity']?.toString(),
    );
  }

  // CartItemModel을 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ingredient_id': ingredientId,
      'ingredient_name': ingredientName,
      'recipe_id': recipeId,
      'recipe_name': recipeName,
      'quantity': quantity,
    };
  }
}

// 전역 장바구니 데이터
List<CartItemModel>? cartItems;
