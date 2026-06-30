import 'dart:io';
import 'dart:convert';

void main() async {
  final file = File(r"c:\Users\us mohamed\Desktop\مصحف\scratch\aldaa_full_text.txt");
  final lines = await file.openRead().transform(utf8.decoder).transform(const LineSplitter()).toList();
  
  for (var i = 17836; i < 18730 && i < lines.length; i++) {
    final line = lines[i].trim();
    final isSeparator = line == "فصل" || 
                        line.startsWith("فصل ") || 
                        line.startsWith("فصل:") || 
                        line.startsWith("[فصل");
    if (isSeparator) {
      print("Line ${i+1}: '$line'");
    }
  }
}
