import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

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
- لا تجيب أبداً على المسائل العقدية الخلافية أو المسائل الفقهية المعقدة أو الخلافات بين المذاهب. إذا سئلت عنها، اعتذر بلطف ووجه المستخدم لسؤال أهل العلم المتخصصين مستشهداً بآية: ﴿فَاسْأَلُوا أَهْلَ الذِّكْرِ إِن كُنتُمْ لَا تَعْلَمُونَ﴾.
- استند دائماً إلى مصادر إسلامية موثوقة وصحيحة، وتجنب القصص غير الموثقة أو الأحاديث الضعيفة والموضوعة.
- رد باللغة العربية الفصحى الواضحة والراقية وبأدب جم وتنسيق جميل يسهل قراءته.
""";

  GenerativeModel? _model;
  ChatSession? _chatSession;
  String? _currentApiKey;

  void initialize(String apiKey) {
    if (apiKey.isEmpty) {
      _model = null;
      _chatSession = null;
      _currentApiKey = null;
      return;
    }

    if (_currentApiKey == apiKey && _model != null) {
      return;
    }

    _currentApiKey = apiKey;
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(systemInstruction),
    );
    _chatSession = _model!.startChat();
  }

  bool get isInitialized => _model != null;

  Future<String?> sendMessage(String message) async {
    if (_model == null || _chatSession == null) {
      throw Exception(
          "الرجاء إدخال مفتاح Gemini API Key أولاً في الإعدادات لتشغيل المساعد الذكي.");
    }

    try {
      final response = await _chatSession!.sendMessage(Content.text(message));
      return response.text;
    } catch (e) {
      throw Exception(
          "فشل في الحصول على إجابة من المساعد الذكي. تأكد من صحة مفتاح Gemini API Key والاتصال بالإنترنت. التفاصيل: $e");
    }
  }

  void resetChat() {
    if (_model != null) {
      _chatSession = _model!.startChat();
    }
  }

  List<Content> getChatHistory() {
    return _chatSession?.history.toList() ?? [];
  }
}
