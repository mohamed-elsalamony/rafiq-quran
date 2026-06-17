import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  // مفتاح API مضمن — يعمل تلقائياً دون الحاجة لإدخال المستخدم
  static const String _builtInApiKey = 'AIzaSyD_J_y6v8LMhCtHDsXM3ePt7nJGbQX8cek';

  static const String systemInstruction = """
أنت مساعد ذكاء اصطناعي إسلامي ذكي وموثوق داخل تطبيق "رفيق القرآن".

مهمتك الأساسية هي:
1. تفسير الآيات القرآنية الكريمة اعتماداً على التفسير المعتمد (مثل تفسير ابن كثير).
2. شرح الأحاديث النبوية الشريفة استناداً إلى شروح أهل السنة المعتمدة.
3. الإجابة على الأسئلة الدينية والعبادات والمعاملات اليومية البسيطة.
4. المساعدة في فهم محتويات التطبيق وكيفية استخدامها.

شروط هامة وضوابط صارمة يجب عليك الالتزام بها في كل رد:
- ابدأ دائماً أو اختم ردك بالتأكيد الواضح على أنك "مساعد ذكاء اصطناعي للإرشاد والتوضيح، ولست مرجعاً فقهياً أو فتوى شرعية معتمدة".
- انصح المستخدم دائماً بالرجوع إلى العلماء المعتمدين والمؤسسات الدينية الرسمية (مثل دار الإفتاء) في المسائل الكبيرة والشخصية والمهمة.
- لا تجيب أبداً على المسائل العقدية الخلافية أو المسائل الفقهية المعقدة أو الخلافات بين المذاهب. إذا سئلت عنها، اعتذر بلطف ووجه المستخدم لسؤال أهل العلم المتخصصين مستشهداً بآية: ﴿فَاسْأَلُوا أَهْلَ الذِّكْرِ إِن كُنتُمْ لَا تَعْلَمُونَ﴾.
- استند دائماً إلى مصادر إسلامية موثوقة وصحيحة، وتجنب القصص غير الموثقة أو الأحاديث الضعيفة والموضوعة.
- رد باللغة العربية الفصحى الواضحة والراقية وبأدب جم وتنسيق جميل يسهل قراءته.
""";

  GenerativeModel? _model;
  ChatSession? _chatSession;
  bool _isInitialized = false;

  /// تهيئة النموذج تلقائياً عند أول استخدام
  void _ensureInitialized() {
    if (_isInitialized && _model != null) return;
    try {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _builtInApiKey,
        systemInstruction: Content.system(systemInstruction),
      );
      _chatSession = _model!.startChat();
      _isInitialized = true;
      debugPrint('GeminiService initialized successfully.');
    } catch (e) {
      debugPrint('GeminiService initialization error: $e');
    }
  }

  bool get isInitialized {
    _ensureInitialized();
    return _isInitialized && _model != null;
  }

  Future<String?> sendMessage(String message) async {
    _ensureInitialized();
    if (_model == null || _chatSession == null) {
      throw Exception(
          "حدث خطأ في تهيئة المساعد الذكي. تأكد من اتصالك بالإنترنت وأعد المحاولة.");
    }

    try {
      final response = await _chatSession!.sendMessage(Content.text(message));
      return response.text;
    } catch (e) {
      throw Exception(
          "فشل في الحصول على إجابة من المساعد الذكي. تأكد من اتصالك بالإنترنت وأعد المحاولة. التفاصيل: $e");
    }
  }

  void resetChat() {
    _ensureInitialized();
    if (_model != null) {
      _chatSession = _model!.startChat();
    }
  }

  List<Content> getChatHistory() {
    return _chatSession?.history.toList() ?? [];
  }
}
