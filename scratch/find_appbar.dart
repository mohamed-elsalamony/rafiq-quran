import 'dart:io';

void main() {
  final file = File(r"c:\Users\us mohamed\Desktop\مصحف\lib\features\quran\presentation\quran_screen.dart");
  if (!file.existsSync()) {
    print("File not found!");
    return;
  }
  
  final lines = file.readAsLinesSync();
  print("Total lines: ${lines.length}");
  
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.contains("AppBar") || line.contains("Navigator") || line.contains("leading:") || line.contains("WillPopScope") || line.contains("PopScope")) {
      print("Line ${i+1}: ${line.trim()}");
    }
  }
}
