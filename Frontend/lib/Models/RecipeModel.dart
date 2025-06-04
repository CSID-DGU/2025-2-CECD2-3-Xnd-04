import 'package:Frontend/Abstracts/RecipeAbstract.dart';
import 'package:Frontend/Models/IngredientModel.dart';
import 'package:dio/dio.dart';

/// 화면에 띄워주는 10개의 레시피만 한정해서 저장
List<List<dynamic>?>? Recipes;

class RecipeModel implements RecipeAbstract{
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
  RecipeModel getRecipe(int idx){
    this._id = Recipes![0]![idx];
    this._recipeName = Recipes![1]![idx];
    this._imgUrl = Recipes![2]![idx];
    return this;
  }
  /// 전역변수의 레시피의 사용되는 식재료와 상세정보를 객체화
  @override
  RecipeModel getDetailRecipe(int idx){
    this._ingredients = Recipes![3]![idx];
    this._descriptions = Recipes![4]![idx];
    return this;
  }
}

class RecipeDetailModel extends RecipeModel implements RecipeDetailAbstract{
  String? _servingSize;
  String? _cookingTime;
  String? _difficulty;
  bool? _isSaved;

  @override
  String? get servingSize => _servingSize;
  String? get cookingTime => _cookingTime;
  String? get difficulty => _difficulty;
  bool? get isSaved => _isSaved;

  RecipeDetailModel({int? id,
    String? recipeName,
    String? imgUrl,
    String? servingSize,
    String?
    cookingTime,
    String? difficulty,
    bool? isSaved}) : super(id : id, recipeName : recipeName, imgUrl : imgUrl){
    this._servingSize = servingSize;
    this._cookingTime = cookingTime;
    this._difficulty = difficulty;
    this._isSaved = isSaved;
  }

  @override
  RecipeDetailModel toRecipeDetail(Response recipeDetailResponse, int idx){
    List<dynamic> data = recipeDetailResponse.data['results'];

    this._id = data[idx]['id'];
    this._recipeName = data[idx]['food_name'];
    this._servingSize = data[idx]['serving_size'];
    this._cookingTime = data[idx]['cooking_time'];
    this._difficulty = data[idx]['cooking_level'];
    this._isSaved = data[idx]['is_saved'];

    return this;
  }
}


class RecipesModel implements RecipesAbstract{
  List<RecipeModel>? _recipes;
  List <RecipeModel>? get recipes => _recipes;

  RecipesModel(List<RecipeModel>? recipes){
    this._recipes = recipes;
  }
}

