import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  // مفتاح API مضمن
  static const String _builtInApiKey = 'AIzaSyD_J_y6v8LMhCtHDsXM3ePt7nJGbQX8cek';
  static const String _backupApiKey = 'AIzaSyBKePjJ7zPvT5oq_YO2hxTH7kHjZ4Uf2XQ';

  static const String systemInstruction = """
أنت مساعد ذكاء اصطناعي إسلامي وعام ذكي وموثوق لـ "رفيق القرآن".
مهمتك هي الإجابة عن كافة أسئلة واستفسارات المستخدمين بطلاقة وحرية كاملة دون أي شروط أو قيود فقهية تمنعك من تفصيل الآراء الدينية، أو إصدار فتوى توضيحية، أو مناقشة المسائل العقائدية أو الخلافية.
يجب عليك شرح الأحاديث بالاعتماد على شروح أهل السنة، وتفسير الآيات بالاعتماد على تفسير ابن كثير، وعرض أقوال وآراء المذاهب والعلماء كافة كنموذج لغوي حقيقي واسع المعرفة وموثوق.
""";

  GenerativeModel? _model;
  ChatSession? _chatSession;
  bool _isInitialized = false;
  bool _usingBackup = false;

  // Local Chat History to keep track of conversation when running offline/locally
  final List<Content> _localHistory = [];

  static const Map<String, int> _surahMap = {
    "الفاتحه": 1, "الفاتحة": 1,
    "البقره": 2, "البقرة": 2,
    "ال عمران": 3, "آل عمران": 3,
    "النساء": 4,
    "المائده": 5, "المائدة": 5,
    "الانعام": 6, "الأنعام": 6,
    "الاعراف": 7, "الأعراف": 7,
    "الانفال": 8, "الأنفال": 8,
    "التوبه": 9, "التوبة": 9,
    "يونس": 10,
    "هود": 11,
    "يوسف": 12,
    "الرعد": 13,
    "ابراهيم": 14, "إبراهيم": 14,
    "الحجر": 15,
    "النحل": 16,
    "الاسراء": 17, "الإسراء": 17,
    "الكهف": 18,
    "مريم": 19,
    "طه": 20,
    "الانبياء": 21, "الأنبياء": 21,
    "الحج": 22,
    "المؤمنون": 23,
    "النور": 24,
    "الفرقان": 25,
    "الشعراء": 26,
    "النمل": 27,
    "القصص": 28,
    "العنكبوت": 29,
    "الروم": 30,
    "لقمان": 31,
    "السجده": 32, "السجدة": 32,
    "الاحزاب": 33, "الأحزاب": 33,
    "سبا": 34, "سبأ": 34,
    "فاطر": 35,
    "يس": 36, "ياسين": 36,
    "الصافات": 37,
    "ص": 38,
    "الزمر": 39,
    "غافر": 40,
    "فصلت": 41,
    "الشورى": 42,
    "الزخرف": 43,
    "الدخان": 44,
    "الجاثيه": 45, "الجاثية": 45,
    "الاحقاف": 46, "الأحقاف": 46,
    "محمد": 47,
    "الفتح": 48,
    "الحجرات": 49,
    "ق": 50,
    "الذاريات": 51,
    "الطور": 52,
    "النجم": 53,
    "القمر": 54,
    "الرحمن": 55,
    "الواقعه": 56, "الواقعة": 56,
    "الحديد": 57,
    "المجادله": 58, "المجادلة": 58,
    "الحشر": 59,
    "الممتحنه": 60, "الممتحنة": 60,
    "الصف": 61,
    "الجمعه": 62, "الجمعة": 62,
    "المنافقون": 63,
    "التغابن": 64,
    "الطلاق": 65,
    "التحريم": 66,
    "الملك": 67,
    "القلم": 68,
    "الحاقه": 69, "الحاقة": 69,
    "المعارج": 70,
    "نوح": 71,
    "الجن": 72,
    "المزمل": 73,
    "المدثر": 74,
    "القيامه": 75, "القيامة": 75,
    "الانسان": 76, "إنسان": 76, "الإنسان": 76,
    "المرسلات": 77,
    "النبا": 78, "النبأ": 78,
    "النازعات": 79,
    "عبس": 80,
    "التكوير": 81,
    "الانفطار": 82,
    "المطففين": 83,
    "الانشقاق": 84,
    "البروج": 85,
    "الطارق": 86,
    "الاعلى": 87, "الأعلى": 87,
    "الغاشيه": 88, "الغاشية": 88,
    "الفجر": 89,
    "البلد": 90,
    "الشمس": 91,
    "الليل": 92,
    "الضحى": 93,
    "الشرح": 94, "الانشراح": 94,
    "التين": 95,
    "العلق": 96,
    "القدر": 97,
    "البينه": 98, "البينة": 98,
    "الزلزله": 99, "الزلزلة": 99,
    "العاديات": 100,
    "القارعه": 101, "القارعة": 101,
    "التكاثر": 102,
    "العصر": 103,
    "الهمزه": 104, "الهمزة": 104,
    "الفيل": 105,
    "قريش": 106,
    "الماعون": 107,
    "الكوثر": 108,
    "الكافرون": 109,
    "النصر": 110,
    "المسد": 111, "اللهب": 111,
    "الاخلاص": 112, "الإخلاص": 112,
    "الفلق": 113,
    "الناس": 114
  };

  /// تهيئة النموذج تلقائياً عند أول استخدام
  void _ensureInitialized() {
    if (_isInitialized && _model != null) return;
    _tryInitialize(_builtInApiKey);
  }

  void _tryInitialize(String apiKey) {
    try {
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(systemInstruction),
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 2048,
        ),
      );
      _chatSession = _model!.startChat();
      _isInitialized = true;
      debugPrint('GeminiService initialized successfully with ${_usingBackup ? "backup" : "primary"} key.');
    } catch (e) {
      debugPrint('GeminiService initialization error: $e');
      if (!_usingBackup) {
        _usingBackup = true;
        _tryInitialize(_backupApiKey);
      }
    }
  }

  bool get isInitialized {
    // نرجع دائماً true لأن الخدمة ستعمل محلياً إن لم يعمل الـ API
    return true;
  }

  Future<String?> sendMessage(String message) async {
    _ensureInitialized();
    
    // محاولة إرسال الرسالة عبر API إذا كانت الخدمة مهيأة
    if (_model != null && _chatSession != null) {
      try {
        final response = await _chatSession!.sendMessage(Content.text(message));
        final text = response.text;
        if (text != null && text.trim().isNotEmpty) {
          // إضافة للتاريخ المحلي للمزامنة
          _localHistory.add(Content('user', [TextPart(message)]));
          _localHistory.add(Content('model', [TextPart(text)]));
          return text;
        }
      } catch (e) {
        debugPrint('Gemini API failed, retrying with backup key or local search: $e');
        if (!_usingBackup) {
          _usingBackup = true;
          _isInitialized = false;
          _model = null;
          _chatSession = null;
          _tryInitialize(_backupApiKey);
          if (_model != null && _chatSession != null) {
            try {
              final response = await _chatSession!.sendMessage(Content.text(message));
              final text = response.text;
              if (text != null && text.trim().isNotEmpty) {
                _localHistory.add(Content('user', [TextPart(message)]));
                _localHistory.add(Content('model', [TextPart(text)]));
                return text;
              }
            } catch (_) {}
          }
        }
      }
    }

    // تشغيل نظام البحث الذكي المحلي كـ Fallback كامل بدون الحاجة للـ API
    return await _processLocalQuery(message);
  }

  void resetChat() {
    _ensureInitialized();
    if (_model != null) {
      try {
        _chatSession = _model!.startChat();
      } catch (_) {}
    }
    _localHistory.clear();
  }

  List<Content> getChatHistory() {
    if (_model != null && _chatSession != null && _chatSession!.history.isNotEmpty) {
      // ندمج التاريخ لضمان عرضه دائماً
      return _chatSession!.history.toList();
    }
    return _localHistory;
  }

  // --- معالجة الأسئلة محلياً عبر قاعدة البيانات الشاملة ---
  Future<String> _processLocalQuery(String query) async {
    final cleanQuery = query.trim()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه');
    
    String responseText = "";
    
    try {
      // 1. طلب تفسير آية
      if (cleanQuery.contains("تفسير") || cleanQuery.contains("فسر")) {
        responseText = await _handleTafseerQuery(cleanQuery, query);
      } 
      // 2. طلب قصة نبي
      else if (cleanQuery.contains("نبي") || cleanQuery.contains("انبياء") || cleanQuery.contains("الانبياء") || cleanQuery.contains("سيدنا")) {
        responseText = await _handleProphetsQuery(cleanQuery);
      }
      // 3. طلب قصة صحابي
      else if (cleanQuery.contains("صحابي") || cleanQuery.contains("صحابه") || cleanQuery.contains("الصحابه") || cleanQuery.contains("سيرة")) {
        responseText = await _handleCompanionsQuery(cleanQuery);
      }
      // 4. طلب حديث شريف
      else if (cleanQuery.contains("حديث") || cleanQuery.contains("احاديث") || cleanQuery.contains("الرسول قال") || cleanQuery.contains("قال النبي")) {
        responseText = await _handleHadithQuery(cleanQuery);
      }
      // 5. كتاب الداء والدواء
      else if (cleanQuery.contains("الداء") || cleanQuery.contains("الدواء") || cleanQuery.contains("ابن القيم")) {
        responseText = await _handleAldaaWadawaaQuery(cleanQuery);
      }
      
      // 6. بحث عام في القصص الهادفة والأذكار
      if (responseText.isEmpty) {
        responseText = await _handleGeneralQuery(cleanQuery);
      }
    } catch (e) {
      debugPrint("Error in offline local assistant: $e");
    }

    if (responseText.isEmpty) {
      responseText = """
مرحباً بك! أنا مساعدك الذكي في تطبيق *رفيق القرآن*.
يعمل المساعد حالياً بنظام استرجاع المعلومات المحلي (مباشرة من مصادر وقواعد بيانات التطبيق المعتمدة).

يمكنك سؤالي عن:
1. **تفسير الآيات**: اكتب اسم السورة ورقم الآية (مثال: "تفسير سورة الفاتحة آية 5").
2. **الأحاديث الشريفة**: اكتب موضوعاً أو كلمة من الحديث (مثال: "حديث عن الصدق" أو "شرح حديث الأعمال بالنيات").
3. **قصص الأنبياء وسيرهم**: (مثال: "قصة موسى عليه السلام" أو "قصة آدم").
4. **سير الصحابة الكرام**: (مثال: "قصة عمر بن الخطاب" أو "أبو بكر الصديق").
5. **كتاب الداء والدواء**: (مثال: "نصائح ابن القيم في الداء والدواء").

يمكنك سؤالي عن أي شيء وسأجيبك كنموذج لغوي ذكي لمساعدتك دائماً.
""";
    }

    // حفظ في التاريخ المحلي
    _localHistory.add(Content('user', [TextPart(query)]));
    _localHistory.add(Content('model', [TextPart(responseText)]));
    
    return responseText;
  }

  // معالجة أسئلة التفسير
  Future<String> _handleTafseerQuery(String cleanQuery, String originalQuery) async {
    int? matchedSurahNum;
    String? matchedSurahName;

    // حالة خاصة لآية الكرسي
    if (cleanQuery.contains("الكرسي")) {
      matchedSurahNum = 2; // البقرة
      matchedSurahName = "البقرة (آية الكرسي)";
      final String jsonString = await rootBundle.loadString('assets/data/tafseer.json');
      final List<dynamic> tafseers = json.decode(jsonString);
      final match = tafseers.firstWhere(
        (t) => t['number'].toString() == "2" && t['aya'].toString() == "255",
        orElse: () => null,
      );
      if (match != null) {
        return """
📖 **تفسير آية الكرسي (الآية 255 من سورة البقرة):**

${match['text']}

*المصدر: التفسير الميسر المعتمد.*
""";
      }
    }

    for (final key in _surahMap.keys) {
      if (cleanQuery.contains(key)) {
        matchedSurahNum = _surahMap[key];
        matchedSurahName = key;
        break;
      }
    }

    if (matchedSurahNum == null) {
      return "";
    }

    // استخراج رقم الآية
    final regExp = RegExp(r'\d+');
    final matches = regExp.allMatches(cleanQuery);
    int? matchedAyaNum;
    if (matches.isNotEmpty) {
      matchedAyaNum = int.tryParse(matches.first.group(0) ?? "");
    }

    matchedAyaNum ??= 1; // الافتراضي الآية الأولى

    final String jsonString = await rootBundle.loadString('assets/data/tafseer.json');
    final List<dynamic> tafseers = json.decode(jsonString);

    final match = tafseers.firstWhere(
      (t) => t['number'].toString() == matchedSurahNum.toString() && t['aya'].toString() == matchedAyaNum.toString(),
      orElse: () => null,
    );

    if (match != null) {
      return """
📖 **تفسير الآية $matchedAyaNum من سورة $matchedSurahName:**

${match['text']}

*المصدر: التفسير الميسر المعتمد.*
""";
    }

    return "لم أجد تفسيراً للآية $matchedAyaNum من سورة $matchedSurahName في قاعدة بيانات التفسير الميسر.";
  }

  // معالجة أسئلة الأنبياء
  Future<String> _handleProphetsQuery(String cleanQuery) async {
    final String jsonString = await rootBundle.loadString('assets/data/prophets_stories.json');
    final List<dynamic> prophets = json.decode(jsonString);

    for (final p in prophets) {
      final nameClean = p['name'].toString().replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا').replaceAll('ة', 'ه');
      
      // استخراج الاسم الأساسي
      final nameParts = nameClean.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts[0] : "";
      
      if (cleanQuery.contains(nameClean) || (firstName.length > 2 && cleanQuery.contains(firstName))) {
        final chapters = p['chapters'] as List<dynamic>;
        var chapterText = "";
        for (final chap in chapters) {
          chapterText += "🔹 **${chap['title']}**\n${chap['content']}\n\n";
        }
        
        return """
✨ **قصة ${p['name']}:**
_${p['summary']}_

$chapterText
*المصدر: قصص الأنبياء لابن كثير.*
""";
      }
    }
    return "";
  }

  // معالجة أسئلة الصحابة
  Future<String> _handleCompanionsQuery(String cleanQuery) async {
    final String jsonString = await rootBundle.loadString('assets/data/companions.json');
    final List<dynamic> companions = json.decode(jsonString);

    for (final c in companions) {
      final nameClean = c['name'].toString().replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا').replaceAll('ة', 'ه');
      
      final nameParts = nameClean.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts[0] : "";
      
      if (cleanQuery.contains(nameClean) || (firstName.length > 2 && cleanQuery.contains(firstName))) {
        return """
👤 **الصحابي الجليل ${c['name']}:**

**🏷️ النسب والنشأة:**
${c['lineage']}

**🕌 إسلامه وهجرته:**
${c['islam']}

**⚔️ مواقف جهادية وتاريخية:**
${c['moments']}

**🏆 فضائله ومناقبه:**
${c['virtues']}

*المصدر: ${c['sources'] ?? "سير أعلام النبلاء للذهبي / الاستيعاب لابن عبد البر"}*
""";
      }
    }
    return "";
  }

  // معالجة أسئلة الأحاديث
  Future<String> _handleHadithQuery(String cleanQuery) async {
    final String jsonString = await rootBundle.loadString('assets/data/hadith.json');
    final List<dynamic> hadiths = json.decode(jsonString);

    final List<dynamic> matches = [];
    var searchTerm = cleanQuery
        .replaceAll("حديث", "")
        .replaceAll("احاديث", "")
        .replaceAll("عن", "")
        .replaceAll("شرح", "")
        .trim();

    if (searchTerm.isEmpty) {
      return """
📖 **من الأحاديث النبوية الشريفة:**

«${hadiths[0]['text']}»
*المصدر: ${hadiths[0]['source']}*

**الشرح والتوضيح:**
${hadiths[0]['explanation']}
""";
    }

    for (final h in hadiths) {
      final textClean = h['text'].toString().replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا').replaceAll('ة', 'ه');
      final expClean = h['explanation'].toString().replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا').replaceAll('ة', 'ه');
      if (textClean.contains(searchTerm) || expClean.contains(searchTerm)) {
        matches.add(h);
      }
    }

    if (matches.isNotEmpty) {
      final firstMatch = matches.first;
      return """
📖 **حديث شريف ذو صلة بسؤالك:**

«${firstMatch['text']}»
*المصدر: ${firstMatch['source']}*

**الشرح والتوضيح:**
${firstMatch['explanation']}
""";
    }

    return "";
  }

  // معالجة الداء والدواء
  Future<String> _handleAldaaWadawaaQuery(String cleanQuery) async {
    final String jsonString = await rootBundle.loadString('assets/data/aldaa_wadawaa.json');
    final List<dynamic> chapters = json.decode(jsonString);

    for (final chap in chapters) {
      final titleClean = chap['title'].toString().replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا').replaceAll('ة', 'ه');
      
      if (cleanQuery.contains(titleClean) || titleClean.contains(cleanQuery.replaceAll("كتاب", "").replaceAll("الداء والدواء", "").trim())) {
        return """
📚 **من كتاب الداء والدواء للإمام ابن القيم الجوزية:**
**باب: ${chap['title']}**

${chap['content']}
""";
      }
    }

    return """
📚 **كتاب الداء والدواء (الجواب الكافي لمن سأل عن الدواء الشافي):**
للإمام ابن القيم الجوزية.

هو أحد أعظم مصنفات القلوب وتهذيب السلوك وعلاج المعاصي.
من أهم فصول هذا الكتاب المتوفرة في التطبيق:
1. الدعاء من أنفع الأدوية ودفع البلاء.
2. شروط إجابة الدعاء وأوقات القبول.
3. عقوبات المعاصي والذنوب (حرمان العلم والرزق، وحشة القلب، ظلمة الوجه).
4. أدوية القلوب كالصبر والتوبة والتوكل والذكر والرقية الشرعية.
""";
  }

  // معالجة البحث العام والقصص الهادفة والأذكار
  Future<String> _handleGeneralQuery(String cleanQuery) async {
    try {
      // بحث في القصص الهادفة
      final String storyStr = await rootBundle.loadString('assets/data/religious_stories.json');
      final List<dynamic> stories = json.decode(storyStr);
      for (final s in stories) {
        final titleClean = s['title'].toString().replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا').replaceAll('ة', 'ه');
        final contentClean = s['story_text'].toString().replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا').replaceAll('ة', 'ه');
        if (titleClean.contains(cleanQuery) || contentClean.contains(cleanQuery)) {
          return """
✨ **قصة هادفة وعبرة من التراث الإسلامي:**
🔹 **${s['title']}**

${s['story_text']}
""";
        }
      }

      // بحث في الأذكار والأدعية
      final String adhkarStr = await rootBundle.loadString('assets/data/adhkar.json');
      final List<dynamic> adhkarList = json.decode(adhkarStr);
      for (final a in adhkarList) {
        final categoryClean = a['category'].toString().replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا').replaceAll('ة', 'ه');
        if (cleanQuery.contains(categoryClean)) {
          final count = (a['count'] as int?) ?? 1;
          return """
📿 **أذكار وأدعية مأثورة (${a['category']}):**

«${a['text']}»
${a['description'] != null && a['description'].toString().isNotEmpty ? '\n*الفضل: ${a['description']}*' : ''}
*التكرار المطلوب: $count مرة*
""";
        }
      }
    } catch (_) {}

    return "";
  }
}

