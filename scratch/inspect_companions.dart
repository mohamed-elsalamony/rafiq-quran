import 'dart:convert';
import 'dart:io';

void main() {
  final file = File(r'c:\Users\us mohamed\Desktop\مصحف\assets\data\companions.json');
  final content = file.readAsStringSync();
  final List<dynamic> data = json.decode(content);

  print('Total companions: ${data.length}');
  int incompleteCount = 0;
  for (var c in data) {
    final name = c['name'] as String;
    final lineage = (c['lineage'] ?? '') as String;
    final islam = (c['islam'] ?? '') as String;
    final moments = (c['moments'] ?? '') as String;
    final virtues = (c['virtues'] ?? '') as String;
    final hadiths = (c['hadiths'] ?? []) as List<dynamic>;

    final isShort = lineage.length < 50 || islam.length < 50 || moments.length < 50 || virtues.length < 50;
    if (isShort) {
      incompleteCount++;
      print('Companion ID ${c['id']} (${name}) is short/incomplete:');
      print('  lineage: ${lineage.length} chars');
      print('  islam: ${islam.length} chars');
      print('  moments: ${moments.length} chars');
      print('  virtues: ${virtues.length} chars');
      print('  hadiths: ${hadiths.length}');
    }
  }
  print('Incomplete/short companions count: $incompleteCount');
}
