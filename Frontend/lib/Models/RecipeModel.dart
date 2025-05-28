import 'package:Frontend/Abstracts/RecipeAbstract.dart';
import 'package:Frontend/Models/IngredientModel.dart';

List<List<dynamic>?>? RecipeInfo;

List<Ingredient> _tempIngredients = [
  Ingredient(number: 1, ingredientName: '식재료 1'),
  Ingredient(number: 2, ingredientName: '식재료 2'),
  Ingredient(number: 3, ingredientName: '식재료 3'),
  Ingredient(number: 4, ingredientName: '식재료 4'),
  Ingredient(number: 5, ingredientName: '식재료 5'),
  Ingredient(number: 6, ingredientName: '식재료 6'),
];

List<String> _tempDescriptions = [
  '이 밤 그날의 반딧불을 당신의 창 가까이 보낼게요',
  '사랑한다는 말이에요, 나 우리의 첫 입맞춤을 떠올려',
  '그럼 언제든 눈을 감고 가장 먼 곳으로 가요',
  '난 파도가 머물던 모래 위에 적힌 글씨처럼',
  '그대가 멀리 사라져 버릴 것 같아 늘 그리워, 그리워',
  '여기 내 마음속에 모든 말을 다 꺼내어 줄 순 없지만',
  '사랑한다는 말이에요 어떻게 나에게 그대란 행운이 온 걸까',
  '지금 우리 함께 있다면 아, 얼마나 좋을까요'
];

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
  List<dynamic> get ingredients => [];
  List<dynamic> get descriptions => [];

  /// 전역변수에 레시피의 ID, 이름, 이미지 URL의 정보를 저장
  RecipeModel setRecipe(int idx){
    this._id = RecipeInfo![0]![idx];
    this._recipeName = RecipeInfo![1]![idx];
    this._imgUrl = RecipeInfo![2]![idx];
    return this;
  }

  RecipeModel setDetailRecipe(int idx){
    this._ingredients = RecipeInfo![3]![idx];
    // this._descriptions = RecipeInfo![4]![idx];
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