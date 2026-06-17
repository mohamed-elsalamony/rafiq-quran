import 'dart:convert';
import 'dart:io';

void main() {
  final file = File(r'c:\Users\us mohamed\Desktop\مصحف\assets\data\companions.json');
  if (!file.existsSync()) {
    print('File not found!');
    return;
  }
  
  final content = file.readAsStringSync();
  final List<dynamic> data = json.decode(content);

  final categoryCounts = <String, int>{};
  int nullCategoriesCount = 0;
  
  for (var c in data) {
    final categories = c['categories'] as List<dynamic>?;
    if (categories == null) {
      nullCategoriesCount++;
    } else {
      for (var cat in categories) {
        final catStr = cat.toString();
        categoryCounts[catStr] = (categoryCounts[catStr] ?? 0) + 1;
      }
    }
  }

  print('Total companions: ${data.length}');
  print('Companions with null/empty categories: $nullCategoriesCount');
  print('Category counts:');
  categoryCounts.forEach((key, value) {
    print('  - $key: $value companions');
  });
}
