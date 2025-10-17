import 'package:flutter/material.dart';
import 'package:Frontend/Abstracts/kakaoLogin.dart';
import 'package:Frontend/Models/LoginModel.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:Frontend/Widgets/CommonAppBar.dart';
import '../Models/IngredientModel.dart';
import '../Models/RecipeModel.dart';
import 'package:Frontend/MordalViews/RecipeMordal.dart';
import 'package:Frontend/Views/RecipeDetailView.dart';

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
  RecipesModel? filteredRecipeStorage;

  /// 레시피 끌어오기
  void getListedSavedRecipes(){
    List<RecipeModel> savedrecipes = [];
    // SavedRecipes가 null이거나 비어있는지 확인
    if (SavedRecipes != null && SavedRecipes!.isNotEmpty && SavedRecipes![0] != null) {
      for(int i = 0; i < SavedRecipes![0]!.length; i++)
        savedrecipes.add(RecipeModel().getSavedRecipe(i));
    }
    savedRecipeStorage = RecipesModel(savedrecipes);
    filteredRecipeStorage = savedRecipeStorage;
  }

  /// 레시피 필터링
  void filterRecipes(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredRecipeStorage = savedRecipeStorage;
      });
      return;
    }

    List<RecipeModel> filtered = [];
    if (savedRecipeStorage?.recipes != null) {
      for (var recipe in savedRecipeStorage!.recipes!) {
        if (recipe.recipeName != null &&
            recipe.recipeName!.toLowerCase().contains(query.toLowerCase())) {
          filtered.add(recipe);
        }
      }
    }
    setState(() {
      filteredRecipeStorage = RecipesModel(filtered);
    });
  }

  FavoritesPage(){
    super.initState();
    getListedSavedRecipes();
    _scrollController = ScrollController();

    // 검색어 변경 감지 - debounce 없이 즉시 필터링
    _searchController.addListener(() {
      filterRecipes(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    // 저장된 레시피 뷰 - 하단바 4번 활성화
    currentBottomNavIndex = 4;

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    if(!nav3Processed){
      getListedSavedRecipes();
      nav3Processed = true;
    }

    return Scaffold(
      appBar: const CommonAppBar(title: 'Xnd'),
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
                hintText: '저장된 레시피 검색',
                hintStyle: TextStyle(
                  color: Colors.grey[700],
                  fontSize: screenHeight * 0.018,
                  fontWeight: FontWeight.bold,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey[700]),
                suffixIcon: (_searchController.text.isNotEmpty)
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.red, size: screenHeight * 0.025),
                        onPressed: () {
                          _searchController.clear();
                          filterRecipes('');
                        },
                      )
                    : null,
                border: InputBorder.none,
              ),
            ),
          ),
          // 레시피 리스트
          Expanded(
            child: (filteredRecipeStorage?.recipes?.isEmpty ?? true)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchController.text.isEmpty ? Icons.star_border : Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? '저장된 레시피가 없습니다'
                              : '검색 결과가 없습니다',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _searchController.text.isEmpty
                              ? '마음에 드는 레시피를 별표로 저장해보세요!'
                              : '다른 검색어를 입력해보세요',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: filteredRecipeStorage?.recipes?.length ?? 0,
                    itemBuilder: (context, index) {
                      RecipeModel recipe = filteredRecipeStorage!.recipes![index];
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
        // 서버에서 레시피 상세 정보 가져오기
        int recipeIdx = await getIngredientInfoFromServer(recipe, true);

        if (recipeIdx >= 0) {
          // SavedRecipes에서 해당 레시피의 인덱스 찾기
          int savedRecipeIdx = -1;
          if (SavedRecipes != null && SavedRecipes![0] != null) {
            for (int i = 0; i < SavedRecipes![0]!.length; i++) {
              if (SavedRecipes![0]![i] == recipe.id) {
                savedRecipeIdx = i;
                break;
              }
            }
          }

          if (savedRecipeIdx >= 0) {
            recipe.getDetailSavedRecipe(savedRecipeIdx);
          }
        }

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
                            deleteSavedRecipe(savedrecipe: recipe);
                            for (int i = 0; i < Recipes![0]!.length; i++) {
                              if (Recipes![0]![i] == recipe.id) {
                                Recipes![3]![i] = false;
                                break;
                              }
                            }
                            getListedSavedRecipes();
                          });
                        },
                        child: Icon(
                          Icons.star,
                          color: Colors.amber,
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
