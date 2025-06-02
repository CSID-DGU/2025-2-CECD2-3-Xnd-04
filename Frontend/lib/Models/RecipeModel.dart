import 'package:Frontend/Abstracts/RecipeAbstract.dart';
import 'package:Frontend/Models/IngredientModel.dart';

List<List<dynamic>?>? Recipes;

class RecipeModel extends RecipeAbstract{
  int? _id;
  String? _recipeName;
  String? _imgUrl;
  List<dynamic> _ingredients = [];
  List<dynamic> _descriptions = [];             // 조리 순서 하드코딩

  RecipeModel({int? id, String? recipeName, String? imgUrl}){
    this._id = id;
    this._recipeName = recipeName;
    this._imgUrl = imgUrl;
  }

  @override
  int? get id => _id;
  String? get recipeName => _recipeName;
  String? get imgUrl => _imgUrl;
  List<dynamic> get ingredients => _ingredients;
  List<dynamic> get descriptions => _descriptions;

  /// 전역변수의 레시피의 ID, 이름, 이미지 URL의 정보를 객체화
  @override
  RecipeModel setRecipe(int idx){
    this._id = Recipes![0]![idx];
    this._recipeName = Recipes![1]![idx];
    this._imgUrl = Recipes![2]![idx];
    return this;
  }
  /// 전역변수의 레시피의 사용되는 식재료와 상세정보를 객체화
  @override
  RecipeModel setDetailRecipe(int idx){
    this._ingredients = Recipes![3]![idx];
    this._descriptions = Recipes![4]![idx];
    return this;
  }
}

class RecipesModel extends RecipesAbstract{
  List<RecipeModel>? _recipes;
  List <RecipeModel>? get recipes => _recipes;

  RecipesModel(List<RecipeModel>? recipes){
    this._recipes = recipes;
  }
}