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

  print('--- Companions with null or empty categories ---');
  for (var c in data) {
    final name = c['name'];
    final id = c['id'];
    final categories = c['categories'] as List<dynamic>?;
    if (categories == null || categories.isEmpty) {
      print('ID: $id, Name: $name');
    }
  }

  print('\n--- Companions with short biographies (less than 150 chars in any field) ---');
  for (var c in data) {
    final name = c['name'];
    final id = c['id'];
    final lineage = c['lineage']?.toString() ?? '';
    final islam = c['islam']?.toString() ?? '';
    final moments = c['moments']?.toString() ?? '';
    final virtues = c['virtues']?.toString() ?? '';
    
    if (lineage.length < 150 || islam.length < 150 || moments.length < 150 || virtues.length < 150) {
      print('ID: $id, Name: $name (lineage: ${lineage.length}, islam: ${islam.length}, moments: ${moments.length}, virtues: ${virtues.length})');
    }
  }
}
