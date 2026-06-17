import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rafiq_quran/core/services/db_helper.dart';
import 'package:rafiq_quran/features/quran/presentation/khatm_celebration_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Khatm Quran Supplication & Database Logs Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Add, Retrieve, and Clear Khatm Completion Logs', () async {
      // Step 1: Ensure initial log history is empty
      var history = await DbHelper.getKhatmHistory();
      expect(history, isEmpty);

      // Step 2: Add a log and check it persists
      await DbHelper.addKhatmLog();
      history = await DbHelper.getKhatmHistory();
      expect(history.length, 1);
      expect(history[0]['id'], isNotNull);
      expect(history[0]['date'], isNotNull);

      // Step 3: Add a second log and check order
      await DbHelper.addKhatmLog();
      history = await DbHelper.getKhatmHistory();
      expect(history.length, 2);

      // Step 4: Clear logs and verify they are deleted
      await DbHelper.clearKhatmHistory();
      history = await DbHelper.getKhatmHistory();
      expect(history, isEmpty);
    });

    test('Khatm Celebration Screen Supplication Text Presence', () {
      // Ensure the authentic Prophetic supplication text is non-empty
      const suppText = KhatmCelebrationScreen.supplicationText;
      expect(suppText, isNotEmpty);
      expect(suppText, contains('اللَّهُمَّ ارْحَمْنِي بالقُرْآنِ'));
      expect(suppText, contains('اللَّهُمَّ أَصْلِحْ لِي دِينِي'));
      expect(suppText, contains('اللَّهُمَّ اجْعَلْ خَيْرَ عُمْرِي آخِرَهُ'));
    });
  });
}
