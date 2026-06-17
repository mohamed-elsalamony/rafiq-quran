import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showResetConfirmation(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تحذير هام',
            textAlign: TextAlign.right,
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text(
          'هل أنت متأكد تماماً من رغبتك في حذف جميع البيانات المحلية؟ سيؤدي ذلك إلى تصفير المسبحة، وحذف جميع خطط الحفظ والختمة والعلامات المرجعية والعودة للوضع الافتراضي.',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _showDoubleResetConfirmation(context, appState);
            },
            child:
                const Text('نعم، استمر', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDoubleResetConfirmation(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد أخير',
            textAlign: TextAlign.right,
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text(
          'هذه الخطوة لا يمكن التراجع عنها! هل تؤكد حذف كل التقدم المحرز في الحفظ والورد اليومي بشكل نهائي؟',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء وتراجع'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
            onPressed: () async {
              Navigator.pop(context);
              await appState.clearAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'تم تهيئة التطبيق بنجاح وحذف جميع البيانات المحلية!',
                        textAlign: TextAlign.right),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('حذف نهائي للملفات',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatTimeOfDay(int hour, int minute) {
    final period = hour >= 12 ? 'م' : 'ص';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  Future<void> _selectTime(BuildContext context, int currentHour,
      int currentMinute, Function(int, int) onTimeSelected) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F5A47), // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0F5A47), // Button text color
              ),
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      onTimeSelected(picked.hour, picked.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = appState.isDarkMode;
    const primaryColor = Color(0xFF0F5A47);
    const Color accentColor = Color(0xFFD4AF37);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : primaryColor,
        foregroundColor: Colors.white,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: const Text(
            'إعدادات التطبيق',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
              fontSize: 16,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F7F5),
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // 1. المظهر والسمات
            _buildSectionHeader(
                title: 'المظهر والسمات',
                isDark: isDark,
                accentColor: accentColor),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    Icon(isDark ? Icons.dark_mode : Icons.light_mode,
                        color: accentColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'الوضع الليلي (Dark Mode)',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            isDark
                                ? 'تفعيل المظهر الداكن المريح للعين ليلاً'
                                : 'تفعيل المظهر الفاتح والساطع',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Switch(
                      value: isDark,
                      activeColor: accentColor,
                      onChanged: (val) {
                        appState.toggleDarkMode(val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. خط المصحف والتصفح
            _buildSectionHeader(
                title: 'إعدادات خط المصحف',
                isDark: isDark,
                accentColor: accentColor),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'حجم الخط (${appState.fontSize.toInt()})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Icon(Icons.format_size, color: accentColor),
                      ],
                    ),
                    Slider(
                      value: appState.fontSize,
                      min: 16.0,
                      max: 36.0,
                      activeColor: primaryColor,
                      inactiveColor: primaryColor.withOpacity(0.2),
                      onChanged: (val) {
                        appState.setFontSize(val);
                      },
                    ),
                    const Divider(),
                    const Text('نوع الخط العربي:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                        textAlign: TextAlign.right),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                appState.setQuranFontFamily('Amiri'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  appState.quranFontFamily == 'Amiri'
                                      ? primaryColor.withOpacity(0.1)
                                      : Colors.transparent,
                              side: BorderSide(
                                  color: appState.quranFontFamily == 'Amiri'
                                      ? primaryColor
                                      : Colors.grey[300]!),
                            ),
                            child: Text('خط Amiri',
                                style: GoogleFonts.amiri(
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                appState.setQuranFontFamily('Scheherazade'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  appState.quranFontFamily == 'Scheherazade'
                                      ? primaryColor.withOpacity(0.1)
                                      : Colors.transparent,
                              side: BorderSide(
                                  color:
                                      appState.quranFontFamily == 'Scheherazade'
                                          ? primaryColor
                                          : Colors.grey[300]!),
                            ),
                            child: Text('خط Scheherazade',
                                style: GoogleFonts.scheherazadeNew(
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    const Text('سمة خلفية المصحف:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                        textAlign: TextAlign.right),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildThemeOption(context, appState, 'light', 'فاتح',
                            const Color(0xFFFDFBF7), Colors.black87),
                        _buildThemeOption(
                            context,
                            appState,
                            'sepia',
                            'دافئ (Sepia)',
                            const Color(0xFFF4ECD8),
                            const Color(0xFF5B4636)),
                        _buildThemeOption(context, appState, 'dark', 'مظلم',
                            const Color(0xFF1E1E1E), Colors.grey[200]!),
                      ],
                    ),
                    const Divider(),
                    const Text(
                      'معاينة الخط العربي للآيات:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: appState.quranThemeMode == 'dark'
                            ? const Color(0xFF1E1E1E)
                            : (appState.quranThemeMode == 'sepia'
                                ? const Color(0xFFF4ECD8)
                                : const Color(0xFFFDFBF7)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                        style: appState.quranFontFamily == 'Scheherazade'
                            ? GoogleFonts.scheherazadeNew(
                                fontSize: appState.fontSize + 4,
                                fontWeight: FontWeight.bold,
                                color: appState.quranThemeMode == 'dark'
                                    ? Colors.amber[100]
                                    : (appState.quranThemeMode == 'sepia'
                                        ? const Color(0xFF5B4636)
                                        : primaryColor),
                              )
                            : GoogleFonts.amiri(
                                fontSize: appState.fontSize,
                                fontWeight: FontWeight.bold,
                                color: appState.quranThemeMode == 'dark'
                                    ? Colors.amber[100]
                                    : (appState.quranThemeMode == 'sepia'
                                        ? const Color(0xFF5B4636)
                                        : primaryColor),
                              ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. التنبيهات والإشعارات
            _buildSectionHeader(
                title: 'التنبيهات والإشعارات',
                isDark: isDark,
                accentColor: accentColor),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تفعيل إشعارات التذكير اليومي',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const Text(
                            'تذكير بقراءة الورد اليومي وأذكار الصباح والمساء',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Switch(
                      value: appState.notificationsEnabled,
                      activeColor: accentColor,
                      onChanged: (val) {
                        appState.toggleNotifications(val);
                      },
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.notifications_active, color: accentColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: ListTile(
                leading: Icon(Icons.playlist_add_check, color: accentColor),
                title: const Text('إرسال إشعار تجريبي (مؤقت بعد 5 ثوانٍ)',
                    textAlign: TextAlign.right),
                subtitle: const Text(
                  'اضغط هنا لاختبار وصول الإشعارات وسماع صوت التنبيه فوراً',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                trailing: const Icon(Icons.arrow_back_ios, size: 16),
                onTap: () async {
                  try {
                    // Schedule a notification to run 5 seconds from now
                    final testTime =
                        DateTime.now().add(const Duration(seconds: 5));
                    await NotificationService().scheduleNotification(
                      id: 888,
                      title: '🔔 إشعار تجريبي من رفيق القرآن',
                      body:
                          'رائع! خدمة التنبيهات والأصوات تعمل بشكل صحيح وسليم على جهازك 🕌',
                      scheduledDate: testTime,
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'تمت جدولة إشعار تجريبي بنجاح! سيصلك خلال 5 ثوانٍ...',
                              textAlign: TextAlign.right),
                          backgroundColor: Colors.teal,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('فشل إرسال الإشعار التجريبي: $e',
                              textAlign: TextAlign.right),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 12),

            // Periodic Remembrance Card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'تفعيل الإشعارات الدورية (ذكر/آية/حديث)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const Text(
                                'تلقي تنبيهات عشوائية تحتوي على ذكر، آية أو حديث على مدار اليوم',
                                style:
                                    TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Switch(
                          value: appState.periodicDhikrEnabled,
                          activeColor: accentColor,
                          onChanged: (val) {
                            appState.setPeriodicDhikrEnabled(val);
                          },
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.access_alarm, color: accentColor),
                      ],
                    ),
                  ),
                  if (appState.periodicDhikrEnabled) ...[
                    const Divider(indent: 16, endIndent: 16),
                    // Interval choice
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          const Text(
                            'معدل تكرار التذكير:',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: appState.periodicDhikrInterval,
                              dropdownColor: isDark
                                  ? const Color(0xFF2C2C2C)
                                  : Colors.white,
                              style: TextStyle(
                                color:
                                    isDark ? Colors.amber[200] : primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(
                                    value: 60,
                                    child: Text('كل ساعة',
                                        textAlign: TextAlign.right)),
                                DropdownMenuItem(
                                    value: 90,
                                    child: Text('كل ساعة ونصف',
                                        textAlign: TextAlign.right)),
                                DropdownMenuItem(
                                    value: 120,
                                    child: Text('كل ساعتين',
                                        textAlign: TextAlign.right)),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  appState.setPeriodicDhikrInterval(val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(indent: 16, endIndent: 16),
                    // Content type choice
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          const Text(
                            'نوع محتوى التنبيه:',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: appState.periodicDhikrType,
                              dropdownColor: isDark
                                  ? const Color(0xFF2C2C2C)
                                  : Colors.white,
                              style: TextStyle(
                                color:
                                    isDark ? Colors.amber[200] : primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(
                                    value: 'all',
                                    child: Text('الكل (آية / ذكر / حديث)',
                                        textAlign: TextAlign.right)),
                                DropdownMenuItem(
                                    value: 'hadith',
                                    child: Text('أحاديث نبوية فقط',
                                        textAlign: TextAlign.right)),
                                DropdownMenuItem(
                                    value: 'dhikr',
                                    child: Text('أذكار وأدعية فقط',
                                        textAlign: TextAlign.right)),
                                DropdownMenuItem(
                                    value: 'verse',
                                    child: Text('آيات قرآنية فقط',
                                        textAlign: TextAlign.right)),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  appState.setPeriodicDhikrType(val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(indent: 16, endIndent: 16),
                    // Quiet hours settings
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'أوقات الصمت (إيقاف الإشعارات مؤقتاً):',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey),
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Text('من:',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: DropdownButton<int>(
                                        isExpanded: true,
                                        value:
                                            appState.periodicDhikrSilenceStart,
                                        dropdownColor: isDark
                                            ? const Color(0xFF2C2C2C)
                                            : Colors.white,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.amber[200]
                                              : primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        underline: const SizedBox(),
                                        items: List.generate(24, (index) {
                                          final displayHour = index == 0
                                              ? '12 ص'
                                              : index == 12
                                                  ? '12 م'
                                                  : index > 12
                                                      ? '${index - 12} م'
                                                      : '$index ص';
                                          return DropdownMenuItem(
                                              value: index,
                                              child: Text(displayHour));
                                        }),
                                        onChanged: (val) {
                                          if (val != null) {
                                            appState
                                                .setPeriodicDhikrSilenceStart(
                                                    val);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Row(
                                  children: [
                                    const Text('إلى:',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: DropdownButton<int>(
                                        isExpanded: true,
                                        value: appState.periodicDhikrSilenceEnd,
                                        dropdownColor: isDark
                                            ? const Color(0xFF2C2C2C)
                                            : Colors.white,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.amber[200]
                                              : primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        underline: const SizedBox(),
                                        items: List.generate(24, (index) {
                                          final displayHour = index == 0
                                              ? '12 ص'
                                              : index == 12
                                                  ? '12 م'
                                                  : index > 12
                                                      ? '${index - 12} م'
                                                      : '$index ص';
                                          return DropdownMenuItem(
                                              value: index,
                                              child: Text(displayHour));
                                        }),
                                        onChanged: (val) {
                                          if (val != null) {
                                            appState.setPeriodicDhikrSilenceEnd(
                                                val);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // نظام التذكيرات الذكية اليومي
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'نظام التذكيرات الذكية اليومي 🔔',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'تذكيرات ذكية ترافقك طوال يومك للمحافظة على وردك وأذكارك',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.auto_awesome, color: accentColor),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Time Pickers
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تحديد مواعيدك اليومية (انقر لتغيير الوقت):',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Wake-up Time
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectTime(
                                  context,
                                  appState.smartWakeUpHour,
                                  appState.smartWakeUpMinute,
                                  (h, m) => appState.setSmartWakeUpTime(h, m),
                                ),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: primaryColor.withOpacity(0.2)),
                                    borderRadius: BorderRadius.circular(12),
                                    color: primaryColor.withOpacity(0.02),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.wb_sunny_outlined,
                                          color: Colors.orange, size: 20),
                                      const SizedBox(height: 6),
                                      const Text('الاستيقاظ',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTimeOfDay(
                                            appState.smartWakeUpHour,
                                            appState.smartWakeUpMinute),
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: accentColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Return from work
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectTime(
                                  context,
                                  appState.smartReturnHour,
                                  appState.smartReturnMinute,
                                  (h, m) => appState.setSmartReturnTime(h, m),
                                ),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: primaryColor.withOpacity(0.2)),
                                    borderRadius: BorderRadius.circular(12),
                                    color: primaryColor.withOpacity(0.02),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.work_history_outlined,
                                          color: Colors.blue, size: 20),
                                      const SizedBox(height: 6),
                                      const Text('العودة للبيت',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTimeOfDay(
                                            appState.smartReturnHour,
                                            appState.smartReturnMinute),
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: accentColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Bedtime
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectTime(
                                  context,
                                  appState.smartSleepHour,
                                  appState.smartSleepMinute,
                                  (h, m) => appState.setSmartSleepTime(h, m),
                                ),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: primaryColor.withOpacity(0.2)),
                                    borderRadius: BorderRadius.circular(12),
                                    color: primaryColor.withOpacity(0.02),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.dark_mode_outlined,
                                          color: Colors.indigo, size: 20),
                                      const SizedBox(height: 6),
                                      const Text('النوم',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTimeOfDay(
                                            appState.smartSleepHour,
                                            appState.smartSleepMinute),
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: accentColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Wake-up Delay Setting & Content Type Setting
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      children: [
                        // Delay picker
                        Row(
                          children: [
                            const Text(
                              'تأخير التذكير الأول بعد الاستيقاظ:',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButton<int>(
                                isExpanded: true,
                                value: appState.smartWakeUpDelay,
                                dropdownColor: isDark
                                    ? const Color(0xFF2C2C2C)
                                    : Colors.white,
                                style: TextStyle(
                                  color:
                                      isDark ? Colors.amber[200] : primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                underline: const SizedBox(),
                                items: const [
                                  DropdownMenuItem(
                                      value: 5,
                                      child: Text('5 دقائق',
                                          textAlign: TextAlign.right)),
                                  DropdownMenuItem(
                                      value: 15,
                                      child: Text('15 دقيقة',
                                          textAlign: TextAlign.right)),
                                  DropdownMenuItem(
                                      value: 30,
                                      child: Text('30 دقيقة',
                                          textAlign: TextAlign.right)),
                                  DropdownMenuItem(
                                      value: 45,
                                      child: Text('45 دقيقة',
                                          textAlign: TextAlign.right)),
                                  DropdownMenuItem(
                                      value: 60,
                                      child: Text('ساعة واحدة',
                                          textAlign: TextAlign.right)),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    appState.setSmartWakeUpDelay(val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 1),
                        // Content type picker
                        Row(
                          children: [
                            const Text(
                              'نوع محتوى التذكيرات العشوائية:',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: appState.smartContentType,
                                dropdownColor: isDark
                                    ? const Color(0xFF2C2C2C)
                                    : Colors.white,
                                style: TextStyle(
                                  color:
                                      isDark ? Colors.amber[200] : primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                underline: const SizedBox(),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'all',
                                      child: Text('الكل (آية / ذكر / حديث)',
                                          textAlign: TextAlign.left)),
                                  DropdownMenuItem(
                                      value: 'verse',
                                      child: Text('آيات قرآنية فقط',
                                          textAlign: TextAlign.left)),
                                  DropdownMenuItem(
                                      value: 'dhikr',
                                      child: Text('أذكار وأدعية فقط',
                                          textAlign: TextAlign.left)),
                                  DropdownMenuItem(
                                      value: 'hadith',
                                      child: Text('أحاديث نبوية فقط',
                                          textAlign: TextAlign.left)),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    appState.setSmartContentType(val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Switches for 4 reminders
                  SwitchListTile(
                    title: const Text('تذكير الاستيقاظ الأول (آية/ذكر/حديث)',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        'يصلك بعد الاستيقاظ بـ ${appState.smartWakeUpDelay} دقائق ليبدأ يومك بذكر الله',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey)),
                    value: appState.smartWakeUpRem1Enabled,
                    activeColor: accentColor,
                    onChanged: (val) => appState.toggleSmartWakeUpRem1(val),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SwitchListTile(
                    title: const Text('تذكير الورد القرآني الصباحي',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text(
                        'يصلك بعد ساعة من الاستيقاظ ليعينك على تخصيص وقت لوردك',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    value: appState.smartWakeUpRem2Enabled,
                    activeColor: accentColor,
                    onChanged: (val) => appState.toggleSmartWakeUpRem2(val),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SwitchListTile(
                    title: const Text('تذكير العودة من العمل والمحافظة',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text(
                        'أذكار المساء، أو تذكير بالصلاة على النبي ﷺ ومتابعة الورد',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    value: appState.smartReturnRemEnabled,
                    activeColor: accentColor,
                    onChanged: (val) => appState.toggleSmartReturnRem(val),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SwitchListTile(
                    title: const Text('تذكير النوم والاستعداد',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text(
                        'يصلك قبل موعد النوم بـ 30 دقيقة لقراءة أذكار النوم وسورة الملك',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    value: appState.smartSleepRemEnabled,
                    activeColor: accentColor,
                    onChanged: (val) => appState.toggleSmartSleepRem(val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. المساعد الذكي (AI)
            _buildSectionHeader(
                title: 'إعدادات المساعد الذكي (AI)',
                isDark: isDark,
                accentColor: accentColor),
            _GeminiApiKeySettings(
              appState: appState,
              isDark: isDark,
              primaryColor: primaryColor,
              accentColor: accentColor,
            ),
            const SizedBox(height: 20),

            // 5. إدارة البيانات والخصوصية
            _buildSectionHeader(
                title: 'إدارة البيانات المحلية',
                isDark: isDark,
                accentColor: accentColor),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: ListTile(
                title: const Text('تهيئة التطبيق بالكامل (Factory Reset)',
                    textAlign: TextAlign.right),
                subtitle: const Text(
                  'حذف كافة البيانات والتقدم والعودة للوضع الأصلي',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: const Icon(Icons.delete_forever, color: Colors.red),
                onTap: () => _showResetConfirmation(context, appState),
              ),
            ),
            const SizedBox(height: 20),

            // 6. حول التطبيق
            _buildSectionHeader(
                title: 'حول رفيق القرآن',
                isDark: isDark,
                accentColor: accentColor),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('1.1.0',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('إصدار التطبيق',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'رفيق القرآن هو تطبيق إسلامي متكامل يهدف إلى مساعدتك في قراءة وتلاوة القرآن الكريم وحفظه وتدبر آياته، ومتابعة الورد اليومي والختمات مع المسبحة الإلكترونية والأذكار اليومية بطابع مريح وجميل وعملي.',
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                          height: 1.5),
                      textAlign: TextAlign.justify,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'صدقة جارية لكل من ساهم في نشره واستخدمه 🤲',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                '© 2026 Mohamed Elsalamony. All Rights Reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[600] : Colors.grey[500],
                  fontFamily: 'Outfit',
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      {required String title,
      required bool isDark,
      required Color accentColor}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.teal[100] : Colors.teal.shade800,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    AppState appState,
    String mode,
    String label,
    Color bg,
    Color fg,
  ) {
    final isSelected = appState.quranThemeMode == mode;
    return GestureDetector(
      onTap: () => appState.setQuranThemeMode(mode),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFD4AF37)
                    : Colors.grey.withOpacity(0.3),
                width: isSelected ? 3.0 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: const Color(0xFFD4AF37).withOpacity(0.4),
                          blurRadius: 6)
                    ]
                  : null,
            ),
            child: Icon(Icons.check,
                color: isSelected ? fg : Colors.transparent, size: 18),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _GeminiApiKeySettings extends StatefulWidget {
  final AppState appState;
  final bool isDark;
  final Color primaryColor;
  final Color accentColor;

  const _GeminiApiKeySettings({
    required this.appState,
    required this.isDark,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  State<_GeminiApiKeySettings> createState() => _GeminiApiKeySettingsState();
}

class _GeminiApiKeySettingsState extends State<_GeminiApiKeySettings> {
  late TextEditingController _controller;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.appState.geminiApiKey);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'مفتاح Gemini API Key',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'لتشغيل المساعد الذكي "اسأل عن دينك"',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.key, color: widget.accentColor),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              obscureText: _obscureText,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: widget.isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'أدخل مفتاح Gemini API هنا...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                prefixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: widget.primaryColor.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: widget.primaryColor, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('كيفية الحصول على مفتاح مجاني؟',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        content: const Text(
                          '1. اذهب لموقع Google AI Studio (aistudio.google.com)\n'
                          '2. قم بتسجيل الدخول بحساب Google الخاص بك.\n'
                          '3. اضغط على زر "Get API key" ثم قم بإنشاء مفتاح جديد.\n'
                          '4. انسخ المفتاح والصقه هنا في هذا الحقل لتفعيل المساعد الذكي.',
                          textAlign: TextAlign.right,
                          style: TextStyle(height: 1.5, fontSize: 13),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('حسناً فهمت'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.help_outline,
                      size: 16, color: Colors.blue),
                  label: const Text('كيف أحصل على مفتاح مجاني؟',
                      style: TextStyle(fontSize: 11, color: Colors.blue)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  onPressed: () async {
                    final newKey = _controller.text.trim();
                    await widget.appState.setGeminiApiKey(newKey);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم حفظ مفتاح API بنجاح!',
                              textAlign: TextAlign.right),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('حفظ المفتاح',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
