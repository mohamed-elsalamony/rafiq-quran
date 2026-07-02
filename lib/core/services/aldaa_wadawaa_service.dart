import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AldaaWadawaaChapter {
  final int id;
  final String title;
  final String content;
  final int page;

  AldaaWadawaaChapter({
    required this.id,
    required this.title,
    required this.content,
    required this.page,
  });

  factory AldaaWadawaaChapter.fromJson(Map<String, dynamic> json) {
    return AldaaWadawaaChapter(
      id: json['id'] as int,
      title: _cleanText(json['title'] as String),
      content: _cleanContent(json['content'] as String),
      page: json['page'] as int,
    );
  }

  // ================================================================
  // دوال تنظيف النص من الرموز الغريبة وهوامش التحقيق
  // ================================================================

  /// تنظيف العنوان من الرموز الغريبة
  static String _cleanText(String text) {
    // إزالة رموز التحكم في الاتجاه (Unicode invisible chars)
    text = text.replaceAll(
      RegExp(r'[\u200B-\u200F\u202A-\u202E\u2060-\u206F\uFEFF\u00AD]'),
      '',
    );
    // إزالة الحروف اللاتينية الغريبة المعزولة
    text = text.replaceAll(RegExp(r'(?<!\p{L})[A-Za-z]{1,4}(?!\p{L})'), '');
    // تنظيف المسافات
    text = text.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    return text;
  }

  /// تنظيف شامل لمحتوى الفصل
  static String _cleanContent(String text) {
    // 1: إزالة رموز التحكم في الاتجاه
    text = text.replaceAll(
      RegExp(r'[\u200B-\u200F\u202A-\u202E\u2060-\u206F\uFEFF\u00AD]'),
      '',
    );

    // 2: معالجة سطر بسطر - حذف هوامش التحقيق
    final lines = text.split('\n');
    final keepLines = <String>[];

    for (final line in lines) {
      final t = line.trim();
      if (t.isEmpty) {
        keepLines.add('');
        continue;
      }

      // هامش رقمي في بداية السطر: (۱) أو [2] أو )٣(
      if (RegExp(r'^\s*[\(\[]\s*[\d\u06F0-\u06F9\u0660-\u0669]{1,3}\s*[\)\]]')
          .hasMatch(t)) continue;

      // اختصار نسخة محقق: حرف واحد + نقطتان في بداية السطر (ف: س: ز: ل: خ:)
      if (RegExp(r'^[\u0641\u0633\u0632\u0644\u062E\u0637\u062D\u0628\u0623\u0643\u0646\u064A\u0648]\s*:')
              .hasMatch(t) &&
          t.length < 150) continue;

      // سطر رقم مجرد أو حرف + رقم فقط
      if (RegExp(r'^[\d\u06F0-\u06F9\u0660-\u0669\s،.]{1,8}$').hasMatch(t)) {
        continue;
      }

      // سطر يبدأ بـ "وانظر" أو "أخرجه" أو "راجع" مع رقم - هوامش توثيق
      if (RegExp(r'^(وانظر|أخرجه|راجع|انظر)\s.{0,20}[\(（\[].{0,8}[\)）\]]')
          .hasMatch(t)) continue;

      keepLines.add(line);
    }
    text = keepLines.join('\n');

    // 3: إزالة إشارات الهوامش المدمجة في وسط النص: (۱) أو [2]
    text = text.replaceAll(
        RegExp(r'\s*\(\s*[\d\u06F0-\u06F9\u0660-\u0669]{1,3}\s*\)\s*'), ' ');
    text = text.replaceAll(
        RegExp(r'\s*\[\s*[\d\u06F0-\u06F9\u0660-\u0669]{1,3}\s*\]\s*'), ' ');

    // 4: إزالة الحروف اللاتينية الغريبة المعزولة (1-4 أحرف بين مسافات)
    // حرف/حرفان/3 أحرف لاتينية بين مسافات عربية أو في بداية/نهاية السطر
    text = text.replaceAllMapped(
      RegExp(r'(?<![A-Za-z])[A-Za-z]{1,5}(?![A-Za-z])'),
      (m) => ' ',
    );

    // 5: إزالة مسلسلات لاتينية متعددة (3+ كلمات لاتينية متتالية)
    text = text.replaceAll(RegExp(r'([A-Za-z]{1,8}\s+){3,}'), ' ');

    // 6: تنظيف رمز › المكسور
    text = text.replaceAll('\u203A', '\u060C');
    text = text.replaceAll('\u2039', '\u060C');

    // 7: تنظيف علامات اقتباس مضاعفة
    text = text.replaceAll(RegExp(r'"{2,}'), '"');
    text = text.replaceAll(RegExp(r"'{2,}"), "'");

    // 8: تنظيف الأسطر الفارغة الزائدة
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // 9: تنظيف المسافات الزائدة
    text = text.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
    text = text.replaceAll(RegExp(r'^[ \t]+$', multiLine: true), '');

    return text.trim();
  }
}

