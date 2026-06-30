import 'dart:io';
import 'dart:convert';

void main() async {
  final file = File(r"c:\Users\us mohamed\Desktop\مصحف\scratch\aldaa_full_text.txt");
  if (!file.existsSync()) {
    print("File not found!");
    return;
  }
  
  final lines = await file.openRead().transform(utf8.decoder).transform(const LineSplitter()).toList();
  
  var fasslCount = 0;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line == "فصل" || line.startsWith("فصل ") || line.startsWith("فصل:") || line.startsWith("[فصل")) {
      fasslCount++;
      print("--- Occurrence $fasslCount at Line ${i+1} ---");
      print("Header: $line");
      for (var j = 1; j <= 3; j++) {
        if (i + j < lines.length) {
          print("Line ${i+1+j}: ${lines[i+j].trim()}");
        }
      }
      print("");
      if (fasslCount >= 60) break; // limit output size
    }
  }
}
