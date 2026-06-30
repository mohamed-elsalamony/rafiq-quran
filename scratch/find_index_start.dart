import 'dart:io';
import 'dart:convert';

void main() async {
  final file = File(r"c:\Users\us mohamed\Desktop\مصحف\scratch\aldaa_full_text.txt");
  final lines = await file.openRead().transform(utf8.decoder).transform(const LineSplitter()).toList();
  
  print("--- Lines 28500 to 28800 ---");
  for (var i = 28500; i < 28800 && i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isNotEmpty) {
      print("${i+1}: '$line'");
    }
  }
}
