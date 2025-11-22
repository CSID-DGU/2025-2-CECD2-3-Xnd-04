import 'package:flutter/material.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:Frontend/Widgets/CommonAppBar.dart';
import 'package:Frontend/Services/loadRecipeQueryService.dart';
import 'package:Frontend/Services/loadRecipeService.dart';
import 'package:Frontend/Models/RecipeModel.dart';
import 'package:Frontend/Services/searchHistoryService.dart';
import 'package:Frontend/Views/RecipeDetailView.dart';
import 'package:Frontend/Services/loadIngredientService.dart';
import 'package:Frontend/Services/createSavedRecipeService.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();

  // 최근 검색어 리스트
  List<String> recentSearches = [];

  // 추천 레시피 리스트
  List<RecipeModel> recommendedRecipes = [];
  bool isLoadingRecommendations = true;
  int displayedRecipeCount = 10; // 현재 표시할 레시피 개수
  int totalRecipeCount = 0; // 서버에서 받은 전체 레시피 개수

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadRecommendedRecipes();
  }

  // 최근 검색어 불러오기
  Future<void> _loadRecentSearches() async {
    final searches = await SearchHistoryService.loadRecentSearches();
    setState(() {
      recentSearches = searches;
    });
  }

  // 추천 레시피 불러오기
  Future<void> _loadRecommendedRecipes() async {
    setState(() {
      isLoadingRecommendations = true;
    });

    try {
      // 서버에서 추천 레시피 가져오기
      List<List<dynamic>?>? recipesData = await getRecipeInfoFromServer();

      if (recipesData != null && recipesData[0] != null) {
        // 전역 Recipes 변수에 저장
        Recipes = recipesData;

        // 전체 레시피 개수 저장
        totalRecipeCount = recipesData[0]!.length;

        List<RecipeModel> recipes = [];
        int count = recipesData[0]!.length < displayedRecipeCount
            ? recipesData[0]!.length
            : displayedRecipeCount;

        for (int i = 0; i < count; i++) {
          // RecipeModel의 getRecipe 메서드를 사용하여 전체 정보 가져오기
          RecipeModel recipe = RecipeModel().getRecipe(i);
          recipes.add(recipe);
        }

        setState(() {
          recommendedRecipes = recipes;
          isLoadingRecommendations = false;
        });
      }
    } catch (e) {
      print('추천 레시피 로드 실패: $e');
      setState(() {
        isLoadingRecommendations = false;
      });
    }
  }

  // 더 많은 레시피 로드
  void _loadMoreRecipes() {
    if (Recipes == null || Recipes![0] == null) {
      print('레시피 데이터가 없습니다');
      return;
    }

    setState(() {
      int previousCount = displayedRecipeCount;
      int newCount = displayedRecipeCount + 10;

      // totalRecipeCount를 초과하지 않도록 제한
      if (newCount > totalRecipeCount) {
        newCount = totalRecipeCount;
      }

      print('이전 개수: $previousCount, 새 개수: $newCount, 전체: $totalRecipeCount');

      // 추가 레시피 로드
      List<RecipeModel> newRecipes = [];
      for (int i = previousCount; i < newCount; i++) {
        RecipeModel recipe = RecipeModel().getRecipe(i);
        newRecipes.add(recipe);
      }

      recommendedRecipes.addAll(newRecipes);
      displayedRecipeCount = newCount;

      print('현재 표시 중인 레시피 개수: ${recommendedRecipes.length}');
    });
  }

  // 검색 실행 함수
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    // 검색어 저장
    await SearchHistoryService.saveSearch(query);

    // 검색어 목록 새로고침
    await _loadRecentSearches();

    // 레시피 검색
    Recipes = await getRecipeQueryInfoFromServer(query: query);

    // 전역 변수에 검색어 저장
    currentSearchQuery = query;

    // RecipeView로 이동
    if (mounted) {
      Navigator.of(context).pushNamed('/RecipeView');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 검색 뷰 - 하단바 1번 활성화
    currentBottomNavIndex = 1;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 검색창
                    Container(
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
                        onSubmitted: (value) {
                          // 검색 실행
                          _performSearch(value);
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 최근 검색어 섹션
                    const Text(
                      '최근 검색어',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    recentSearches.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              '최근 검색어가 없습니다',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          )
                        : SizedBox(
                            height: 40,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: recentSearches.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _buildKeywordChip(recentSearches[index], isRecent: true),
                                );
                              },
                            ),
                          ),
                    const SizedBox(height: 32),

                    // 추천 레시피 섹션
                    const Text(
                      '추천 레시피',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    isLoadingRecommendations
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : recommendedRecipes.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: Text(
                                    '추천 레시피를 불러올 수 없습니다',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  ...recommendedRecipes.map((recipe) {
                                    return _buildRecipeCard(recipe);
                                  }),
                                  // "10개 더 보기" 버튼
                                  if (displayedRecipeCount < totalRecipeCount)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      child: ElevatedButton(
                                        onPressed: _loadMoreRecipes,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF87CEEB),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 32,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: const Text(
                                          '10개 더 보기',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                    const SizedBox(height: 100), // 하단 여백
                  ],
                ),
              ),
            ),
          ),
          // 챗봇 아이콘 영역 (하단바 바로 위)
          Container(
            height: 70,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16),
            child: GestureDetector(
              onTap: () {
                // TODO: 챗봇 기능 구현
                debugPrint('챗봇 열기');
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const MainBottomView(),
    );
  }

  // 키워드 칩 위젯
  Widget _buildKeywordChip(String keyword, {bool isRecent = false}) {
    return InkWell(
      onTap: () {
        // 해당 키워드로 검색
        _performSearch(keyword);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF87CEEB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              keyword,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700, // 더 굵은 폰트
              ),
            ),
            if (isRecent) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  // 최근 검색어 삭제 (검색 실행 방지)
                  await SearchHistoryService.removeSearch(keyword);
                  // 검색어 목록 새로고침
                  await _loadRecentSearches();
                },
                child: Icon(
                  Icons.close,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 레시피 카드 위젯
  Widget _buildRecipeCard(RecipeModel recipe) {
    return GestureDetector(
      onTap: () async {
        // 레시피 상세 정보 로드
        int recipeIdx = await getIngredientInfoFromServer(recipe, false);

        if (recipeIdx >= 0) {
          recipe.getDetailRecipe(recipeIdx);

          // 레시피 상세 페이지로 이동
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailView(recipe: recipe),
            ),
          );
        } else {
          // 에러 처리
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('레시피 정보를 불러올 수 없습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
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
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
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
                    child: Icon(
                      Icons.restaurant,
                      color: Colors.grey[600],
                      size: 32,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
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
                          style: const TextStyle(
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
                            // 전역 Recipes 변수에서 isSaved 업데이트
                            if (Recipes != null && Recipes![0] != null && Recipes![3] != null) {
                              for (int i = 0; i < Recipes![0]!.length; i++) {
                                if (recipe.id == Recipes![0]![i]) {
                                  Recipes![3]![i] = !Recipes![3]![i];

                                  // savedRecipes 전역 변수 업데이트
                                  if (!Recipes![3]![i]) {
                                    deleteSavedRecipe(savedrecipe: recipe);
                                  } else {
                                    addSavedRecipe(i);
                                  }

                                  // 로컬 레시피 리스트도 업데이트
                                  recommendedRecipes[recommendedRecipes.indexOf(recipe)] =
                                      RecipeModel().getRecipe(i);

                                  break;
                                }
                              }
                            }
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
                  const SizedBox(height: 8),
                  // 조리시간, 인분, 난이도
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        recipe.cookingTime ?? '50분',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        recipe.servingSize ?? '4인분',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '난이도',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        recipe.cookingLevel ?? '쉬움',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
