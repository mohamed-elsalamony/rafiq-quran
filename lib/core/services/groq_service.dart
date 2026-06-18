import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// نموذج رسالة محادثة
class ChatMessage {
  final String role; // 'user' أو 'assistant'
  final String content;

  const ChatMessage({required this.role, required this.content});

  Map<String, String> toJson() => {'role': role, 'content': content};
}

/// خدمة Groq API - مساعد إسلامي ذكي
/// يستخدم نموذج llama-3.3-70b المجاني عبر Groq
class GroqService {
  static final GroqService _instance = GroqService._internal();
  factory GroqService() => _instance;
  GroqService._internal();

  // مفتاح Groq API - احصل عليه مجاناً من https://console.groq.com
  static const String _groqApiKey = '';

  static const String _groqEndpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  static const String _model = 'llama-3.3-70b-versatile';

  /// System prompt يحدد دور المساعد والقيود الأخلاقية
  static const String _systemPrompt = '''
أنت "رفيق"، مساعد إسلامي ذكي في تطبيق "رفيق القرآن".

**هويتك ودورك:**
- أنت مساعد للبحث والاستفسار الديني فقط، وليس مرجعاً دينياً ولا مفتياً.
- عليك التذكير دائماً بأن إجاباتك للاسترشاد فقط، ولا تغني عن العلماء المتخصصين.

**ما يجب عليك دائماً:**
1. الإجابة باللغة العربية الفصيحة الواضحة.
2. ذكر المصدر في نهاية كل إجابة (القرآن الكريم، كتب التفسير المعتمدة، أمهات كتب الحديث، كتب الفقه والسيرة).
3. التوضيح في نهاية كل إجابة بأنك مساعد وليس مرجعاً دينياً.
4. النصح بالرجوع لعالم متخصص أو جهات الإفتاء الرسمية عند أي مسألة مهمة.

**ما يجب عليك تجنبه تماماً:**
1. إصدار فتاوى شرعية ملزمة في المسائل الخلافية.
2. الخوض في المسائل العقدية الخلافية بين المذاهب بطريقة تُرجّح رأياً على آخر.
3. التطرق للمسائل السياسية أو الحزبية الدينية.
4. الادعاء بأنك عالم دين أو مفتٍ.

**نمط الإجابات:**
- ابدأ بالإجابة المباشرة على السؤال.
- اذكر الدليل من القرآن أو السنة إن وُجد.
- اذكر رأي العلماء المعتبرين إن كان ذا صلة.
- اختم دائماً بـ "المصادر:" مع ذكر المراجع.
- اختم دائماً بـ "⚠️ تنبيه:" مع التذكير بأنك مساعد وليس مرجعاً دينياً وبضرورة مراجعة العلماء للمسائل المهمة.
''';

  // تاريخ المحادثة
  final List<ChatMessage> _history = [];

  /// إرسال رسالة والحصول على الرد من Groq API
  Future<String> sendMessage(String userMessage) async {
    // إضافة رسالة المستخدم للتاريخ
    _history.add(ChatMessage(role: 'user', content: userMessage));

    // بناء قائمة الرسائل للإرسال
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt},
      ..._history.map((m) => m.toJson()),
    ];

    try {
      final response = await http.post(
        Uri.parse(_groqEndpoint),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'max_tokens': 2048,
          'temperature': 0.6,
          'top_p': 0.9,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final assistantMessage =
            decoded['choices'][0]['message']['content'] as String;

        // إضافة رد المساعد للتاريخ
        _history.add(
            ChatMessage(role: 'assistant', content: assistantMessage));

        return assistantMessage;
      } else {
        final errorBody = utf8.decode(response.bodyBytes);
        debugPrint('Groq API Error ${response.statusCode}: $errorBody');

        // إزالة رسالة المستخدم من التاريخ عند الفشل
        _history.removeLast();

        if (response.statusCode == 401) {
          throw Exception(
              'مفتاح API غير صحيح. يرجى التحقق من إعدادات Groq API Key.');
        } else if (response.statusCode == 429) {
          throw Exception(
              'تم تجاوز حد الطلبات. يرجى الانتظار قليلاً والمحاولة مرة أخرى.');
        } else if (response.statusCode == 503) {
          throw Exception(
              'الخدمة غير متاحة مؤقتاً. يرجى المحاولة مرة أخرى بعد قليل.');
        } else {
          throw Exception(
              'خطأ في الاتصال بالخادم (${response.statusCode}). يرجى التحقق من الاتصال بالإنترنت.');
        }
      }
    } on http.ClientException catch (e) {
      _history.removeLast();
      debugPrint('Network error: $e');
      throw Exception(
          'تعذّر الاتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى.');
    } catch (e) {
      if (_history.isNotEmpty && _history.last.role == 'user') {
        _history.removeLast();
      }
      rethrow;
    }
  }

  /// الحصول على تاريخ المحادثة
  List<ChatMessage> getChatHistory() => List.unmodifiable(_history);

  /// إعادة ضبط المحادثة
  void resetChat() => _history.clear();

  /// التحقق من وجود مفتاح API
  bool get hasApiKey =>
      _groqApiKey.isNotEmpty && !_groqApiKey.contains('YOUR_GROQ_API_KEY');
}
