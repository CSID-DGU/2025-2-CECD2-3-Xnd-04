import 'package:flutter/material.dart';
import 'package:Frontend/Views/MainFrameView.dart';
import 'package:Frontend/Widgets/CommonAppBar.dart';
import 'package:Frontend/Services/loadRecipeQueryService.dart';
import 'package:Frontend/Models/RecipeModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();

  // 최근 검색어 리스트
  List<String> recentSearches = [];

  // SharedPreferences 키
  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 10; // 최대 10개

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  // SharedPreferences에서 최근 검색어 불러오기
  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList(_recentSearchesKey) ?? [];
    setState(() {
      recentSearches = searches;
    });
  }

  // SharedPreferences에 최근 검색어 저장
  Future<void> _saveRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, recentSearches);
  }

  // 검색 실행 함수
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    // 검색어를 최근 검색어에 추가 (중복 제거, 최대 10개)
    setState(() {
      recentSearches.remove(query);
      recentSearches.insert(0, query);
      if (recentSearches.length > _maxRecentSearches) {
        recentSearches = recentSearches.sublist(0, _maxRecentSearches);
      }
    });

    // SharedPreferences에 저장
    await _saveRecentSearches();

    // 레시피 검색
    Recipes = await getRecipeQueryInfoFromServer(query: query);

    // RecipeView로 이동
    if (mounted) {
      Navigator.of(context).pushNamed('/RecipeView');
    }
  }

  // 최신 트렌드 (하드코딩 - 6개)
  final List<String> trendingKeywords = [
    '크리스마스 요리',
    '다이어트 식단',
    '간단한 야식',
    '건강 샐러드',
    '겨울 보양식',
    '에어프라이어 요리',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    SizedBox(
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

                    // 최신 트렌드 섹션
                    const Text(
                      '최신 트렌드',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: trendingKeywords.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildKeywordChip(trendingKeywords[index]),
                          );
                        },
                      ),
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
                  setState(() {
                    recentSearches.remove(keyword);
                  });
                  // SharedPreferences에 저장
                  await _saveRecentSearches();
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
}
