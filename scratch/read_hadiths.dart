import 'dart:convert';
import 'dart:io';

void main() {
  final file = File(r'c:\Users\us mohamed\Desktop\مصحف\assets\data\hadith.json');
  final content = file.readAsStringSync();
  final List<dynamic> data = json.decode(content);
  for (var h in data) {
    print('ID: ${h['id']} | Category: ${h['category']} | Text: ${h['text'].toString().substring(0, 40)}...');
  }
}
