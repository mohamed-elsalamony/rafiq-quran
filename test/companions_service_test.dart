import 'package:flutter_test/flutter_test.dart';
import 'package:rafiq_quran/core/services/companions_service.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:typed_data';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
      if (message == null) return null;
      final Uint8List list = message.buffer.asUint8List();
      final String key = utf8.decode(list, allowMalformed: true);
      
      if (key.contains('companions.json')) {
        final data = [
          {
            "id": 1,
            "name": "أبو بكر الصديق",
            "categories": [
              "العشرة المبشرون بالجنة",
              "أهل بدر",
              "السابقون الأولون"
            ],
            "lineage": "هو عبد الله بن عثمان بن عامر بن عمرو بن كعب بن تيم بن مرة القرشي التيمي",
            "islam": "أول من أسلم من الرجال الأحرار",
            "moments": "صاحب النبي ﷺ في الغار والهجرة المباركة",
            "virtues": "أفضل الأمة بعد نبيها، ولقبه الصديق",
            "hadiths": [
              "عن أبي بكر الصديق رضي الله عنه أنه قال للنبي ﷺ: علمني دعاء..."
            ],
            "sources": "الاستيعاب لابن عبد البر، سير أعلام النبلاء للذهبي، صحيح البخاري"
          },
          {
            "id": 101,
            "name": "خديجة بنت خويلد",
            "categories": [
              "الصحابيات"
            ],
            "lineage": "هي خديجة بنت خويلد بن أسد بن عبد العزى القرشية الأسدية",
            "islam": "أول من أسلم من الناس طراً، رجالاً ونساءً",
            "moments": "أوت النبي ﷺ ودعمته بمالها ونفسها وصدقته حين كذبه الناس",
            "virtues": "سيدة نساء العالمين وبشرها ببيت في الجنة من قصب",
            "hadiths": [],
            "sources": "الاستيعاب لابن عبد البر، سير أعلام النبلاء للذهبي"
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

  group('Companions Service Tests', () {
    test('Load, filter, search, and verify companion of the day', () async {
      final service = CompanionsService();
      // Test uninitialized / empty initially (assuming singletons might carry state, so we load)
      await service.loadCompanions();

      final all = service.getAllCompanions();
      expect(all.length, 2);
      expect(all[0].name, 'أبو بكر الصديق');
      expect(all[1].name, 'خديجة بنت خويلد');

      // Test get by ID
      final abubakr = service.getCompanionById(1);
      expect(abubakr, isNotNull);
      expect(abubakr!.name, 'أبو بكر الصديق');

      final khadija = service.getCompanionById(101);
      expect(khadija, isNotNull);
      expect(khadija!.name, 'خديجة بنت خويلد');

      // Test categories filtering
      final mubasharun = service.getCompanionsByCategory('العشرة المبشرون بالجنة');
      expect(mubasharun.length, 1);
      expect(mubasharun[0].name, 'أبو بكر الصديق');

      final femaleCompanions = service.getCompanionsByCategory('الصحابيات');
      expect(femaleCompanions.length, 1);
      expect(femaleCompanions[0].name, 'خديجة بنت خويلد');

      // Test searching
      final searchResult1 = service.searchCompanions('الصديق');
      expect(searchResult1.length, 1);
      expect(searchResult1[0].id, 1);

      final searchResult2 = service.searchCompanions('سيدة نساء');
      expect(searchResult2.length, 1);
      expect(searchResult2[0].id, 101);

      final searchResultEmpty = service.searchCompanions('غير موجود');
      expect(searchResultEmpty.length, 0);

      // Test search within category
      final searchInCat = service.searchCompanions('أول', category: 'الصحابيات');
      expect(searchInCat.length, 1);
      expect(searchInCat[0].id, 101);

      // Test companion of the day
      final companionOfDay = service.getCompanionOfDay();
      expect(companionOfDay, isNotNull);
      expect(all.contains(companionOfDay), isTrue);
    });
  });
}
