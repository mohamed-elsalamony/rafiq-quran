import 'dart:io';
import 'dart:convert';

void main() async {
  final file = File(r"c:\Users\us mohamed\Desktop\مصحف\scratch\aldaa_full_text.txt");
  final lines = await file.openRead().transform(utf8.decoder).transform(const LineSplitter()).toList();
  
  // Print lines around 17830 to 17860
  print("--- Lines 17830 to 17860 ---");
  for (var i = 17829; i < 17860 && i < lines.length; i++) {
    print("${i+1}: '${lines[i]}'");
  }
}
