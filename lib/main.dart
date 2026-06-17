import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/services/app_state.dart';
import 'core/services/notification_service.dart';
import 'core/services/prophet_blessing_service.dart';
import 'core/services/periodic_notification_helper.dart';
import 'core/services/prayer_service.dart';
import 'core/services/hadith_service.dart';
import 'core/services/widget_update_service.dart';
import 'package:adhan/adhan.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/quran/presentation/quran_screen.dart';
import 'features/adhkar/presentation/adhkar_screen.dart';
import 'features/tasbih/presentation/tasbih_screen.dart';
import 'features/prayer_times/presentation/prayer_qibla_screen.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/hifz_khatma/presentation/hifz_khatma_screen.dart';

import 'features/quran/presentation/quran_provider.dart';
import 'features/tasbih/presentation/tasbih_provider.dart';
import 'features/prayer_times/presentation/prayer_provider.dart';
import 'features/adhkar/presentation/adhkar_provider.dart';
import 'features/onboarding/presentation/splash_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/settings/presentation/settings_screen.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().executeTask((task, inputData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Update widget first in background task
      final savedCity = prefs.getString('prayer_selected_city') ?? 'القاهرة';
      final savedMethodName =
          prefs.getString('prayer_calculation_method') ?? '';

      double? lat;
      double? lon;
      CalculationMethod method = CalculationMethod.egyptian;

      if (savedCity == 'موقعي الحالي') {
        lat = prefs.getDouble('prayer_loc_lat');
        lon = prefs.getDouble('prayer_loc_lon');
      } else if (PrayerService.defaultCities.containsKey(savedCity)) {
        final defaultCity = PrayerService.defaultCities[savedCity]!;
        lat = defaultCity.latitude;
        lon = defaultCity.longitude;
        method = defaultCity.method;
      }

      if (savedMethodName.isNotEmpty) {
        method = CalculationMethod.values
            .firstWhere((m) => m.name == savedMethodName, orElse: () => method);
      }

      if (lat != null && lon != null) {
        final coords = Coordinates(lat, lon);
        final hadithService = HadithService();
        await hadithService.loadHadiths();
        final hadith = await hadithService.getHadithOfDay();

        await WidgetUpdateService.updateWidget(
          coordinates: coords,
          method: method,
          cityName: savedCity,
          dailyAyah: "إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ",
          dailyHadith: hadith?.text ?? "خيركم من تعلم القرآن وعلمه",
        );
      }
    } catch (e) {
      debugPrint("Error updating widget in background task: $e");
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('periodic_dhikr_enabled') ?? false;
      if (!enabled) return true;

      final type = prefs.getString('periodic_dhikr_type') ?? 'all';
      final silenceStart = prefs.getInt('periodic_dhikr_silence_start') ?? 22;
      final silenceEnd = prefs.getInt('periodic_dhikr_silence_end') ?? 5;

      final now = DateTime.now();
      final currentHour = now.hour;

      bool inSilence = false;
      if (silenceStart == silenceEnd) {
        inSilence = false; // No silence window if both hours are the same
      } else if (silenceStart < silenceEnd) {
        inSilence = currentHour >= silenceStart && currentHour < silenceEnd;
      } else {
        inSilence = currentHour >= silenceStart || currentHour < silenceEnd;
      }

      if (inSilence) {
        debugPrint("Periodic Notification: Skipped due to quiet hours.");
        return true;
      }

      final content = PeriodicNotificationHelper.getRandomContent(type);
      final id = Random().nextInt(10000) + 5000;
      await PeriodicNotificationHelper.showNotification(
        id: id,
        title: content['title'] ?? 'رفيق القرآن',
        body: content['body'] ?? 'اذكر الله',
      );
    } catch (e) {
      debugPrint("Error in WorkManager execution: $e");
    }
    return true;
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة خدمة الإشعارات — ضرورية لعمل جميع التنبيهات
  try {
    await NotificationService().init();
    debugPrint("NotificationService initialized in main()");
  } catch (e) {
    debugPrint("NotificationService initialization failed: $e");
  }

  try {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
  } catch (e) {
    debugPrint("Workmanager initialization failed: $e");
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppState()),
        ChangeNotifierProxyProvider<AppState, QuranProvider>(
          create: (context) => QuranProvider(
              appState: Provider.of<AppState>(context, listen: false)),
          update: (context, appState, previous) =>
              previous ?? QuranProvider(appState: appState),
        ),
        ChangeNotifierProvider(create: (context) => TasbihProvider()),
        ChangeNotifierProvider(create: (context) => PrayerProvider()),
        ChangeNotifierProvider(create: (context) => AdhkarProvider()),
        ChangeNotifierProvider(create: (context) => ProphetBlessingService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    const Color primaryColor = Color(0xFF0F5A47);
    const Color accentColor = Color(0xFFD4AF37);

    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: 'رفيق القرآن',
      debugShowCheckedModeBanner: false,
      locale: const Locale(
          'ar', 'AE'), // تشغيل التطبيق باللغة العربية RTL افتراضياً
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'AE'),
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },

      // السمة الفاتحة الفاخرة
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
          primary: primaryColor,
          secondary: accentColor,
          background: const Color(0xFFF9FBF9),
        ),
        textTheme: GoogleFonts.outfitTextTheme().copyWith(
          bodyLarge: GoogleFonts.amiri(fontSize: 16),
          bodyMedium: GoogleFonts.amiri(fontSize: 14),
        ),
      ),

      // السمة المظلمة الفاخرة
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
          primary: primaryColor,
          secondary: accentColor,
          background: const Color(0xFF121212),
        ),
        textTheme: GoogleFonts.outfitTextTheme().copyWith(
          bodyLarge: GoogleFonts.amiri(fontSize: 16, color: Colors.grey[200]),
          bodyMedium: GoogleFonts.amiri(fontSize: 14, color: Colors.grey[300]),
        ),
      ),

      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const MainShell(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  bool _isInit = false;

  final List<Widget> _tabs = [];

  @override
  void initState() {
    super.initState();
    _tabs.addAll([
      const QuranScreen(),
      const AdhkarScreen(),
      HomeScreen(onTabChanged: _onTabChanged),
      const TasbihScreen(),
      const PrayerQiblaScreen(),
    ]);
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    final appState = Provider.of<AppState>(context, listen: false);
    appState.saveLastScreen(_getScreenNameFromIndex(index));
  }

  String _getScreenNameFromIndex(int index) {
    switch (index) {
      case 0:
        return 'quran';
      case 1:
        return 'adhkar';
      case 2:
        return 'home';
      case 3:
        return 'tasbih';
      case 4:
        return 'prayer';
      default:
        return 'home';
    }
  }

  int _getIndexFromScreenName(String name) {
    switch (name) {
      case 'quran':
        return 0;
      case 'adhkar':
        return 1;
      case 'home':
        return 2;
      case 'tasbih':
        return 3;
      case 'prayer':
        return 4;
      default:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    const Color primaryColor = Color(0xFF0F5A47);
    const Color accentColor = Color(0xFFD4AF37);
    final isDark = appState.isDarkMode;

    final double screenWidth = MediaQuery.of(context).size.width;
    final double tabWidth = screenWidth / 5;
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;

    // دائماً يفتح على الرئيسية عند الإقلاع الأول أو عند التوجيه من إشعار
    if (!_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        _currentIndex = _getIndexFromScreenName(args);
      } else {
        _currentIndex = 2;
      }
      _isInit = true;
    }

    return Scaffold(
      drawer: Drawer(
        child: Container(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // رأس القائمة الجانبية
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, const Color(0xFF073A2F)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'رفيق القرآن',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'إصدار 1.1.0',
                      style: TextStyle(color: Colors.teal[100], fontSize: 12),
                    ),
                  ],
                ),
              ),

              // خيارات التنقل والخدمات المساعدة
              ListTile(
                title: const Text('الحساب والمزامنة السحابية',
                    textAlign: TextAlign.right),
                trailing: const Icon(Icons.cloud_sync, color: Colors.teal),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AuthScreen()));
                },
              ),
              ListTile(
                title:
                    const Text('الورد وحفظ القرآن', textAlign: TextAlign.right),
                trailing: const Icon(Icons.assignment, color: Colors.teal),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HifzKhatmaScreen()));
                },
              ),
              ListTile(
                title:
                    const Text('إعدادات التطبيق', textAlign: TextAlign.right),
                trailing: const Icon(Icons.settings, color: Colors.teal),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/settings');
                },
              ),
              const Divider(),

              // التحكم بحجم خط المصحف في القائمة الجانبية مباشرة
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'حجم خط المصحف (${appState.fontSize.toInt()})',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                      textAlign: TextAlign.right,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: _currentIndex == 2
          ? AppBar(
              backgroundColor: isDark ? const Color(0xFF1F1F1F) : primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'رفيق القرآن',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
      body: _tabs[_currentIndex],
      bottomNavigationBar: _buildBottomNavigationBar(
        screenWidth,
        tabWidth,
        isRtl,
        isDark,
        primaryColor,
        accentColor,
      ),
    );
  }

  Widget _buildBottomNavigationBar(
    double screenWidth,
    double tabWidth,
    bool isRtl,
    bool isDark,
    Color primaryColor,
    Color accentColor,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      height: 72,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E).withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : primaryColor.withOpacity(0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Row(
          children: [
            _buildNavItem(0, Icons.menu_book_outlined, 'المصحف', isDark,
                primaryColor, accentColor),
            _buildNavItem(1, Icons.library_books_outlined, 'الأذكار', isDark,
                primaryColor, accentColor),
            _buildNavItem(2, Icons.home_outlined, 'الرئيسية', isDark,
                primaryColor, accentColor),
            _buildNavItem(3, Icons.fingerprint_outlined, 'السبحة', isDark,
                primaryColor, accentColor),
            _buildNavItem(4, Icons.explore_outlined, 'الصلاة', isDark,
                primaryColor, accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    bool isDark,
    Color primaryColor,
    Color accentColor,
  ) {
    final bool isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTabChanged(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: isSelected
                  ? (Matrix4.identity()..translate(0.0, -2.0))
                  : Matrix4.identity(),
              child: Icon(
                isSelected ? _getIconForIndex(index, isActive: true) : icon,
                color: isSelected
                    ? accentColor
                    : (isDark ? Colors.white54 : Colors.grey[500]),
                size: isSelected ? 24 : 20,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? accentColor
                      : (isDark ? Colors.white54 : Colors.grey[600]),
                  fontFamily: 'Amiri',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 6 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForIndex(int index, {required bool isActive}) {
    switch (index) {
      case 0:
        return isActive ? Icons.menu_book : Icons.menu_book_outlined;
      case 1:
        return isActive ? Icons.library_books : Icons.library_books_outlined;
      case 2:
        return isActive ? Icons.home : Icons.home_outlined;
      case 3:
        return isActive ? Icons.fingerprint : Icons.fingerprint_outlined;
      case 4:
        return isActive ? Icons.explore : Icons.explore_outlined;
      default:
        return Icons.home;
    }
  }
}
