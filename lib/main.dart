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

    final double screenWidth = MediaQuery.of(context).size.width;
    final double tabWidth = screenWidth / 5;
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;

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
      appBar: _currentIndex == 0
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
                  Text(
                    'رفيق القرآن',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
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
    final double targetX = isRtl
        ? screenWidth - (_currentIndex + 0.5) * tabWidth
        : (_currentIndex + 0.5) * tabWidth;

    return Container(
      height: 70, // Extra height for the floating active button overflow
      color: Colors.transparent,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: targetX, end: targetX),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        builder: (context, animX, child) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Notched base background path
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 60,
                child: CustomPaint(
                  painter: NotchedBasePainter(
                    centerX: animX,
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  ),
                ),
              ),

              // 2. Floating Circular Active Button
              Positioned(
                left: animX - 28,
                bottom: 14,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor,
                    border: Border.all(color: accentColor, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getIconForIndex(_currentIndex, isActive: true),
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),

              // 3. Row of tab actions
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 60,
                child: Row(
                  children: [
                    _buildNavItem(0, Icons.home_outlined, 'الرئيسية', isDark, accentColor),
                    _buildNavItem(1, Icons.menu_book_outlined, 'المصحف', isDark, accentColor),
                    _buildNavItem(2, Icons.library_books_outlined, 'الأذكار', isDark, accentColor),
                    _buildNavItem(3, Icons.fingerprint_outlined, 'السبحة', isDark, accentColor),
                    _buildNavItem(4, Icons.explore_outlined, 'الصلاة', isDark, accentColor),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    bool isDark,
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
            if (isSelected)
              const SizedBox(height: 24)
            else
              Icon(
                icon,
                color: isDark ? Colors.white60 : Colors.grey[600],
                size: 22,
              ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? accentColor
                    : (isDark ? Colors.white60 : Colors.grey[600]),
                fontFamily: 'Outfit',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForIndex(int index, {required bool isActive}) {
    switch (index) {
      case 0:
        return isActive ? Icons.home : Icons.home_outlined;
      case 1:
        return isActive ? Icons.menu_book : Icons.menu_book_outlined;
      case 2:
        return isActive ? Icons.library_books : Icons.library_books_outlined;
      case 3:
        return isActive ? Icons.fingerprint : Icons.fingerprint_outlined;
      case 4:
        return isActive ? Icons.explore : Icons.explore_outlined;
      default:
        return Icons.home;
    }
  }
}

class NotchedBasePainter extends CustomPainter {
  final double centerX;
  final Color color;

  NotchedBasePainter({
    required this.centerX,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final double notchRadius = 35.0;
    final double notchDepth = 25.0;

    path.moveTo(0, 0);
    path.lineTo(centerX - notchRadius - 10, 0);

    path.cubicTo(
      centerX - notchRadius,
      0,
      centerX - notchRadius + 8,
      notchDepth,
      centerX,
      notchDepth,
    );

    path.cubicTo(
      centerX + notchRadius - 8,
      notchDepth,
      centerX + notchRadius,
      0,
      centerX + notchRadius + 10,
      0,
    );

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawShadow(path, Colors.black26, 6.0, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant NotchedBasePainter oldDelegate) {
    return oldDelegate.centerX != centerX || oldDelegate.color != color;
  }
}
