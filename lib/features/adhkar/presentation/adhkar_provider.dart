import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/db_helper.dart';
import 'adhkar_data.dart';

class AdhkarProvider extends ChangeNotifier {
  String _selectedCategory = 'أذكار الصباح';
  List<String> _favTexts = [];
  bool _isSearching = false;
  String _searchQuery = '';

  // Keep counts in session
  final Map<String, int> _counts = {};

  final List<String> categories = [
    'أذكار الصباح',
    'أذكار المساء',
    'أذكار النوم والاستيقاظ',
    'أذكار بعد الصلاة',
    'أذكار السفر',
    'أذكار المسجد',
    'أذكار الطعام والشراب',
    'أذكار دخول وخروج المنزل',
    'أذكار الوضوء',
    'الرقية الشرعية',
    'سورة الملك',
    'أذكار متنوعة',
    'المفضلة'
  ];

  // Getters
  String get selectedCategory => _selectedCategory;
  List<String> get favTexts => _favTexts;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;

  AdhkarProvider() {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    try {
      _favTexts = await DbHelper.getFavoriteAdhkar();
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading favorite adhkar: $e");
    }
  }

  Future<void> toggleFavorite(String text) async {
    try {
      await DbHelper.toggleFavoriteAdhkar(text);
      await loadFavorites();
    } catch (e) {
      debugPrint("Error toggling favorite zekr: $e");
    }
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void toggleSearching(bool search) {
    _isSearching = search;
    if (!search) {
      _searchQuery = '';
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  int getRemainingCount(ZekrModel item) {
    if (_counts.containsKey(item.text)) {
      return _counts[item.text]!;
    }
    return item.count;
  }

  void decrementCount(ZekrModel item) {
    int current = getRemainingCount(item);
    if (current > 0) {
      HapticFeedback.lightImpact();
      _counts[item.text] = current - 1;
      notifyListeners();

      // If target reached, save to tasbih logs
      if (current - 1 == 0) {
        DbHelper.addTasbihLog(item.category, item.count);
      }
    }
  }

  void resetCounts() {
    _counts.clear();
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  List<ZekrModel> getFilteredItems() {
    List<ZekrModel> currentList = [];
    if (_selectedCategory == 'المفضلة') {
      currentList = AdhkarData.items
          .where((item) => _favTexts.contains(item.text))
          .toList();
    } else {
      currentList = AdhkarData.items
          .where((item) => item.category == _selectedCategory)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      currentList = currentList
          .where((item) =>
              item.text.contains(_searchQuery) ||
              item.fadl.contains(_searchQuery))
          .toList();
    }

    return currentList;
  }
}
