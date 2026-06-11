import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/services/app_state.dart';
import 'core/services/prophet_blessing_service.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization failed: $e. Falling back to simulation mode.");
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppState()),
        ChangeNotifierProxyProvider<AppState, QuranProvider>(
          create: (context) => QuranProvider(appState: Provider.of<AppState>(context, listen: false)),
          update: (context, appState, previous) => previous ?? QuranProvider(appState: appState),
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
    final Color primaryColor = const Color(0xFF0F5A47);
    final Color accentColor = const Color(0xFFD4AF37);

    return MaterialApp(
      title: 'رفيق القرآن',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'AE'), // تشغيل التطبيق باللغة العربية RTL افتراضياً
      
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
      HomeScreen(onTabChanged: _onTabChanged),
      const QuranScreen(),
      const AdhkarScreen(),
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
      case 0: return 'home';
      case 1: return 'quran';
      case 2: return 'adhkar';
      case 3: return 'tasbih';
      case 4: return 'prayer';
      default: return 'home';
    }
  }

  int _getIndexFromScreenName(String name) {
    switch (name) {
      case 'home': return 0;
      case 'quran': return 1;
      case 'adhkar': return 2;
      case 'tasbih': return 3;
      case 'prayer': return 4;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final Color primaryColor = const Color(0xFF0F5A47);
    final Color accentColor = const Color(0xFFD4AF37);
    final isDark = appState.isDarkMode;

    // دائماً يفتح على الرئيسية عند الإقلاع الأول، ونلغي الاستعادة التلقائية لآخر شاشة
    if (!_isInit) {
      _currentIndex = 0;
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
                leading: const Icon(Icons.cloud_sync, color: Colors.teal),
                title: const Text('الحساب والمزامنة السحابية', textAlign: TextAlign.right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AuthScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.assignment, color: Colors.teal),
                title: const Text('الورد وحفظ القرآن', textAlign: TextAlign.right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const HifzKhatmaScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.teal),
                title: const Text('إعدادات التطبيق', textAlign: TextAlign.right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/settings');
                },
              ),
              const Divider(),
              
              // التحكم بحجم خط المصحف في القائمة الجانبية مباشرة
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'حجم خط المصحف (${appState.fontSize.toInt()})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
      appBar: AppBar(
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
            Text(
              'رفيق القرآن',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: accentColor,
        unselectedItemColor: isDark ? Colors.white60 : Colors.grey[600],
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: accentColor,
          fontFamily: 'Outfit',
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          color: isDark ? Colors.white60 : Colors.grey[600],
          fontFamily: 'Outfit',
        ),
        selectedIconTheme: IconThemeData(size: 26, color: accentColor),
        unselectedIconTheme: IconThemeData(size: 22, color: isDark ? Colors.white60 : Colors.grey[600]),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), activeIcon: Icon(Icons.menu_book), label: 'المصحف'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books_outlined), activeIcon: Icon(Icons.library_books), label: 'الأذكار'),
          BottomNavigationBarItem(icon: Icon(Icons.fingerprint_outlined), activeIcon: Icon(Icons.fingerprint), label: 'السبحة'),
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'الصلاة'),
        ],
      ),
    );
  }
}
