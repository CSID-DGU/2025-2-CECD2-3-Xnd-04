import 'package:flutter/material.dart';
import 'package:Frontend/Abstracts/kakaoLogin.dart';
import 'package:Frontend/Models/LoginModel.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import '../Models/IngredientModel.dart';
import '../Models/RecipeModel.dart';
import 'package:Frontend/MordalViews/RecipeMordal.dart';

import '../Services/createSavedRecipeService.dart';
import '../Services/loadIngredientService.dart';
import '../Services/loadRecipeQueryService.dart';
import '../Services/loadRecipeService.dart';

class FavoritesView extends StatefulWidget {
  const FavoritesView({Key? key}) : super(key: key);

  @override
  State<FavoritesView> createState() => FavoritesPage();
}

class FavoritesPage extends State<FavoritesView> {
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();
  late ScrollController _scrollController;

  RecipesModel? savedRecipeStorage;

  /// 레시피 끌어오기
  void getListedSavedRecipes(){
    List<RecipeModel> savedrecipes = [];
    for(int i = 0; i < SavedRecipes![0]!.length; i++)
      savedrecipes.add(RecipeModel().getSavedRecipe(i));
    savedRecipeStorage = RecipesModel(savedrecipes);
  }

  FavoritesPage(){
    super.initState();
    getListedSavedRecipes();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    if(!nav3Processed){
      getListedSavedRecipes();
      nav3Processed = true;
    }

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
                    style: TextStyle(color: Colors.black, fontSize: screenHeight * 0.02),
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical:10),
                      hintText: (_searchQuery.isEmpty) ? '레시피 검색' : null,
                      hintStyle: TextStyle(color: Colors.grey[700], fontSize: screenHeight * 0.015, fontWeight: FontWeight.bold),
                      prefixIcon: IconButton(
                        icon: Icon(Icons.search, color: Colors.grey[700]),
                        onPressed: () async {
                          _searchController.clear();
                          for(int i = 0; i < SavedRecipes!.length; i++)
                            SavedRecipes![i]!.clear();
                          SavedRecipes = await getSavedRecipeQueryInfoFromServer(query:_searchQuery);
                          setState(() {
                            // 레시피 뷰에서 어디로 쏠건지...
                            getListedSavedRecipes();
                          });
                        },
                      ),
                      suffixIcon: (_searchController.text.isNotEmpty)
                          ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.red, size: screenHeight * 0.02),
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
                  height: screenHeight * 0.78,
                  child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      interactive: true,
                      child: ListView(
                          controller: _scrollController,
                          children: <Widget>[
                            // 실제론 DB에서 랜덤으로 추천돌려서 레시피로 띄워줌
                            for(RecipeModel savedrecipe in savedRecipeStorage!.recipes!)
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
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(30),
                                          child: Image.network(savedrecipe.imgUrl!, fit: BoxFit.cover),
                                        )
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
                                          onPressed: () {
                                            setState(() async {
                                              int recipeIdx = await getIngredientInfoFromServer(savedrecipe, true);
                                              savedrecipe.getDetailSavedRecipe(recipeIdx);
                                              // 이 부분에 모달 창
                                              RecipeDialog recipedialog = RecipeDialog(recipe: savedrecipe);
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
                                                            flex: 2,
                                                            fit: FlexFit.tight,
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                              children: <Widget>[
                                                                SizedBox(width: 15),
                                                                Flexible(
                                                                  child: Text(savedrecipe.recipeName!,
                                                                    style: TextStyle(
                                                                      color: Colors.black,
                                                                      fontWeight: FontWeight.bold,
                                                                      fontSize: screenHeight * 0.012
                                                                    )
                                                                  ),
                                                                )
                                                              ]
                                                            )
                                                          ),
                                                          Flexible(
                                                            flex: 3,
                                                            fit: FlexFit.tight,
                                                            child: SizedBox()
                                                          ),
                                                        ],
                                                      )
                                                  ),
                                                ),
                                                Flexible(
                                                  flex: 1,
                                                  fit: FlexFit.tight,
                                                  child: Container(
                                                    padding: EdgeInsets.only(top: 20),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(30),
                                                    ),
                                                    child: Align(
                                                        alignment: Alignment.topCenter,
                                                        child: GestureDetector(
                                                            onTap: () async {
                                                              await createSavedRecipe(recipe : savedrecipe);
                                                              setState((){
                                                                deleteSavedRecipe(savedrecipe : savedrecipe);
                                                                for (int i = 0; i < Recipes![0]!.length; i++) {
                                                                  if (Recipes![0]![i] == savedrecipe.id) {
                                                                    Recipes![3]![i] = false;
                                                                    break;
                                                                  }
                                                                }
                                                                getListedSavedRecipes();
                                                              });
                                                            },
                                                            child: Image.asset('assets/hearts/filledheart.png', height: 20, width: 20)
                                                        )
                                                    )
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