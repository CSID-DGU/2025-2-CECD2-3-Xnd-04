import 'package:Frontend/Abstracts/RecipeAbstract.dart';
import 'package:Frontend/Models/IngredientModel.dart';
import 'package:flutter/material.dart';

class RecipeModel extends RecipeAbstract{
  int? _recipeNum;
  String? _recipeName;
  List<Ingredient>? _ingredients;
  List<Text>? _descriptions;             // 조리 순서 하드코딩

  RecipeModel({int? recipeNum, String? recipeName, List<Ingredient>? ingredients = null, List<Text>? descriptions = null}){
    this._recipeNum = recipeNum;
    this._recipeName = recipeName;
    this._ingredients = ingredients;
    this._descriptions = descriptions;
  }

  @override
  int? get recipeNum => _recipeNum;
  String? get recipeName => _recipeName;
  List<Ingredient>? get ingredients => _ingredients;
  List<Text>? get descriptions => _descriptions;

  @override
  Map<String, dynamic> toMap(){
    Map<String, dynamic> mapRecipe = {};
    mapRecipe['recipeNum'] = _recipeNum;
    mapRecipe['recipeName'] = _recipeName;
    mapRecipe['ingredients'] = _ingredients;
    mapRecipe['descriptions'] = _descriptions;

    return mapRecipe;
  }
}

class RecipesModel extends RecipesAbstract{
  List<RecipeModel>? _recipes;
  List <RecipeModel>? get recipes => _recipes;

  RecipesModel(){}

  List<Ingredient> _tempIngredients = [
    Ingredient(number: 1, ingredientName: '식재료 1'),
    Ingredient(number: 2, ingredientName: '식재료 2'),
    Ingredient(number: 3, ingredientName: '식재료 3'),
    Ingredient(number: 3, ingredientName: '식재료 4'),
    Ingredient(number: 3, ingredientName: '식재료 5'),
    Ingredient(number: 3, ingredientName: '식재료 6'),
  ];

  @override
  void makeRecipesList({required int num}){
    this._recipes = List.generate(
        num, (idx) => RecipeModel(
          recipeNum: idx + 1,
          recipeName: '레시피 이름 ${idx + 1}',
          ingredients: _tempIngredients
        ),
        growable: false
    );
  }

  void addRecipes(){
    _recipes!.add(RecipeModel(
        recipeNum: _recipes!.length + 1,
        recipeName: '레시피 이름 ${_recipes!.length + 1}',
        ingredients: _tempIngredients)
    );
  }
}