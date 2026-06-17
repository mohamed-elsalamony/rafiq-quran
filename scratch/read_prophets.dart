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
    print('ID: ${p['id']}, Name: ${p['name']}');
  }
}
