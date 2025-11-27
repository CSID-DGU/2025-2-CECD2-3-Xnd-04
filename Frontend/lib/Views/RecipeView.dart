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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // 전역 검색어를 검색창에 설정
    if (currentSearchQuery.isNotEmpty) {
      _searchController.text = currentSearchQuery;
    }
    // 초기 로드: 검색어가 없으면 추천 레시피 20개 로드
    _loadInitialRecipes();
  }

  // 초기 레시피 로드 함수
  Future<void> _loadInitialRecipes() async {
    if (currentSearchQuery.isEmpty) {
      // 검색어가 없으면 추천 레시피 가져오기
      Recipes = await getRecipeInfoFromServer();
    }
    getListedRecipes();
  }

  @override
  void dispose() {
    super.dispose();
    _searchController.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 검색 결과 뷰 - 하단바 1번 활성화
    currentBottomNavIndex = 1;

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    if(!nav2Processed){
      _loadInitialRecipes();
      nav2Processed = true;
    }

    return Scaffold(
      appBar: const CommonAppBar(title: 'Xnd', showBackButton: true),
      backgroundColor: Colors.white,
      bottomNavigationBar: const MainBottomView(),
      body: Column(
        children: [
          // 검색 바
          Padding(
            padding: EdgeInsets.fromLTRB(16, screenHeight * 0.015, 16, screenHeight * 0.01),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '키워드를 입력하세요',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade400),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
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

                    // 전역 변수에 검색어 저장
                    currentSearchQuery = value;

                    setState(() {
                      // 검색어를 유지 (clear 제거)
                      getListedRecipes();
                    });
                  }
                },
              ),
            ),
          ),
          // 필터 버튼 영역
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('추천순', false),
                SizedBox(width: 8),
                _buildFilterChip('정확도순', false),
                SizedBox(width: 8),
                _buildFilterChip('인기순', true),
                Spacer(),
                _buildFilterButton(),
              ],
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
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: Icon(Icons.restaurant, color: Colors.grey[600], size: 32),
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

  // 필터 칩 위젯 (기능 비활성화)
  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? Color(0xFF2196F3) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Color(0xFF2196F3) : Colors.grey[400]!,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // 필터 버튼 위젯 (기능 비활성화)
  Widget _buildFilterButton() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[400]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '필터',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 4),
          Icon(Icons.tune, size: 16, color: Colors.black),
        ],
      ),
    );
  }
}
