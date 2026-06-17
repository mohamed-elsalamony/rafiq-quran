import 'dart:convert';
import 'dart:io';

void main() {
  final file = File(r'c:\Users\us mohamed\Desktop\مصحف\assets\data\prophets_stories.json');
  if (!file.existsSync()) {
    print('File not found!');
    return;
  }
  
  final content = file.readAsStringSync();
  final List<dynamic> data = json.decode(content);
  print('Total prophets: ${data.length}');
  for (var p in data) {
    final chapters = p['chapters'] as List<dynamic>;
    print('Prophet: ${p['name']} (${p['id']})');
    print('  Summary: ${p['summary']}');
    print('  Chapters count: ${chapters.length}');
    for (var c in chapters) {
      final textLen = (c['content'] as String).length;
      print('    - Title: "${c['title']}" (Length: $textLen chars)');
    }
  }
}
