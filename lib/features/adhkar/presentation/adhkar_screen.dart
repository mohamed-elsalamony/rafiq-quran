import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_state.dart';
import 'adhkar_provider.dart';

class AdhkarScreen extends StatefulWidget {
  const AdhkarScreen({super.key});

  @override
  State<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends State<AdhkarScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetCounts(AdhkarProvider provider) {
    provider.resetCounts();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت إعادة تعيين جميع العدادات.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final adhkarProvider = Provider.of<AdhkarProvider>(context);
    final isDark = appState.isDarkMode;
    const primaryColor = Color(0xFF0F5A47);
    final filteredItems = adhkarProvider.getFilteredItems();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : primaryColor,
        foregroundColor: Colors.white,
        title: adhkarProvider.isSearching
            ? TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'ابحث عن ذكر معين...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: adhkarProvider.setSearchQuery,
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: const Text(
                  'الأذكار اليومية',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                    fontSize: 16,
                  ),
                ),
              ),
        centerTitle: true,
        actions: [
          if (!adhkarProvider.isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => adhkarProvider.toggleSearching(true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                adhkarProvider.toggleSearching(false);
                _searchController.clear();
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _resetCounts(adhkarProvider),
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
            // Category selector bar
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                reverse: false, // RTL fit
                itemCount: adhkarProvider.categories.length,
                itemBuilder: (context, index) {
                  final cat = adhkarProvider.categories[index];
                  final isSelected = adhkarProvider.selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: ChoiceChip(
                      label: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.grey[300] : Colors.black87),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: primaryColor,
                      backgroundColor:
                          isDark ? const Color(0xFF2C2C2C) : Colors.grey[200],
                      onSelected: (val) {
                        if (val) {
                          adhkarProvider.setCategory(cat);
                        }
                      },
                    ),
                  );
                },
              ),
            ),

            // Adhkar cards list
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
                            adhkarProvider.selectedCategory == 'المفضلة'
                                ? 'لا توجد أذكار مضافة للمفضلة حالياً.'
                                : 'عذراً، لم يتم العثور على أذكار مطابقة.',
                            style: TextStyle(
                              fontSize: 15,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                          left: 16.0, right: 16.0, top: 16.0, bottom: 100.0),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final remaining =
                            adhkarProvider.getRemainingCount(item);
                        final isCompleted = remaining == 0;
                        final isFavorited =
                            adhkarProvider.favTexts.contains(item.text);

                        return TweenAnimationBuilder<double>(
                          key: ValueKey(item.text + adhkarProvider.selectedCategory),
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 300 + (index * 40).clamp(0, 300)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, (1.0 - value) * 16),
                              child: Opacity(
                                opacity: value,
                                child: child,
                              ),
                            );
                          },
                          child: Card(
                            elevation: 3,
                            shadowColor: Colors.black.withOpacity(0.05),
                            color: isDark
                                ? (isCompleted
                                    ? const Color(0xFF1B2621)
                                    : const Color(0xFF1E1E1E))
                                : (isCompleted
                                    ? const Color(0xFFEDF5F1)
                                    : Colors.white),
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
                              onTap: () => adhkarProvider.decrementCount(item),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                isFavorited
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: isFavorited
                                                    ? Colors.red
                                                    : Colors.grey,
                                              ),
                                              iconSize: 20,
                                              onPressed: () => adhkarProvider
                                                  .toggleFavorite(item.text),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.copy,
                                                  color: Colors.grey),
                                              iconSize: 20,
                                              onPressed: () {
                                                Clipboard.setData(ClipboardData(
                                                    text: item.text));
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'تم نسخ الذكر إلى الحافظة!')),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF2C2C2C)
                                                : Colors.grey[100],
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'المطلوب: ${item.count}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Text of Dhikr
                                    Text(
                                      item.text,
                                      style: TextStyle(
                                        fontSize: 16.5,
                                        height: 1.6,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? Colors.grey[100]
                                            : Colors.black87,
                                      ),
                                      textAlign: TextAlign.justify,
                                      textDirection: TextDirection.rtl,
                                    ),
                                    const SizedBox(height: 12),

                                    // Fadl text if exists
                                    if (item.fadl.isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF182220)
                                              : const Color(0xFFF1F6F3),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          item.fadl,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? Colors.teal[200]
                                                : primaryColor,
                                            height: 1.4,
                                          ),
                                          textDirection: TextDirection.rtl,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],

                                    // Count decrements indicators
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          isCompleted
                                              ? 'تم إنجازه بنجاح!'
                                              : 'انقر على البطاقة للتسبيح',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isCompleted
                                                ? Colors.teal
                                                : Colors.grey,
                                            fontWeight: isCompleted
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        Container(
                                          width: 52,
                                          height: 52,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isCompleted
                                                ? Colors.teal
                                                : (isDark
                                                    ? const Color(0xFF2C2C2C)
                                                    : Colors.grey[200]),
                                            border: Border.all(
                                              color: isCompleted
                                                  ? Colors.teal
                                                  : Colors.transparent,
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
                                                  : (isDark
                                                      ? Colors.white
                                                      : Colors.black87),
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
