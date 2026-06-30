import 'dart:io';
import 'dart:convert';

void main() async {
  final file = File(r"c:\Users\us mohamed\Desktop\مصحف\scratch\aldaa_full_text.txt");
  final lines = await file.openRead().transform(utf8.decoder).transform(const LineSplitter()).toList();
  
  print("Total lines: ${lines.length}");
  print("--- Lines 28800 to 28900 ---");
  for (var i = 28800; i < 28900 && i < lines.length; i++) {
    print("${i+1}: '${lines[i]}'");
  }
}
