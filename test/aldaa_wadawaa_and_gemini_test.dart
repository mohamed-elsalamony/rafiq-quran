import 'package:flutter_test/flutter_test.dart';
import 'package:rafiq_quran/core/services/aldaa_wadawaa_service.dart';
import 'package:rafiq_quran/core/services/gemini_service.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:typed_data';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock AssetBundle to return sample JSON content for testing offline assets
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
      if (message == null) return null;
      final Uint8List list = message.buffer.asUint8List();
      final String key = utf8.decode(list, allowMalformed: true);
      
      if (key.contains('aldaa_wadawaa.json')) {
        final data = [
          {
            "id": 1,
            "title": "مقدمة الكتاب والفتوى في السؤال",
            "content": "سئل الشيخ الإمام العالم العارف بالله شمس الدين محمد بن أبي بكر بن أيوب قيم الجوزية",
            "page": 5
          },
          {
            "id": 2,
            "title": "الدعاء من أنفع الأدوية",
            "content": "والدعاء من أنفع الأدوية، وهو عدو البلاء، يدافعه ويعالجه",
            "page": 9
          }
        ];
        final bytes = utf8.encode(json.encode(data));
        return ByteData.sublistView(Uint8List.fromList(bytes));
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  group('Aldaa Wadawaa Service Tests', () {
    test('Load, get, search and parse chapters', () async {
      final service = AldaaWadawaaService();
      await service.loadChapters();

      final chapters = service.getAllChapters();
      expect(chapters.length, 2);
      expect(chapters[0].title, 'مقدمة الكتاب والفتوى في السؤال');
      expect(chapters[0].page, 5);

      final chapter = service.getChapterById(2);
      expect(chapter, isNotNull);
      expect(chapter!.title, 'الدعاء من أنفع الأدوية');

      final searchResults = service.searchChapters('الجواب الكافي');
      // "الجواب الكافي" is not in title/content/page
      expect(searchResults.length, 0);

      final searchTitle = service.searchChapters('الدعاء');
      expect(searchTitle.length, 1);
      expect(searchTitle[0].id, 2);

      final searchPage = service.searchChapters('5');
      expect(searchPage.length, 1);
      expect(searchPage[0].id, 1);
    });
  });

  group('Gemini Service Configuration Tests', () {
    test('Initialize and verify instruction constraints', () {
      final service = GeminiService();
      
      // Test isInitialized is true due to local fallback availability
      expect(service.isInitialized, isTrue);

      // Verify instruction system rules
      const instruction = GeminiService.systemInstruction;
      expect(instruction, contains('ذكاء اصطناعي'));
      expect(instruction, contains('مساعد'));
      expect(instruction, contains('علماء'));
      expect(instruction, contains('فتوى'));
    });
  });
}
