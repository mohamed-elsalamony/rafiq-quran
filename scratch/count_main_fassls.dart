import 'dart:io';
import 'dart:convert';

void main() async {
  final file = File(r"c:\Users\us mohamed\Desktop\مصحف\scratch\aldaa_full_text.txt");
  final lines = await file.openRead().transform(utf8.decoder).transform(const LineSplitter()).toList();
  
  var mainFasslCount = 0;
  for (var i = 42; i < 28619 && i < lines.length; i++) {
    final line = lines[i].trim();
    final isSeparator = line == "فصل" || 
                        line.startsWith("فصل ") || 
                        line.startsWith("فصل:") || 
                        line.startsWith("[فصل");
    if (isSeparator) {
      mainFasslCount++;
      print("Fassl $mainFasslCount at Line ${i+1}: '$line'");
      // Print the next 2 lines of text
      var nextText = "";
      for (var j = 1; j <= 2; j++) {
        if (i + j < lines.length) {
          nextText += lines[i+j].trim() + " ";
        }
      }
      print("  Start text: ${nextText.trim()}");
    }
  }
  print("Total separators in main text: $mainFasslCount");
}
