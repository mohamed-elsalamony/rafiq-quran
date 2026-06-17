import 'package:flutter_test/flutter_test.dart';
import 'package:rafiq_quran/core/services/prophets_stories_service.dart';
import 'package:rafiq_quran/core/services/seerah_service.dart';
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
      // The key is sent as the UTF-8 encoded string.
      // Wait, in older/some versions the key might have a leading length byte or be raw string.
      // We can check if the key contains our asset path.
      final String key = utf8.decode(list, allowMalformed: true);
      
      if (key.contains('prophets_stories.json')) {
        final data = [
          {
            "id": 1,
            "name": "آدم عليه السلام",
            "summary": "قصة آدم",
            "chapters": [
              {
                "id": 101,
                "title": "خلق آدم",
                "content": "خلق الله آدم من تراب",
                "verses": [
                  {
                    "text": "إني جاعل في الأرض خليفة",
                    "surah": "البقرة",
                    "number": 30
                  }
                ],
                "source": "قصص الأنبياء ص 15"
              }
            ]
          }
        ];
        final bytes = utf8.encode(json.encode(data));
        return ByteData.sublistView(Uint8List.fromList(bytes));
      } else if (key.contains('prophet_seerah.json')) {
        final data = [
          {
            "id": 1,
            "stage": "مرحلة مكة",
            "title": "المولد الشريف ونشأته ﷺ",
            "content": "ولد النبي محمد ﷺ في مكة",
            "source": "سيرة ابن هشام ص 156"
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

  group('Prophets Stories Service Tests', () {
    test('Load, get, search and parse stories', () async {
      final service = ProphetsStoriesService();
      await service.loadStories();

      final stories = service.getAllStories();
      expect(stories.length, 1);
      expect(stories[0].name, 'آدم عليه السلام');
      expect(stories[0].chapters.length, 1);
      expect(stories[0].chapters[0].verses.length, 1);
      expect(stories[0].chapters[0].verses[0].surah, 'البقرة');

      final story = service.getStoryById(1);
      expect(story, isNotNull);
      expect(story!.name, 'آدم عليه السلام');

      final searchResults = service.searchStories('تراب');
      expect(searchResults.length, 1);

      final noResults = service.searchStories('غير موجود');
      expect(noResults.length, 0);
    });
  });

  group('Seerah Service Tests', () {
    test('Load, get, search and daily event', () async {
      final service = SeerahService();
      await service.loadEvents();

      final events = service.getAllEvents();
      expect(events.length, 1);
      expect(events[0].title, 'المولد الشريف ونشأته ﷺ');
      expect(events[0].stage, 'مرحلة مكة');

      final event = service.getEventById(1);
      expect(event, isNotNull);
      expect(event!.title, 'المولد الشريف ونشأته ﷺ');

      final searchResults = service.searchEvents('ولد');
      expect(searchResults.length, 1);

      final daily = await service.getEventOfDay();
      expect(daily, isNotNull);
      expect(daily!.title, 'المولد الشريف ونشأته ﷺ');
    });
  });
}
