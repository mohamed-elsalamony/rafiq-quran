import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/services/app_state.dart';

class MessageModel {
  final String text;
  final bool isUser;
  final DateTime time;

  MessageModel({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

class AiProvider extends ChangeNotifier {
  final AppState appState;
  final List<MessageModel> _messages = [];
  bool _isTyping = false;
  String? _errorMessage;

  final List<String> suggestions = [
    'اقترح لي وردًا قرآنيًا لليوم',
    'ما تفسير آية الكرسي باختصار؟',
    'كيف أضع خطة حفظ سورة الملك؟',
    'اذكر لي فضل أذكار الصباح والمساء',
    'ما هي أسباب نزول سورة الكهف؟'
  ];

  // Getters
  List<MessageModel> get messages => _messages;
  bool get isTyping => _isTyping;
  String? get errorMessage => _errorMessage;

  AiProvider({required this.appState}) {
    // Welcome message
    _messages.add(
      MessageModel(
        text: 'السلام عليكم ورحمة الله وبركاته، أنا رفيقك الذكي. كيف يمكنني مساعدتك اليوم في تلاوة القرآن أو تفسيره، أو تنظيم خطط الحفظ والمراجعة والأذكار؟',
        isUser: false,
        time: DateTime.now(),
      ),
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Offline rule-based response simulator
  String _getOfflineAiResponse(String query) {
    query = query.toLowerCase();
    if (query.contains('ورد') || query.contains('قراءة') || query.contains('يوم')) {
      return 'اقتراح الورد اليومي:\nنقترح عليك قراءة 4 صفحات يومياً (بعد صلاة الفجر أو المغرب). هذا الورد الميسر يتيح لك ختم القرآن الكريم كاملاً خلال 5 أشهر تقريباً، وبمعدل 15 دقيقة فقط من وقتك يومياً.';
    } else if (query.contains('الكرسي') || query.contains('تفسير آية الكرسي')) {
      return 'تفسير آية الكرسي باختصار:\nهي أعظم آية في كتاب الله. تحتوي على عقيدة التوحيد الخالص وأسماء الله الحسنى وصفاته العلا. تتحدث عن حياة الله الكاملة (الحي)، قيوميته على شؤون خلقه (القيوم)، سعة علمه وملكه وكبريائه (وسع كرسيه السموات والأرض). وقراءتها دبر كل صلاة مكتوبة سبب لدخول الجنة.';
    } else if (query.contains('الملك') || query.contains('حفظ سورة الملك')) {
      return 'خطة حفظ سورة الملك (30 آية):\n* المدة: 6 أيام فقط.\n* الورد اليومي: حفظ 5 آيات يومياً.\n* اليوم 1: الآيات 1-5.\n* اليوم 2: الآيات 6-10.\n* اليوم 3: الآيات 11-15.\n* اليوم 4: الآيات 16-20.\n* اليوم 5: الآيات 21-25.\n* اليوم 6: الآيات 26-30.\n* ننصحك بالمراجعة التكرارية قبل البدء بالورد الجديد وتلاوتها في النوافل.';
    } else if (query.contains('فضل') || query.contains('أذكار')) {
      return 'فضل أذكار الصباح والمساء:\nهي حصن المسلم اليومي ومصدر انشراح صدره وتيسير أمره. تحفظه من شياطين الإنس والجن، وتجلب له رضا الرحمن، وتزيد من بركة يومه، وتزيل الهم والحزن عن قلبه كما جاء في أحاديث النبي صلى الله عليه وسلم.';
    } else if (query.contains('الكهف') || query.contains('نزول سورة الكهف')) {
      return 'أسباب نزول سورة الكهف:\nنزلت سورة الكهف رداً على ثلاثة أسئلة وجهها مشركو مكة للنبي صلى الله عليه وسلم بتوجيه من اليهود لاختبار نبوته: عن فتية ذهبوا في الدهر الأول (أصحاب الكهف)، وعن رجل طاف مشارق الأرض ومغاربها (ذو القرنين)، وعن الروح. فجاءت السورة تفصل هذه القصص العظيمة إثباتاً لصدق نبوته.';
    } else {
      return 'لمعالجة استفسارك بدقة حية والإجابة على الأسئلة الإسلامية العامة، يرجى تفعيل مفتاح Gemini API Key الخاص بك في الإعدادات لتفعيل المساعد الذكي المباشر.';
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(MessageModel(text: text, isUser: true, time: DateTime.now()));
    _isTyping = true;
    _errorMessage = null;
    notifyListeners();

    String replyText = '';
    if (appState.geminiApiKey.isNotEmpty) {
      try {
        final model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: appState.geminiApiKey,
        );
        final prompt = 'أنت مساعد إسلامي ذكي اسمك "رفيق الذكي". أجب عن السؤال التالي بدقة مستنداً لمصادر إسلامية موثوقة وباللغة العربية: $text';
        final content = [Content.text(prompt)];
        
        final response = await model.generateContent(content).timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception('انتهت مهلة الاتصال بخادم الذكاء الاصطناعي.'),
        );
        
        replyText = response.text ?? 'لم يتم تلقي استجابة صحيحة من الذكاء الاصطناعي.';
      } catch (e) {
        debugPrint("Gemini API error: $e");
        _errorMessage = "فشل الاتصال بالذكاء الاصطناعي: ${e.toString().replaceAll('Exception:', '').trim()}. تم استخدام المحاكي المحلي.";
        replyText = _getOfflineAiResponse(text);
      }
    } else {
      // Simulate think delay offline
      await Future.delayed(const Duration(milliseconds: 800));
      replyText = _getOfflineAiResponse(text);
    }

    _messages.add(MessageModel(text: replyText, isUser: false, time: DateTime.now()));
    _isTyping = false;
    notifyListeners();
  }
}
