import 'dart:convert';
import 'dart:io';

void main() {
  final file = File(r'c:\Users\us mohamed\Desktop\مصحف\assets\data\companions.json');
  if (!file.existsSync()) {
    print('File not found!');
    return;
  }
  
  try {
    final content = file.readAsStringSync();
    final List<dynamic> data = json.decode(content);
    
    bool found = false;
    for (var item in data) {
      if (item['id'] == 19) {
        print('Fixing ID 19 name: ${item['name']} -> خالد بن الوليد');
        item['name'] = 'خالد بن الوليد';
        found = true;
      }
    }
    
    if (found) {
      final encoder = JsonEncoder.withIndent('  ');
      file.writeAsStringSync(encoder.convert(data));
      print('companions.json updated successfully!');
    } else {
      print('ID 19 not found in JSON!');
    }
  } catch (e) {
    print('Error: $e');
  }
}
