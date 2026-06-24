import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/fcm_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  bool _notificationsAllowed = true;
  bool _isLoadingPermission = true;

  late TextEditingController _backendUrlController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
    
    final appState = Provider.of<AppState>(context, listen: false);
    _backendUrlController = TextEditingController(text: appState.backendUrl);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _backendUrlController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final allowed = await NotificationService().areNotificationsEnabled();
    if (mounted) {
      setState(() {
        _notificationsAllowed = allowed;
        _isLoadingPermission = false;
      });
    }
  }

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
                        crossAxisAlignment: CrossAxisAlignment.start,
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
            
            // Warning banner if permissions are disabled at system level
            if (!_isLoadingPermission && !_notificationsAllowed) ...[
              Card(
                color: Colors.red.shade900.withOpacity(0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.red.shade800.withOpacity(0.3), width: 1.2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade600, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'إشعارات النظام معطلة ⚠️',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.redAccent,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'تم تعطيل إشعارات التطبيق في إعدادات الهاتف. لن تتمكن من تلقي أوقات الصلاة والتذكيرات اليومية.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final success = await NotificationService().requestPermission();
                            if (!success) {
                              try {
                                await Geolocator.openAppSettings();
                              } catch (e) {
                                debugPrint("Error opening app settings: $e");
                              }
                            }
                            _checkPermission();
                          },
                          icon: const Icon(Icons.settings, size: 16, color: Colors.white),
                          label: const Text(
                            'تفعيل من إعدادات الهاتف',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade800,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

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
                      onChanged: (val) async {
                        await appState.toggleNotifications(val);
                        _checkPermission();
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
                title: const Text('إرسال إشعار تجريبي فوري',
                    textAlign: TextAlign.right),
                subtitle: const Text(
                  'اضغط هنا لاختبار وصول الإشعارات وسماع صوت التنبيه فوراً',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                trailing: const Icon(Icons.arrow_back_ios, size: 16),
                onTap: () async {
                  try {
                    // Check if system notifications are allowed first
                    final allowed = await NotificationService().areNotificationsEnabled();
                    if (!allowed) {
                      throw Exception("صلاحية الإشعارات معطلة في النظام. يرجى تفعيلها أولاً.");
                    }

                    // Show notification instantly (0 seconds delay)
                    await NotificationService().showInstantNotification(
                      id: 888,
                      title: '🔔 إشعار تجريبي فوري من رفيق القرآن',
                      body:
                          'رائع! خدمة التنبيهات والأصوات تعمل بشكل صحيح وسليم على جهازك 🕌',
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'تم إرسال إشعار تجريبي فوري بنجاح!',
                              textAlign: TextAlign.right),
                          backgroundColor: Colors.teal,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      final msg = e.toString().replaceAll('Exception:', '').trim();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('فشل إرسال الإشعار التجريبي: $msg',
                              textAlign: TextAlign.right),
                          backgroundColor: Colors.red.shade900,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 12),

            // FCM Token & Status Card
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
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'خدمة الإشعارات السحابية (FCM)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: FcmService().isInitialized
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    FcmService().isInitialized
                                        ? 'نشط ومتصل بـ Firebase'
                                        : 'غير نشط (لم يتم تهيئة Firebase)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: FcmService().isInitialized
                                          ? Colors.green
                                          : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.cloud_sync_outlined, color: accentColor),
                      ],
                    ),
                    if (FcmService().isInitialized && FcmService().fcmToken != null) ...[
                      const Divider(height: 20),
                      const Text(
                        'رمز تسجيل الجهاز (FCM Token):',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black26 : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[350]!),
                              ),
                              child: SelectableText(
                                FcmService().fcmToken!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: FcmService().fcmToken!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم نسخ رمز FCM Token للحافظة بنجاح', textAlign: TextAlign.right),
                                  backgroundColor: Colors.teal,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
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
                          onChanged: (val) async {
                            await appState.setPeriodicDhikrEnabled(val);
                            _checkPermission();
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
                                      child: Text('الكل (آية / ذكر / حديث)')),
                                  DropdownMenuItem(
                                      value: 'verse',
                                      child: Text('آيات قرآنية فقط')),
                                  DropdownMenuItem(
                                      value: 'dhikr',
                                      child: Text('أذكار وأدعية فقط')),
                                  DropdownMenuItem(
                                      value: 'hadith',
                                      child: Text('أحاديث نبوية فقط')),
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

            // 4. إدارة حالة المساعد (AI Backend)
            _buildSectionHeader(
                title: 'إدارة حالة المساعد (AI Backend)',
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
                    // العنوان والرمز وحالة الاتصال
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'خادم المساعد الذكي (Firebase Functions)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              // شارة حالة الاتصال
                              _buildStatusBadge(appState.assistantStatus, isDark),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: appState.assistantStatus == 'online'
                              ? const Color(0xFFE8F8F5)
                              : (appState.assistantStatus == 'local'
                                  ? Colors.orange.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1)),
                          child: Icon(
                            appState.assistantStatus == 'online'
                                ? Icons.auto_awesome
                                : (appState.assistantStatus == 'local'
                                    ? Icons.cloud_off_rounded
                                    : Icons.error_outline_rounded),
                            color: appState.assistantStatus == 'online'
                                ? const Color(0xFF0F5A47)
                                : (appState.assistantStatus == 'local'
                                    ? Colors.orange
                                    : Colors.red),
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // آخر وقت اتصال ناجح
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          appState.lastSuccessfulConnection.isNotEmpty
                              ? appState.lastSuccessfulConnection
                              : 'غير متوفر',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey[300] : Colors.black87,
                          ),
                        ),
                        const Text(
                          'آخر وقت اتصال ناجح:',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    // حقل إدخال عنوان السيرفر
                    TextField(
                      controller: _backendUrlController,
                      decoration: InputDecoration(
                        labelText: 'رابط دالة Firebase Functions السحابية',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.grey[350] : primaryColor,
                          fontSize: 12,
                        ),
                        hintText: 'https://<region>-<project-id>.cloudfunctions.net/api',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 11),
                        prefixIcon: Icon(Icons.dns_rounded, color: accentColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(height: 12),
                    // أزرار التحكم
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // زر استعادة الافتراضي والمساعدة
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                _backendUrlController.text = 'http://10.0.2.2:3000';
                                appState.setBackendUrl('http://10.0.2.2:3000');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم استعادة عنوان المحاكي الافتراضي للتطوير المحلي',
                                        textAlign: TextAlign.right),
                                  ),
                                );
                              },
                              child: const Text(
                                'الافتراضي المحلي',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 4),
                            TextButton(
                              onPressed: () => _showBackendHelpDialog(context, isDark),
                              child: Text(
                                'دليل النشر',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: accentColor),
                              ),
                            ),
                          ],
                        ),
                        // زر الحفظ وفحص الاتصال
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: () async {
                                await appState.checkBackendStatus();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      appState.assistantStatus == 'online'
                                          ? 'تم الاتصال بالدالة السحابية بنجاح!'
                                          : 'تعذر الاتصال بالدالة. تأكد من نشرها وصحة الرابط.',
                                      textAlign: TextAlign.right,
                                    ),
                                    backgroundColor: appState.assistantStatus == 'online'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: primaryColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('فحص الاتصال', style: TextStyle(fontSize: 11)),
                            ),
                            const SizedBox(width: 6),
                            ElevatedButton(
                              onPressed: () async {
                                final url = _backendUrlController.text.trim();
                                await appState.setBackendUrl(url);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      appState.assistantStatus == 'online'
                                          ? 'تم حفظ العنوان والاتصال بنجاح!'
                                          : 'تم حفظ العنوان، ولكن تعذر الاتصال بالدالة.',
                                      textAlign: TextAlign.right,
                                    ),
                                    backgroundColor: appState.assistantStatus == 'online'
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'حفظ وتفعيل',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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

  Widget _buildStatusBadge(String status, bool isDark) {
    MaterialColor badgeColor;
    String badgeText;
    IconData icon;

    switch (status) {
      case 'online':
        badgeColor = Colors.green;
        badgeText = 'متصل بالمساعد الذكي (Online)';
        icon = Icons.check_circle_rounded;
        break;
      case 'failed':
        badgeColor = Colors.red;
        badgeText = 'فشل الاتصال بالسيرفر (Error)';
        icon = Icons.cancel_rounded;
        break;
      case 'local':
      default:
        badgeColor = Colors.orange;
        badgeText = 'يعمل بوضع محلي (Offline)';
        icon = Icons.offline_bolt_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: badgeColor),
          const SizedBox(width: 6),
          Text(
            badgeText,
            style: TextStyle(
              color: isDark ? badgeColor.withOpacity(0.85) : badgeColor.shade800,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showBackendHelpDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'دليل نشر وربط دالة Firebase Functions',
          textAlign: TextAlign.right,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F5A47)),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'لتأمين مفاتيح الـ API وتحسين ذكاء المساعد، يجب إعداد ونشر دالة Firebase السحابية باتباع الخطوات التالية:',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 12),
              _buildStepRow('1', 'افتح مجلد "functions" الموجود في جذر هذا المشروع.'),
              _buildStepRow('2', 'قم بتثبيت الاعتمادات بتشغيل الأمر: npm install في الطرفية داخل مجلد functions.'),
              _buildStepRow('3', 'انسخ الملف .env.example إلى .env وافتحه لإضافة مفتاح Gemini الخاص بك في GEMINI_API_KEY.'),
              _buildStepRow('4', 'تأكد من تثبيت Firebase CLI وتسجيل الدخول: npm install -g firebase-tools ثم firebase login.'),
              _buildStepRow('5', 'اربط مشروعك السحابي بتشغيل: firebase use --add، ثم انشر الدالة بالأمر: firebase deploy --only functions.'),
              _buildStepRow('6', 'بعد نجاح النشر، انسخ الرابط الناتج (الذي ينتهي بـ /api) وضعه في حقل رابط دالة Firebase Functions في التطبيق.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('فهمت'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(String stepNum, String stepText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 9,
            backgroundColor: const Color(0xFFD4AF37),
            child: Text(
              stepNum,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              stepText,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
          ),
        ],
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
