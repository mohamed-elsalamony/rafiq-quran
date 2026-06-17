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
  print('Total companions: ${data.length}');
  for (var c in data) {
    print('ID: ${c['id']}, Name: ${c['name']}');
  }
}
