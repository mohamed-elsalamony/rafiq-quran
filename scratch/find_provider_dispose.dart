import 'dart:io';

void main() {
  final file = File(r"c:\Users\us mohamed\Desktop\مصحف\lib\features\quran\presentation\quran_provider.dart");
  if (!file.existsSync()) {
    print("File not found!");
    return;
  }
  
  final lines = file.readAsLinesSync();
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.contains("cancel") || line.contains("dispose") || line.contains("close")) {
      print("Line ${i+1}: ${line.trim()}");
    }
  }
}
