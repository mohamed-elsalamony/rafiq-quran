import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_state.dart';
import 'adhkar_provider.dart';

class AdhkarScreen extends StatefulWidget {
  const AdhkarScreen({super.key});

  @override
  State<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends State<AdhkarScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animCtrl;

  static const _primary = Color(0xFF0F5A47);
  static const _accent = Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _resetCounts(AdhkarProvider provider) {
    provider.resetCounts();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تمت إعادة تعيين جميع العدادات.',
            textAlign: TextAlign.center),
        backgroundColor: _primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final adhkarProvider = Provider.of<AdhkarProvider>(context);
    final isDark = appState.isDarkMode;
    final filteredItems = adhkarProvider.getFilteredItems();
    final completedCount =
        filteredItems.where((i) => adhkarProvider.getRemainingCount(i) == 0).length;
    final totalCount = filteredItems.length;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0E1A17) : const Color(0xFFF2F5F3),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF0E1A17) : const Color(0xFF0F5A47),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: adhkarProvider.isSearching
            ? TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'ابحث عن ذكر...',
                  hintStyle: TextStyle(color: Colors.white60),
                  border: InputBorder.none,
                ),
                onChanged: adhkarProvider.setSearchQuery,
                autofocus: true,
              )
            : Text(
                'الأذكار اليومية',
                style: GoogleFonts.amiri(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
        centerTitle: false,
        actions: [
          if (!adhkarProvider.isSearching) ...[
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () => adhkarProvider.toggleSearching(true),
              tooltip: 'بحث',
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _resetCounts(adhkarProvider),
              tooltip: 'إعادة تعيين العدادات',
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                adhkarProvider.toggleSearching(false);
                _searchController.clear();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Progress header ──
          if (!adhkarProvider.isSearching)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: isDark ? const Color(0xFF0F1F1A) : const Color(0xFF0F5A47),
              child: Row(
                children: [
                  // category label
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adhkarProvider.selectedCategory,
                          style: GoogleFonts.amiri(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$completedCount من $totalCount مكتمل',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  // circular progress
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: totalCount > 0 ? completedCount / totalCount : 0,
                          strokeWidth: 5,
                          backgroundColor: Colors.white.withOpacity(0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFD4AF37)),
                        ),
                        Text(
                          totalCount > 0
                              ? '${(completedCount / totalCount * 100).toInt()}%'
                              : '0%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ── Category chips ──
          Container(
            height: 52,
            color: isDark ? const Color(0xFF131F1B) : Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: adhkarProvider.categories.length,
              itemBuilder: (context, index) {
                final cat = adhkarProvider.categories[index];
                final isSelected = adhkarProvider.selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: () => adhkarProvider.setCategory(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _primary
                            : (isDark
                                ? const Color(0xFF1E2D28)
                                : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? _primary
                              : (isDark
                                  ? Colors.white12
                                  : Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontFamily: 'Amiri',
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 1),

          // ── Adhkar list ──
          Expanded(
            child: filteredItems.isEmpty
                ? _buildEmptyState(isDark, adhkarProvider)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final remaining =
                          adhkarProvider.getRemainingCount(item);
                      final isCompleted = remaining == 0;
                      final isFavorited =
                          adhkarProvider.favTexts.contains(item.text);

                      return TweenAnimationBuilder<double>(
                        key: ValueKey(
                            item.text + adhkarProvider.selectedCategory),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(
                            milliseconds:
                                250 + (index * 40).clamp(0, 400)),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, (1.0 - value) * 20),
                              child: child,
                            ),
                          );
                        },
                        child: _AdhkarCard(
                          item: item,
                          remaining: remaining,
                          isCompleted: isCompleted,
                          isFavorited: isFavorited,
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            adhkarProvider.decrementCount(item);
                          },
                          onFavorite: () =>
                              adhkarProvider.toggleFavorite(item.text),
                          onCopy: () {
                            Clipboard.setData(
                                ClipboardData(text: item.text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'تم نسخ الذكر إلى الحافظة!',
                                    textAlign: TextAlign.center),
                                backgroundColor: _primary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, AdhkarProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            provider.selectedCategory == 'المفضلة'
                ? Icons.favorite_border_rounded
                : Icons.search_off_rounded,
            size: 72,
            color: isDark ? Colors.white12 : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            provider.selectedCategory == 'المفضلة'
                ? 'لا توجد أذكار في المفضلة'
                : 'لا توجد أذكار مطابقة',
            style: GoogleFonts.amiri(
              fontSize: 16,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          if (provider.selectedCategory == 'المفضلة')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'أضف أذكاراً للمفضلة بالضغط على أيقونة القلب',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Adhkar Card Widget
// ══════════════════════════════════════════════════════════════
class _AdhkarCard extends StatefulWidget {
  final dynamic item;
  final int remaining;
  final bool isCompleted;
  final bool isFavorited;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onCopy;

  const _AdhkarCard({
    required this.item,
    required this.remaining,
    required this.isCompleted,
    required this.isFavorited,
    required this.isDark,
    required this.onTap,
    required this.onFavorite,
    required this.onCopy,
  });

  @override
  State<_AdhkarCard> createState() => _AdhkarCardState();
}

class _AdhkarCardState extends State<_AdhkarCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _scale;

  static const _primary = Color(0xFF0F5A47);
  static const _accent = Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _handleTap() async {
    await _pulseCtrl.forward();
    await _pulseCtrl.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.item.count > 0
        ? (widget.item.count - widget.remaining) / widget.item.count
        : 1.0;

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: widget.isDark
                ? (widget.isCompleted
                    ? const Color(0xFF0F2A20)
                    : const Color(0xFF182420))
                : (widget.isCompleted
                    ? const Color(0xFFEDF6F1)
                    : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isCompleted
                  ? _primary.withOpacity(0.3)
                  : (widget.isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.shade200),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(widget.isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Top row ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Count badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'المطلوب: ${widget.item.count}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: _accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Action buttons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: widget.onCopy,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: widget.isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.grey.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.copy_rounded,
                                  size: 16,
                                  color: widget.isDark
                                      ? Colors.white38
                                      : Colors.grey[500],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: widget.onFavorite,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: widget.isFavorited
                                      ? Colors.red.withOpacity(0.1)
                                      : (widget.isDark
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.grey.withOpacity(0.08)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  widget.isFavorited
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 16,
                                  color: widget.isFavorited
                                      ? Colors.red
                                      : (widget.isDark
                                          ? Colors.white38
                                          : Colors.grey[500]),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Dhikr text ──
                    Text(
                      widget.item.text,
                      style: GoogleFonts.amiri(
                        fontSize: 18,
                        height: 1.75,
                        fontWeight: FontWeight.w500,
                        color: widget.isDark
                            ? const Color(0xFFD4E8DA)
                            : const Color(0xFF0D3D2E),
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 10),

                    // ── Fadl ──
                    if (widget.item.fadl.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: widget.isDark
                              ? const Color(0xFF0A2018)
                              : const Color(0xFFF0F7F3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _primary.withOpacity(
                                widget.isDark ? 0.15 : 0.1),
                          ),
                        ),
                        child: Text(
                          widget.item.fadl,
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isDark
                                ? const Color(0xFF7ABFA0)
                                : _primary,
                            height: 1.4,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // ── Bottom row: status + counter circle ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Status text
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.isCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.touch_app_rounded,
                              size: 14,
                              color: widget.isCompleted
                                  ? Colors.green[400]
                                  : (widget.isDark
                                      ? Colors.white30
                                      : Colors.grey[400]),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              widget.isCompleted
                                  ? 'تم إنجازه بنجاح!'
                                  : 'انقر للتسبيح',
                              style: TextStyle(
                                fontSize: 11,
                                color: widget.isCompleted
                                    ? Colors.green[400]
                                    : (widget.isDark
                                        ? Colors.white30
                                        : Colors.grey[400]),
                                fontWeight: widget.isCompleted
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        // Counter circle
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                strokeWidth: 4,
                                backgroundColor: widget.isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  widget.isCompleted
                                      ? Colors.green.shade400
                                      : _primary,
                                ),
                              ),
                              AnimatedSwitcher(
                                duration:
                                    const Duration(milliseconds: 200),
                                child: Text(
                                  widget.isCompleted
                                      ? '✓'
                                      : '${widget.remaining}',
                                  key: ValueKey(widget.remaining),
                                  style: TextStyle(
                                    fontSize:
                                        widget.isCompleted ? 18 : 15,
                                    fontWeight: FontWeight.bold,
                                    color: widget.isCompleted
                                        ? Colors.green[400]
                                        : (widget.isDark
                                            ? Colors.white
                                            : Colors.black87),
                                    fontFamily: 'Outfit',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
              // ── Progress bar at bottom ──
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: progress.clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  builder: (_, v, __) => LinearProgressIndicator(
                    value: v,
                    minHeight: 4,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.isCompleted
                          ? Colors.green.shade400
                          : _primary.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
