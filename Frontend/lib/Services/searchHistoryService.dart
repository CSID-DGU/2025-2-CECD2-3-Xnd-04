import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 10;

  // 최근 검색어 불러오기
  static Future<List<String>> loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentSearchesKey) ?? [];
  }

  // 검색어 저장
  static Future<void> saveSearch(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    List<String> searches = prefs.getStringList(_recentSearchesKey) ?? [];

    // 중복 제거
    searches.remove(query);
    // 최상단에 추가
    searches.insert(0, query);
    // 최대 개수 제한
    if (searches.length > _maxRecentSearches) {
      searches = searches.sublist(0, _maxRecentSearches);
    }

    await prefs.setStringList(_recentSearchesKey, searches);
  }

  // 검색어 삭제
  static Future<void> removeSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> searches = prefs.getStringList(_recentSearchesKey) ?? [];
    searches.remove(query);
    await prefs.setStringList(_recentSearchesKey, searches);
  }

  // 전체 검색 기록 삭제
  static Future<void> clearAllSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
  }
}
