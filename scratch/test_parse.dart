import 'dart:io';
import 'dart:convert';

void main() async {
  final file = File(r"c:\Users\us mohamed\Desktop\مصحف\scratch\aldaa_full_text.txt");
  if (!file.existsSync()) {
    print("File not found!");
    return;
  }
  
  final lines = await file.openRead().transform(utf8.decoder).transform(const LineSplitter()).toList();
  
  final List<Map<String, dynamic>> parsedChapters = [];
  var currentChapterLines = <String>[];
  String? currentTitle;
  var chapterId = 1;
  
  // A helper to clean a line from common OCR noise
  String cleanLine(String line) {
    var cleaned = line.trim();
    // Remove manuscript page tags like [۳/ ب] or [38/ب]
    cleaned = cleaned.replaceAll(RegExp(r'\[\d+/[أبجدهو]\]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\[\d+\]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\(1\d+\)'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\(1\d+/\d+\)'), '');
    // Remove isolated numbers on a line (usually page numbers)
    if (RegExp(r'^\d+$').hasMatch(cleaned)) {
      return '';
    }
    // Remove common publisher stamps or headers
    if (cleaned.contains("الجواب الكافي") && cleaned.length < 30) {
      return '';
    }
    return cleaned.trim();
  }

  // First, find the beginning of the actual text
  var startIndex = 0;
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].contains("سئل الشيخ") || lines[i].contains("تقول السادة العلماء")) {
      startIndex = i;
      break;
    }
  }
  
  print("Book starts at line ${startIndex + 1}");
  
  // Set initial title for Chapter 1
  currentTitle = "مقدمة الكتاب والفتوى في السؤال";
  
  for (var i = startIndex; i < lines.length; i++) {
    final line = lines[i].trim();
    
    // Check if this line is a chapter separator
    final isSeparator = line == "فصل" || 
                        line.startsWith("فصل ") || 
                        line.startsWith("فصل:") || 
                        line.startsWith("[فصل");
                        
    if (isSeparator && currentChapterLines.isNotEmpty) {
      // Save current chapter
      final content = currentChapterLines.join("\n").trim();
      if (content.length > 50) {
        parsedChapters.add({
          "id": chapterId++,
          "title": currentTitle ?? "فصل",
          "content": content,
          "page": (chapterId * 3) + 2, // Estimated page number based on order
        });
      }
      
      // Reset for next chapter
      currentChapterLines = [];
      
      // Determine the title of the next chapter from the next few non-empty lines
      currentTitle = null;
      var nextIndex = i + 1;
      while (nextIndex < lines.length) {
        final nextLineClean = cleanLine(lines[nextIndex]);
        if (nextLineClean.isNotEmpty) {
          // Use the first line of text as title helper
          var titleText = nextLineClean;
          // Trim if too long
          if (titleText.length > 60) {
            titleText = titleText.substring(0, 60) + "...";
          }
          currentTitle = titleText;
          break;
        }
        nextIndex++;
      }
      if (currentTitle == null || currentTitle!.isEmpty) {
        currentTitle = "فصل في العقوبات والآثار";
      }
    } else {
      final cleaned = cleanLine(line);
      if (cleaned.isNotEmpty) {
        currentChapterLines.add(cleaned);
      }
    }
  }
  
  // Add the last chapter
  if (currentChapterLines.isNotEmpty) {
    final content = currentChapterLines.join("\n").trim();
    if (content.length > 50) {
      parsedChapters.add({
        "id": chapterId,
        "title": currentTitle ?? "خاتمة الكتاب",
        "content": content,
        "page": (chapterId * 3) + 2,
      });
    }
  }
  
  print("Parsed ${parsedChapters.length} chapters.");
  print("\n--- Titles of first 20 chapters ---");
  for (var i = 0; i < parsedChapters.length && i < 20; i++) {
    print("Chapter ${parsedChapters[i]['id']}: ${parsedChapters[i]['title']} (${parsedChapters[i]['content'].length} chars)");
  }
  
  print("\n--- Titles of last 10 chapters ---");
  for (var i = parsedChapters.length - 10; i < parsedChapters.length; i++) {
    if (i >= 0) {
      print("Chapter ${parsedChapters[i]['id']}: ${parsedChapters[i]['title']} (${parsedChapters[i]['content'].length} chars)");
    }
  }
}
