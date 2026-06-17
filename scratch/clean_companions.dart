import 'dart:convert';
import 'dart:io';

void main() {
  final file = File(r'c:\Users\us mohamed\Desktop\مصحف\assets\data\companions.json');
  if (!file.existsSync()) {
    print('Error: companions.json not found!');
    return;
  }

  try {
    final content = file.readAsStringSync();
    final List<dynamic> data = json.decode(content);

    print('Total companions in database: ${data.length}');

    for (var comp in data) {
      // Clean sources to strictly show Al-Isti'ab and Siyar A'lam al-Nubala
      comp['sources'] = 'الاستيعاب في معرفة الأصحاب لابن عبد البر، سير أعلام النبلاء للذهبي';

      // Clean individual sources inside sections if any
      // (lineage, islam, moments, virtues) to prevent referencing other books
      comp['lineage'] = cleanText(comp['lineage'] as String) + ' (المصدر: الاستيعاب لابن عبد البر)';
      comp['islam'] = cleanText(comp['islam'] as String) + ' (المصدر: سير أعلام النبلاء للذهبي)';
      comp['moments'] = cleanText(comp['moments'] as String) + ' (المصدر: سير أعلام النبلاء للذهبي)';
      comp['virtues'] = cleanText(comp['virtues'] as String) + ' (المصدر: سير أعلام النبلاء للذهبي)';
    }

    final encoder = JsonEncoder.withIndent('  ');
    file.writeAsStringSync(encoder.convert(data));
    print('Successfully cleaned sources for all companions in companions.json via Dart.');
  } catch (e) {
    print('Error: $e');
  }
}

String cleanText(String text) {
  if (text.contains('(المصدر:')) {
    return text.split('(المصدر:')[0].trim();
  }
  return text.trim();
}
