import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/db_helper.dart';
import 'adhkar_data.dart';

class AdhkarScreen extends StatefulWidget {
  const AdhkarScreen({super.key});

  @override
  State<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends State<AdhkarScreen> {
  String _selectedCategory = 'أذكار الصباح';
  List<String> _favTexts = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // حفظ حالة عدادات الجلسة الحالية لكل ذكر (حتى لا تعود للقيمة الأصلية إلا عند إعادة تعيينها)
  final Map<String, int> _counts = {};

  final List<String> _categories = [
    'أذكار الصباح',
    'أذكار المساء',
    'أذكار النوم والاستيقاظ',
    'أذكار بعد الصلاة',
    'أذكار السفر',
    'أذكار المسجد',
    'أذكار الطعام والشراب',
    'أذكار متنوعة',
    'المفضلة'
  ];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() async {
    final list = await DbHelper.getFavoriteAdhkar();
    if (mounted) {
      setState(() {
        _favTexts = list;
      });
    }
  }

  void _toggleFavorite(String text) async {
    await DbHelper.toggleFavoriteAdhkar(text);
    _loadFavorites();
  }

  int _getRemainingCount(ZekrModel item) {
    if (_counts.containsKey(item.text)) {
      return _counts[item.text]!;
    }
    return item.count;
  }

  void _decrementCount(ZekrModel item) {
    int current = _getRemainingCount(item);
    if (current > 0) {
      HapticFeedback.lightImpact(); // اهتزاز بسيط للتأكيد اللمسي
      setState(() {
        _counts[item.text] = current - 1;
      });
      
      // إذا اكتمل العداد، نسجل هذا التسبيح/الذكر في الإحصائيات
      if (current - 1 == 0) {
        DbHelper.addTasbihLog(item.category, item.count);
      }
    }
  }

  void _resetCounts() {
    setState(() {
      _counts.clear();
    });
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت إعادة تعيين جميع العدادات.')),
    );
  }

  List<ZekrModel> _getFilteredItems() {
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

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = appState.isDarkMode;
    final primaryColor = const Color(0xFF0F5A47);
    final accentColor = const Color(0xFFD4AF37);
    final filteredItems = _getFilteredItems();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : primaryColor,
        foregroundColor: Colors.white,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'ابحث عن ذكر معين...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              )
            : const Text(
                'الأذكار اليومية',
                style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
              ),
        centerTitle: true,
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetCounts,
            tooltip: 'إعادة تعيين العدادات',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : const Color(0xFFF6F8F6),
        ),
        child: Column(
          children: [
            // شريط اختيار التصنيفات أفقياً
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                reverse: true, // لتتناسب مع اللغة العربية RTL
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: ChoiceChip(
                      label: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: primaryColor,
                      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[200],
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedCategory = cat;
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            
            // قائمة عرض الأذكار المفلترة
            Expanded(
              child: filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_stories,
                            size: 64,
                            color: isDark ? Colors.grey[700] : Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedCategory == 'المفضلة'
                                ? 'لا توجد أذكار مضافة للمفضلة حالياً.'
                                : 'عذراً، لم يتم العثور على أذكار مطابقة.',
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final remaining = _getRemainingCount(item);
                        final isCompleted = remaining == 0;
                        final isFavorited = _favTexts.contains(item.text);

                        return Card(
                          elevation: 3,
                          shadowColor: Colors.black.withOpacity(0.05),
                          color: isDark 
                              ? (isCompleted ? const Color(0xFF1B2621) : const Color(0xFF1E1E1E))
                              : (isCompleted ? const Color(0xFFEDF5F1) : Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isCompleted
                                  ? Colors.teal.withOpacity(0.3)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          margin: const EdgeInsets.only(bottom: 16.0),
                          child: InkWell(
                            onTap: () => _decrementCount(item),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // أزرار التحكم بالبطاقة (مفضلة، نسخ، مشاركة)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              isFavorited ? Icons.favorite : Icons.favorite_border,
                                              color: isFavorited ? Colors.red : Colors.grey,
                                            ),
                                            iconSize: 20,
                                            onPressed: () => _toggleFavorite(item.text),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.copy, color: Colors.grey),
                                            iconSize: 20,
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(text: item.text));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('تم نسخ الذكر إلى الحافظة!')),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      // الورد اليومي المستهدف كشارة
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'المطلوب: ${item.count}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // نص الذكر الشريف
                                  Text(
                                    item.text,
                                    style: TextStyle(
                                      fontSize: 16.5,
                                      height: 1.6,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.grey[100] : Colors.black87,
                                    ),
                                    textAlign: TextAlign.justify,
                                    textDirection: TextDirection.rtl,
                                  ),
                                  const SizedBox(height: 12),

                                  // فضل الذكر
                                  if (item.fadl.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF182220) : const Color(0xFFF1F6F3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        item.fadl,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.teal[200] : primaryColor,
                                          height: 1.4,
                                        ),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // زر الضغط والعداد التفاعلي
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        isCompleted ? 'تم إنجازه بنجاح!' : 'انقر على البطاقة للتسبيح',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isCompleted ? Colors.teal : Colors.grey,
                                          fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                      // عداد دائري جميل
                                      Container(
                                        width: 52,
                                        height: 52,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isCompleted
                                              ? Colors.teal
                                              : (isDark ? const Color(0xFF2C2C2C) : Colors.grey[200]),
                                          border: Border.all(
                                            color: isCompleted ? Colors.teal : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                        child: Text(
                                          isCompleted ? '✓' : '$remaining',
                                          style: TextStyle(
                                            fontSize: isCompleted ? 20 : 18,
                                            fontWeight: FontWeight.bold,
                                            color: isCompleted
                                                ? Colors.white
                                                : (isDark ? Colors.white : Colors.black87),
                                            fontFamily: 'Outfit',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
