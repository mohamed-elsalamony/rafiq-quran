import 'dart:convert';
import 'dart:io';

void main() {
  final dataDir = Directory(r'c:\Users\us mohamed\Desktop\مصحف\assets\data');
  if (!dataDir.existsSync()) {
    print('Data directory not found!');
    return;
  }

  final files = [
    'religious_stories.json',
    'companions.json',
    'hadith.json',
    'prophet_seerah.json',
    'aldaa_wadawaa.json'
  ];

  for (var fileName in files) {
    final file = File('${dataDir.path}/$fileName');
    if (!file.existsSync()) {
      print('$fileName: NOT FOUND');
      continue;
    }
    final content = file.readAsStringSync();
    try {
      final List<dynamic> data = json.decode(content);
      print('$fileName: ${data.length} items');
      
      if (fileName == 'religious_stories.json') {
        final categories = <String, int>{};
        for (var item in data) {
          final cat = item['category'] as String;
          categories[cat] = (categories[cat] ?? 0) + 1;
        }
        print('  Categories: $categories');
      } else if (fileName == 'hadith.json') {
        final categories = <String, int>{};
        for (var item in data) {
          final cat = item['category'] as String;
          categories[cat] = (categories[cat] ?? 0) + 1;
        }
        print('  Categories: $categories');
      } else if (fileName == 'aldaa_wadawaa.json') {
        print('  Chapters: ${data.map((e) => '${e['id']}: ${e['title']}').join(', ')}');
      } else if (fileName == 'companions.json') {
        print('  First 5 companions: ${data.take(5).map((e) => e['name']).join(', ')}');
      } else if (fileName == 'prophet_seerah.json') {
        print('  Stages: ${data.map((e) => '${e['id']}: ${e['title']}').join(', ')}');
      }
    } catch (e) {
      print('$fileName: Error parsing: $e');
    }
  }
}