class AldaaWadawaaService {
  static final AldaaWadawaaService _instance = AldaaWadawaaService._internal();
  factory AldaaWadawaaService() => _instance;
  AldaaWadawaaService._internal();

  List<AldaaWadawaaChapter> _chapters = [];
  bool _isLoaded = false;

  Future<void> loadChapters() async {
    if (_isLoaded) return;
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/aldaa_wadawaa.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _chapters = jsonList
          .map((j) => AldaaWadawaaChapter.fromJson(j as Map<String, dynamic>))
          .toList();
      _isLoaded = true;
    } catch (e) {
      debugPrint('Error loading Aldaa Wadawaa: $e');
      _chapters = [];
      _isLoaded = true;
    }
  }

  /// إعادة تحميل قسري (لمسح الكاش)
  Future<void> reload() async {
    _isLoaded = false;
    _chapters = [];
    await loadChapters();
  }

  List<AldaaWadawaaChapter> getAllChapters() => _chapters;

  int get totalChapters => _chapters.length;

  AldaaWadawaaChapter? getChapterById(int id) {
    try {
      return _chapters.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// جلب الفصل بالرقم التسلسلي (index) لا بالـ id
  AldaaWadawaaChapter? getChapterByIndex(int index) {
    if (index < 0 || index >= _chapters.length) return null;
    return _chapters[index];
  }

  /// جلب index الفصل الحالي
  int getChapterIndex(int chapterId) {
    return _chapters.indexWhere((c) => c.id == chapterId);
  }

  String _normalizeArabic(String text) {
    return text
        .replaceAll(RegExp(r'[َُِّْٰ]'), '') // remove diacritics
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');
  }

  List<AldaaWadawaaChapter> searchChapters(String query) {
    if (query.isEmpty) return _chapters;
    final normalizedQuery = _normalizeArabic(query.trim().toLowerCase());
    return _chapters
        .where((c) =>
            _normalizeArabic(c.title.toLowerCase()).contains(normalizedQuery) ||
            _normalizeArabic(c.content.toLowerCase())
                .contains(normalizedQuery) ||
            c.page.toString().contains(normalizedQuery))
        .toList();
  }

  // --- Favorite Chapters Persistence ---
  Future<List<int>> getFavoriteChapterIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list =
          prefs.getStringList('favorite_aldaa_chapters') ?? [];
      return list
          .map((idStr) => int.tryParse(idStr) ?? 0)
          .where((id) => id > 0)
          .toList();
    } catch (e) {
      debugPrint('Error fetching favorite chapters: $e');
      return [];
    }
  }

  Future<bool> isFavorite(int chapterId) async {
    final favorites = await getFavoriteChapterIds();
    return favorites.contains(chapterId);
  }

  Future<void> toggleFavorite(int chapterId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list =
          prefs.getStringList('favorite_aldaa_chapters') ?? [];
      final String idStr = chapterId.toString();

      if (list.contains(idStr)) {
        list.remove(idStr);
      } else {
        list.add(idStr);
      }

      await prefs.setStringList('favorite_aldaa_chapters', list);
    } catch (e) {
      debugPrint('Error toggling favorite chapter: $e');
    }
  }

  Future<List<AldaaWadawaaChapter>> getFavoriteChapters() async {
    await loadChapters();
    final favIds = await getFavoriteChapterIds();
    return _chapters.where((c) => favIds.contains(c.id)).toList();
  }
}
