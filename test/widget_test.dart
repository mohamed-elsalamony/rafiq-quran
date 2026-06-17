import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rafiq_quran/main.dart';
import 'package:rafiq_quran/core/services/app_state.dart';
import 'package:rafiq_quran/features/quran/presentation/quran_provider.dart';
import 'package:rafiq_quran/features/tasbih/presentation/tasbih_provider.dart';
import 'package:rafiq_quran/features/prayer_times/presentation/prayer_provider.dart';
import 'package:rafiq_quran/features/adhkar/presentation/adhkar_provider.dart';
import 'package:rafiq_quran/core/services/prophet_blessing_service.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    
    await tester.pumpWidget(
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

    // Settle the splash screen timer (3 seconds)
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Verify that the App starts and builds MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
