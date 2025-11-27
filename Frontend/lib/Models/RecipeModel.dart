import 'package:Frontend/Abstracts/RecipeAbstract.dart';
import 'package:Frontend/Models/IngredientModel.dart';
import 'package:dio/dio.dart';

/// 화면에 띄워주는 count개의 레시피만 한정해서 저장
/// Index structure:
/// 0: recipe_id, 1: food_name, 2: recipe_image, 3: is_saved
/// 4: cooking_time, 5: serving_size, 6: cooking_level
/// 7: category2, 8: category3, 9: category4
/// 10: ingredients (detail), 11: descriptions (detail)
List<List<dynamic>?>? Recipes;

/// 화면에 띄워주는 count개의 즐찾 레시피만 한정해서 저장
List<List<dynamic>?>? SavedRecipes = [[], [], [], [], [], [], [], [], [], [], [], []];

void addSavedRecipe(int idx){
  SavedRecipes![0]!.add(Recipes![0]![idx]);
  SavedRecipes![1]!.add(Recipes![1]![idx]);
  SavedRecipes![2]!.add(Recipes![2]![idx]);
  SavedRecipes![3]!.add(Recipes![3]![idx]);
  SavedRecipes![4]!.add(Recipes![4]![idx]);
  SavedRecipes![5]!.add(Recipes![5]![idx]);
  SavedRecipes![6]!.add(Recipes![6]![idx]);
  SavedRecipes![7]!.add(Recipes![7]![idx]);
  SavedRecipes![8]!.add(Recipes![8]![idx]);
  SavedRecipes![9]!.add(Recipes![9]![idx]);
}

void addDetailSavedRecipe(int idx){
  SavedRecipes![10]!.add(Recipes![10]![idx]);
  SavedRecipes![11]!.add(Recipes![11]![idx]);
}
/// 전역 SavedRecipe에 저장된 변수들을 삭제하는 전역 함수(RecipeModel)
void deleteSavedRecipe({required RecipeModel savedrecipe}){
  // 즐겨찾기로 저장된 레시피 수
  for(int i = 0; i < SavedRecipes![0]!.length; i++) {
    // 현재 삭제하고자 하는 레시피가 프론트에서 관리하는 SavedRecipe에 저장된 경우
    if (SavedRecipes![0]![i] == savedrecipe.id){
      for (int j = 0; j < 12; j++) {
        // 디테일 뷰에 진입하지 않고 SavedRecipe에 접근한 경우
        if (SavedRecipes![j]!.length == 0)
          break;
        SavedRecipes![j]!.removeAt(i);
      }
      break;
    }
  }
}

class RecipeModel implements RecipeAbstract{
  int? _id;
  String? _recipeName;
  String? _imgUrl;
  bool? _isSaved;
  List<dynamic> _ingredients = [];
  List<dynamic> _descriptions = [];             // 조리 순서 하드코딩
  String? _cookingTime;
  String? _servingSize;
  String? _cookingLevel;
  String? _category2;
  String? _category3;
  String? _category4;

  RecipeModel({
    int? id,
    String? recipeName,
    String? imgUrl,
    bool? isSaved,
    String? cookingTime,
    String? servingSize,
    String? cookingLevel,
    String? category2,
    String? category3,
    String? category4,
  }){
    this._id = id;
    this._recipeName = recipeName;
    this._imgUrl = imgUrl;
    this._isSaved = isSaved;
    this._cookingTime = cookingTime;
    this._servingSize = servingSize;
    this._cookingLevel = cookingLevel;
    this._category2 = category2;
    this._category3 = category3;
    this._category4 = category4;
  }

  @override
  int? get id => _id;
  String? get recipeName => _recipeName;
  String? get imgUrl => _imgUrl;
  bool? get isSaved => _isSaved;
  List<dynamic> get ingredients => _ingredients;
  List<dynamic> get descriptions => _descriptions;
  String? get cookingTime => _cookingTime;
  String? get servingSize => _servingSize;
  String? get cookingLevel => _cookingLevel;
  String? get category2 => _category2;
  String? get category3 => _category3;
  String? get category4 => _category4;

  /// 전역변수의 레시피의 ID, 이름, 이미지 URL의 정보를 객체화
  @override
  RecipeModel getRecipe(int idx){
    this._id = Recipes![0]![idx];
    this._recipeName = Recipes![1]![idx];
    this._imgUrl = Recipes![2]![idx];
    this._isSaved = Recipes![3]![idx];
    this._cookingTime = Recipes![4]![idx];
    this._servingSize = Recipes![5]![idx];
    this._cookingLevel = Recipes![6]![idx];
    this._category2 = Recipes![7]![idx];
    this._category3 = Recipes![8]![idx];
    this._category4 = Recipes![9]![idx];
    return this;
  }
  /// 전역변수의 레시피의 사용되는 식재료와 상세정보를 객체화
  @override
  RecipeModel getDetailRecipe(int idx){
    this._ingredients = Recipes![10]![idx];
    this._descriptions = Recipes![11]![idx];
    return this;
  }

  @override
  RecipeModel getSavedRecipe(int idx){
    this._id = SavedRecipes![0]![idx];
    this._recipeName = SavedRecipes![1]![idx];
    this._imgUrl = SavedRecipes![2]![idx];
    this._isSaved = SavedRecipes![3]![idx];
    this._cookingTime = SavedRecipes![4]![idx];
    this._servingSize = SavedRecipes![5]![idx];
    this._cookingLevel = SavedRecipes![6]![idx];
    this._category2 = SavedRecipes![7]![idx];
    this._category3 = SavedRecipes![8]![idx];
    this._category4 = SavedRecipes![9]![idx];
    return this;
  }

  @override
  RecipeModel getDetailSavedRecipe(int idx){
    this._ingredients = SavedRecipes![10]![idx];
    this._descriptions = SavedRecipes![11]![idx];
    return this;
  }
}

class RecipeDetailModel extends RecipeModel implements RecipeDetailAbstract{
  String? _servingSize;
  String? _cookingTime;
  String? _difficulty;

  @override
  String? get servingSize => _servingSize;
  String? get cookingTime => _cookingTime;
  String? get difficulty => _difficulty;

  RecipeDetailModel({
    int? id,
    String? recipeName,
    String? imgUrl,
    String? servingSize,
    String?
    cookingTime,
    String? difficulty,
    bool? isSaved
    }) : super(id : id, recipeName : recipeName, imgUrl : imgUrl){
    this._servingSize = servingSize;
    this._cookingTime = cookingTime;
    this._difficulty = difficulty;
  }

  @override
  RecipeDetailModel toRecipeDetail(Response recipeDetailResponse, int idx){
    List<dynamic> data = recipeDetailResponse.data['results'];

    this._id = data[idx]['id'];
    this._recipeName = data[idx]['food_name'];
    this._servingSize = data[idx]['serving_size'];
    this._cookingTime = data[idx]['cooking_time'];
    this._difficulty = data[idx]['cooking_level'];

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

