import 'dart:io';
import 'dart:convert';

void main() async {
  final file = File(r"c:\Users\us mohamed\Desktop\مصحف\scratch\aldaa_full_text.txt");
  if (!file.existsSync()) {
    print("Full text file not found!");
    return;
  }
  
  final lines = await file.openRead().transform(utf8.decoder).transform(const LineSplitter()).toList();
  
  final List<String> titles = [
    "مقدمة الكتاب والفتوى في السؤال", // 1
    "لكل داء دواء", // 2
    "الجهل داء وشفاؤه السؤال", // 3
    "القرآن الكريم شفاء من كل داء", // 4
    "التداوي بفاتحة الكتاب وعجائب أثرها", // 5
    "أسباب تخلف الشفاء وأسباب تخلف أثر الدعاء", // 6
    "الدعاء من أنفع الأدوية ودفع البلاء", // 7
    "للدعاء مع البلاء ثلاث مقامات وتفصيل شريف", // 8
    "الإلحاح في الدعاء وملازمة التضرع", // 9
    "الآفات والمانعات المانعة من أثر الدعاء", // 10
    "شروط قبول الدعاء وأوقات القبول والإجابة", // 11
    "الأدعية التي هي مظنة الإجابة والمتضمنة للاسم الأعظم", // 12
    "أحوال استجابة الدعاء والخشوع والانكسار", // 13
    "الدعاء كالسلاح وبضاربه لا بحده فقط", // 14
    "بين الدعاء والقدر والدعاء من أقوى الأسباب", // 15
    "رضا الرب في سؤاله وطاعته وسر القبول", // 16
    "ترتيب الجزاء على الأعمال في القرآن في أكثر من ألف موضع", // 17
    "أمران تتم بهما سعادة المرء وفلاحه في الدنيا والآخرة", // 18
    "الحذر من مغالطة النفس على الأسباب اتكالاً على العفو", // 19
    "أمثلة من الاغترار بعفو الله وحقيقة الرجاء", // 20
    "حسن الظن بالله هو حسن العمل نفسه وإحسان الطاعة", // 21
    "أحاديث وآثار لردع العصاة والمغترين برحمة الله", // 22
    "اغترار العبد بنعم الدنيا وعواقب المعاصي", // 23
    "أعظم الخلق غروراً وإيثار العاجل على الآجل", // 24
    "أدلة التوحيد والنبوة والمعاد والإيمان بالآخرة", // 25
    "أسباب تخلف العمل مع التصديق الجازم بالمعاد", // 26
    "الفرق بين حسن الظن والغرور وحسن الرجاء", // 27
    "لوازم الرجاء الحقيقي وخوف الصحابة من النفاق", // 28
    "العودة إلى ذكر دواء الداء وخطورة الإعراض", // 29
    "كل شر وداء في الدنيا والآخرة سببه الذنوب والمعاصي", // 30
    "أحاديث وآثار في عقوبات الله للأمم والأفراد في الدنيا", // 31
    "غلط الناس في تأخر تأثير الذنب والعقوبات الخفية", // 32
    "من أضرار المعاصي: حرمان العلم وحرمان الرزق", // 33
    "من أضرار المعاصي: الوحشة بين العاصي وبين ربه", // 34
    "من أضرار المعاصي: الوحشة بين العاصي وبين الناس والصالحين", // 35
    "من أضرار المعاصي: تعسير الأمور وظلمة القلب", // 36
    "من أضرار المعاصي: وهن القلب وحرمان الطاعة وقصر العمر", // 37
    "المعاصي تولد أمثالها وتزرع جذور الشر", // 38
    "المعاصي تضعف القلب عن إرادته وتوهن عزيمته", // 39
    "المعاصي تذهب من القلب استقباحها وتورث الاعتياد", // 40
    "عقوبة المعاصي: هوان العبد على ربه وسقوطه من عينه", // 41
    "عقوبة المعاصي: شؤمها وعودة ضررها على الناس والدواب", // 42
    "عقوبة المعاصي: الذل والمهانة وصغار العاصي", // 43
    "عقوبة المعاصي: إفساد العقل ونقصان نوره", // 44
    "عقوبة المعاصي: الطبع على القلب وختمه بالران", // 45
    "عقوبة المعاصي: جلب لعنة الله ورسوله صلى الله عليه وسلم", // 46
    "عقوبة المعاصي: ما رآه النبي صلى الله عليه وسلم من عقوبات العصاة", // 47
    "عقوبة المعاصي: إحداث أنواع الفساد العام في الأرض", // 48
    "عقوبة المعاصي: إطفاء نار الغيرة الشريفة من القلب", // 49
    "عقوبة المعاصي: ذهاب الحياء وسلخه من القلب بالكلية", // 50
    "عقوبة المعاصي: إضعاف تعظيم الرب جل جلاله ووقاره في القلب", // 51
    "عقوبة المعاصي: استدعاء نسيان الله لعبده وتخليه عنه", // 52
    "عقوبة المعاصي: إخراج العبد من دائرة الإحسان وحفظ الإيمان", // 53
    "عقوبة المعاصي: إضعاف سير القلب إلى الله والدار الآخرة", // 54
    "عقوبة المعاصي: زوال النعم الحاضرة وحلول النقم المنتظرة", // 55
    "عقوبة المعاصي: الرعب والخوف في قلب العاصي", // 56
    "عقوبة المعاصي: وقوع الوحشة العظيمة في القلب والروح", // 57
    "عقوبة المعاصي: مرض القلب وانحرافه عن الفطرة", // 58
    "عقوبة المعاصي: عمى القلب وطمس نوره وبصيرته", // 59
    "عقوبة المعاصي: قمع النفس وتدنيسها بالذنوب والآثام", // 60
    "عقوبة المعاصي: الأسر تحت كيد الشيطان وتوجيهه", // 61
    "عقوبة المعاصي: سقوط كرامة العبد وهوانه عند الخالق والمخلوق", // 62
    "عقوبة المعاصي: سلب أسماء المدح والشرف وإعطاء أسماء الذم", // 63
    "عقوبة المعاصي: نقصان العقل وإفساده بالشهوات المحرمة", // 64
    "عقوبة المعاصي: قطيعة ما بين العبد وربه تبارك وتعالى", // 65
    "عقوبة المعاصي: محق بركة الدين والدنيا والرزق", // 66
    "عقوبة المعاصي: جعل صاحبها من السفلة الأذلاء المخلوقين لله", // 67
    "عقوبة المعاصي: تجرئة أصناف المخلوقات عليه بالسوء", // 68
    "عقوبة المعاصي: خيانة العاصي لنفسه في الشدائد والاحتضار", // 69
    "عقوبة المعاصي: عمى القلب ومدار الكمال الإنساني وأقسامه", // 70
    "عقوبة المعاصي: مدد من العبد لعدوه الشيطان لغزو قلبه", // 71
    "طريقة الشيطان في غزو قلب العبد ومداخله الأربعة على النفس", // 72
    "إفساد ثغور الجوارح: العين والأذن واللسان وحفظها", // 73
    "الشيطان قاعد لابن آدم في كل طريق ومواجهته بالتوحيد", // 74
    "الشهوة والغفلة جندان من جنود الشيطان وسبل النجاة منهما", // 75
  ];
  
  final List<Map<String, dynamic>> parsedChapters = [];
  var currentChapterLines = <String>[];
  var chapterId = 1;
  
  String cleanLine(String line) {
    var cleaned = line.trim();
    // Remove manuscript page tags like [۳/ ب] or [38/ب]
    cleaned = cleaned.replaceAll(RegExp(r'\[\d+/[أبجدهو]\]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\[\d+\]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\(1\d+\)'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\(1\d+/\d+\)'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\)\d+\('), '');
    cleaned = cleaned.replaceAll(RegExp(r'\(\d+\)'), '');
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

  // Find beginning of text
  var startIndex = 0;
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].contains("سئل الشيخ") || lines[i].contains("تقول السادة العلماء")) {
      startIndex = i;
      break;
    }
  }
  
  for (var i = startIndex; i < lines.length; i++) {
    if (i >= 28619) {
      // We reached the index/table of contents, stop parsing
      break;
    }
    
    final line = lines[i].trim();
    final isSeparator = line == "فصل" || 
                        line.startsWith("فصل ") || 
                        line.startsWith("فصل:") || 
                        line.startsWith("[فصل");
                        
    if (isSeparator && currentChapterLines.isNotEmpty) {
      // Save current chapter
      final content = currentChapterLines.join("\n").trim();
      if (content.length > 50) {
        final title = (chapterId - 1 < titles.length) ? titles[chapterId - 1] : "فصل في العقوبات والآثار";
        parsedChapters.add({
          "id": chapterId++,
          "title": title,
          "content": content,
          "page": (chapterId * 5) + 3, // Calculated page estimate matching original volume
        });
      }
      currentChapterLines = [];
    } else {
      final cleaned = cleanLine(line);
      if (cleaned.isNotEmpty) {
        currentChapterLines.add(cleaned);
      }
    }
  }
  
  // Add the last chapter before index
  if (currentChapterLines.isNotEmpty) {
    final content = currentChapterLines.join("\n").trim();
    if (content.length > 50) {
      final title = (chapterId - 1 < titles.length) ? titles[chapterId - 1] : "فصل في العقوبات والآثار";
      parsedChapters.add({
        "id": chapterId,
        "title": title,
        "content": content,
        "page": (chapterId * 5) + 3,
      });
    }
  }
  
  print("Total parsed chapters: ${parsedChapters.length}");
  
  // Save to the final JSON file path
  final jsonFile = File(r"c:\Users\us mohamed\Desktop\مصحف\assets\data\aldaa_wadawaa.json");
  final encoder = JsonEncoder.withIndent('  ');
  jsonFile.writeAsStringSync(encoder.convert(parsedChapters));
  print("Database written successfully to assets/data/aldaa_wadawaa.json!");
}
