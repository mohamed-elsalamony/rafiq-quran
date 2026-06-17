import 'package:flutter/material.dart';

/// ثوابت ألوان تطبيق رفيق القرآن المركزية
/// يجب استخدام هذه الثوابت في كل أنحاء التطبيق بدلاً من تكرار قيم اللون
class AppColors {
  AppColors._(); // Prevent instantiation

  // ─── الألوان الرئيسية ───
  static const Color primary = Color(0xFF0F5A47); // أخضر إسلامي داكن
  static const Color primaryDark = Color(0xFF073A2F); // أخضر إسلامي أغمق
  static const Color primaryLight = Color(0xFF127F65); // أخضر إسلامي فاتح
  static const Color accent = Color(0xFFD4AF37); // ذهبي

  // ─── ألوان الخلفيات ───
  static const Color backgroundLight = Color(0xFFF4F7F5); // خلفية فاتحة
  static const Color backgroundDark = Color(0xFF121212); // خلفية داكنة
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceDark2 = Color(0xFF252525);

  // ─── ألوان قارئ القرآن ───
  static const Color quranBgLight = Color(0xFFFDFBF7);
  static const Color quranBgSepia = Color(0xFFF4ECD8);
  static const Color quranBgDark = Color(0xFF1E1E1E);
  static const Color quranAppBarSepia = Color(0xFFE8DECA);
  static const Color quranTextSepia = Color(0xFF5B4636);

  // ─── ألوان الحالة ───
  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color warning = Color(0xFFF5A623);

  // ─── ثوابت الشكل ───
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusCircular = 24.0;
}
