import 'package:Frontend/Models/RecipeModel.dart';
import 'package:flutter/material.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:Frontend/Widgets/CommonAppBar.dart';
import '../Models/IngredientModel.dart';
import 'package:Frontend/MordalViews/RecipeMordal.dart';
import 'package:Frontend/Services/loadRecipeService.dart';
import 'package:Frontend/Views/RecipeDetailView.dart';

import '../Services/createFridgeService.dart';
import '../Services/createSavedRecipeService.dart';
import '../Services/loadIngredientService.dart';
import '../Services/loadRecipeQueryService.dart';
import '../Services/searchHistoryService.dart';

class RecipeView extends StatefulWidget {
  const RecipeView({Key? key}) : super(key: key);

  @override
  State<RecipeView> createState() => RecipePage();
}

class RecipePage extends State<RecipeView> {
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();
  late ScrollController _scrollController;

  /// 페이지를 새로 로드할때마다 레시피 저장소를 받아오는 클래스 내 변수
  RecipesModel? recipeStorage;

  /// 프론트 전역 레시피 끌어오기
  void getListedRecipes(){
    if (Recipes == null || Recipes![0] == null) return;
    List<RecipeModel> recipes = [];
    for(int i = 0; i < Recipes![0]!.length; i++)
      recipes.add(RecipeModel().getRecipe(i));
    recipeStorage = RecipesModel(recipes);
  }
  /// 프론트 전역 레시피 업데이트
  void updateRecipeSaved({required RecipeModel recipe}){
    if (Recipes == null || Recipes![0] == null || Recipes![3] == null) return;
    for(int i = 0; i < Recipes![0]!.length; i++){
      if(recipe.id == Recipes![0]![i]){
        Recipes![3]![i] = !Recipes![3]![i];
        break;
      }
    }
  }

  RecipePage(){
    super.initState();
    getListedRecipes();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 검색 결과 뷰 - 하단바 1번 활성화
    currentBottomNavIndex = 1;

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    if(!nav2Processed){
      getListedRecipes();
      nav2Processed = true;
    }

    return Scaffold(
      appBar: const CommonAppBar(title: 'Xnd', showBackButton: true),
      backgroundColor: Colors.white,
      bottomNavigationBar: const MainBottomView(),
      body: Column(
        children: [
          // 검색 바
          Container(
            height: screenHeight * 0.06,
            margin: EdgeInsets.fromLTRB(20, screenHeight * 0.015, 20, screenHeight * 0.01),
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
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                hintText: '레시피 검색',
                hintStyle: TextStyle(
                  color: Colors.grey[700],
                  fontSize: screenHeight * 0.018,
                  fontWeight: FontWeight.bold,
                ),
                prefixIcon: IconButton(
                  icon: Icon(Icons.search, color: Colors.grey[700]),
                  onPressed: () async {
                    if (_searchController.text.trim().isNotEmpty) {
                      // 검색 기록 저장
                      await SearchHistoryService.saveSearch(_searchController.text);

                      // 레시피 검색
                      Recipes = await getRecipeQueryInfoFromServer(query: _searchController.text);
                      setState(() {
                        getListedRecipes();
                      });
                    }
                  },
                ),
                suffixIcon: (_searchController.text.isNotEmpty)
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.red, size: screenHeight * 0.025),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
              ),
              onChanged: (value) {
                setState(() {});
              },
              onSubmitted: (value) async {
                if (value.trim().isNotEmpty) {
                  // 검색 기록 저장
                  await SearchHistoryService.saveSearch(value);

                  // 레시피 검색
                  Recipes = await getRecipeQueryInfoFromServer(query: value);
                  setState(() {
                    getListedRecipes();
                  });
                }
              },
            ),
          ),
          // 레시피 리스트
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: recipeStorage?.recipes?.length ?? 0,
              itemBuilder: (context, index) {
                RecipeModel recipe = recipeStorage!.recipes![index];
                return _buildRecipeCard(recipe, screenWidth, screenHeight);
              },
            ),
          ),
        ],
      ),
    );
  }

  // 레시피 카드 위젯
  Widget _buildRecipeCard(RecipeModel recipe, double screenWidth, double screenHeight) {
    return GestureDetector(
      onTap: () async {
        int recipeIdx = await getIngredientInfoFromServer(recipe, false);
        recipe.getDetailRecipe(recipeIdx);
        // 새로운 상세 페이지로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailView(recipe: recipe),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 레시피 이미지
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                recipe.imgUrl ?? '',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
                  );
                },
              ),
            ),
            SizedBox(width: 12),
            // 레시피 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목과 즐겨찾기
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          recipe.recipeName ?? '레시피',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await createSavedRecipe(recipe: recipe);
                          setState(() {
                            updateRecipeSaved(recipe: recipe);
                            if (!recipe.isSaved!)
                              addSavedRecipe(recipeStorage!.recipes!.indexOf(recipe));
                            else
                              deleteSavedRecipe(savedrecipe: recipe);
                            getListedRecipes();
                          });
                        },
                        child: Icon(
                          recipe.isSaved! ? Icons.star : Icons.star_border,
                          color: recipe.isSaved! ? Colors.amber : Colors.grey,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  // 조리시간, 인분, 난이도
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        recipe.cookingTime ?? '50분',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        recipe.servingSize ?? '4인분',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      SizedBox(width: 12),
                      Text(
                        '난이도',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      SizedBox(width: 4),
                      Text(
                        recipe.cookingLevel ?? '쉬움',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  // 해시태그
                  Wrap(
                    spacing: 4,
                    children: [
                      if (recipe.category2 != null && recipe.category2!.isNotEmpty)
                        _buildHashtag(recipe.category2!),
                      if (recipe.category4 != null && recipe.category4!.isNotEmpty)
                        _buildHashtag(recipe.category4!),
                      if (recipe.category3 != null && recipe.category3!.isNotEmpty)
                        _buildHashtag(recipe.category3!),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 해시태그 위젯
  Widget _buildHashtag(String text) {
    return Text(
      '#$text',
      style: TextStyle(
        fontSize: 12,
        color: Colors.blue[700],
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
