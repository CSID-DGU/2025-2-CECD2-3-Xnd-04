import 'package:flutter/material.dart';
import 'package:Frontend/Abstracts/kakaoLogin.dart';
import 'package:Frontend/Models/LoginModel.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import '../Models/IngredientModel.dart';
import '../Models/RecipeModel.dart';
import 'package:Frontend/MordalViews/RecipeMordal.dart';

class FavoritesView extends StatefulWidget {
  const FavoritesView({Key? key}) : super(key: key);

  @override
  State<FavoritesView> createState() => FavoritesPage();
}

class FavoritesPage extends State<FavoritesView> {
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();
  late ScrollController _scrollController;
  RecipesModel recipeStorage = RecipesModel();

  FavoritesPage(){
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  List<String> getIngredientsType(){
    List<String> str = [];
    str.add('');
    List<RecipeModel>? recipes = recipeStorage.recipes;

    for(RecipeModel recipe in recipes!){
      String temp = '';
      for(Ingredient ingredient in recipe.ingredients!){
        temp += ingredient.ingredientName!;
        temp += ', ';
      }
      str.add(temp);
    }

    return str;
  }

  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    recipeStorage.makeRecipesList(num: 10);

    //올바르게 작동하려면 레시피를 꾸준히 업데이트 하는 방식으로 수정해야함
    List<RecipeModel>? recipes = recipeStorage.recipes;
    List<String> ingredientsTypes = getIngredientsType();

    return Scaffold(
      // 냉장고 선택 페이지 UI
      appBar: basicBar(),
      backgroundColor: Colors.white,
      bottomNavigationBar: const MainBottomView(),
      body: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                mainAppBar(name:'   Xnd'),
                Container(
                  height: screenHeight * 0.04,
                  margin: EdgeInsets.fromLTRB(20, screenHeight * 0.01, 20, screenHeight * 0.01),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: Colors.black, fontSize: 25),
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: (_searchQuery.isEmpty) ? '레시피 검색' : null,
                      hintStyle: TextStyle(color: Colors.grey[700], fontSize: 25, fontWeight: FontWeight.bold),
                      prefixIcon: IconButton(
                        icon: Icon(Icons.search, color: Colors.grey[700]),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            // 레시피 뷰에서 어디로 쏠건지...
                          });
                        },
                      ),
                      suffixIcon: (_searchController.text.isNotEmpty)
                          ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = _searchController.text;
                          });
                        },
                      ) : null,
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                Container(
                  height: screenHeight * 0.83,
                  child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      interactive: true,
                      child: ListView(
                          controller: _scrollController,
                          children: <Widget>[
                            // 실제론 DB에서 랜덤으로 추천돌려서 레시피로 띄워줌
                            for(RecipeModel recipe in recipes!)
                              Container(
                                  margin: EdgeInsets.all(20),
                                  height: screenHeight * 0.18,
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      // 레시피 이미지
                                      Container(
                                        margin: EdgeInsets.fromLTRB((screenWidth - 40) * 0.03, 0, (screenWidth - 40) * 0.04, 0),
                                        width: (screenWidth - 40) * 0.3,
                                        height: (screenWidth - 40) * 0.3,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                      // 레시피 설명
                                      Container(
                                        margin: EdgeInsets.fromLTRB(0, 0, (screenWidth - 40) * 0.03, 0),
                                        width: (screenWidth - 40) * 0.6,
                                        height: (screenWidth - 40) * 0.3,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        child: FilledButton(
                                          onPressed: (){
                                            setState(() {
                                              // 이 부분에 모달 창
                                              RecipeDialog recipedialog = RecipeDialog(recipe: recipe);
                                              showDialog(
                                                  context: context,
                                                  builder: (context) => recipedialog.recipeDialog(context)
                                              );
                                            });
                                          },
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                            padding: EdgeInsets.zero,
                                          ),
                                          child: Row(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              children: <Widget>[
                                                Flexible(
                                                  flex: 2,
                                                  fit: FlexFit.tight,
                                                  child: Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.circular(30),
                                                      ),
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.start,
                                                        children: <Widget>[
                                                          Flexible(
                                                              flex: 1,
                                                              fit: FlexFit.tight,
                                                              child: Row(
                                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                                  children: <Widget>[
                                                                    SizedBox(width: 10),
                                                                    Text(recipe.recipeName!,
                                                                        style: TextStyle(
                                                                            color: Colors.black,
                                                                            fontWeight: FontWeight.bold
                                                                        )
                                                                    ),
                                                                  ]
                                                              )
                                                          ),
                                                          Flexible(
                                                              flex: 4,
                                                              fit: FlexFit.tight,
                                                              child: Column(
                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                children: <Widget>[
                                                                  // 컨테이너에서 텍스트 위치 설정하는 테크닉, 잘 기억해두길...
                                                                  Row(
                                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                                      children: <Widget>[
                                                                        SizedBox(width: 10),
                                                                        Flexible(
                                                                            child: Text(ingredientsTypes[recipe.recipeNum!],
                                                                                style: TextStyle(color: Colors.black)
                                                                            )
                                                                        )
                                                                      ]
                                                                  )
                                                                ],
                                                              )
                                                          ),
                                                        ],
                                                      )
                                                  ),
                                                ),
                                                Flexible(
                                                  flex: 1,
                                                  fit: FlexFit.tight,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(30),
                                                    ),
                                                  ),
                                                ),
                                              ]
                                          ),
                                        ),
                                      )
                                    ],
                                  )
                              )
                          ]
                      )
                  ),
                ),
              ]
          )
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}