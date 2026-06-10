import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final List<MessageModel> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  // الأسئلة المقترحة السريعة
  final List<String> _suggestions = [
    'اقترح لي وردًا قرآنيًا لليوم',
    'ما تفسير آية الكرسي باختصار؟',
    'كيف أضع خطة لحفظ سورة الملك؟',
    'اذكر لي فضل أذكار الصباح والمساء',
    'ما هي أسباب نزول سورة الكهف؟'
  ];

  @override
  void initState() {
    super.initState();
    // رسالة الترحيب التلقائية
    _messages.add(
      MessageModel(
        text: 'السلام عليكم ورحمة الله وبركاته، أنا رفيقك الذكي. كيف يمكنني مساعدتك اليوم في تلاوة القرآن أو تفسيره، أو تنظيم خطط الحفظ والمراجعة والأذكار؟',
        isUser: false,
        time: DateTime.now(),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // محاكي الرد الذكي دون اتصال
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

  // إرسال الرسالة ومعالجتها
  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final appState = Provider.of<AppState>(context, listen: false);

    setState(() {
      _messages.add(MessageModel(text: text, isUser: true, time: DateTime.now()));
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();

    // تشغيل الاتصال بالذكاء الاصطناعي الفعلي إذا وجد مفتاح API Key
    String replyText = '';
    if (appState.geminiApiKey.isNotEmpty) {
      try {
        final model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: appState.geminiApiKey,
        );
        final prompt = 'أنت مساعد إسلامي ذكي اسمك "رفيق الذكي". أجب عن السؤال التالي بدقة مستنداً لمصادر إسلامية موثوقة وباللغة العربية: $text';
        final content = [Content.text(prompt)];
        final response = await model.generateContent(content);
        replyText = response.text ?? 'لم يتم تلقي استجابة صحيحة من الذكاء الاصطناعي.';
      } catch (e) {
        replyText = 'فشل الاتصال بالذكاء الاصطناعي: $e\n\n(تم التحويل للرد التلقائي):\n${_getOfflineAiResponse(text)}';
      }
    } else {
      // إيقاف مؤقت بسيط لمحاكاة التفكير
      await Future.delayed(const Duration(milliseconds: 1000));
      replyText = _getOfflineAiResponse(text);
    }

    if (mounted) {
      setState(() {
        _messages.add(MessageModel(text: replyText, isUser: false, time: DateTime.now()));
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = appState.isDarkMode;
    final primaryColor = const Color(0xFF0F5A47);
    final Color accentColor = const Color(0xFFD4AF37);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'رفيق الذكي (AI)',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F4),
        ),
        child: Column(
          children: [
            // تنبيه للمستخدم في حال لم يقم بتهيئة مفتاح الـ API
            if (appState.geminiApiKey.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.amber[900]?.withOpacity(0.2),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: accentColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'أنت تستخدم وضع المحاكاة دون إنترنت. أدخل مفتاح Gemini API Key في الإعدادات لتفعيل المحادثات الحية والمفتوحة.',
                        style: TextStyle(fontSize: 10, color: isDark ? Colors.amber[200] : Colors.amber[900]),
                      ),
                    ),
                  ],
                ),
              ),

            // قائمة الرسائل
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(msg, isDark, primaryColor, accentColor);
                },
              ),
            ),

            // مؤشر الكتابة
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'جاري كتابة الرد...',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ),
              ),

            // قائمة الأسئلة المقترحة
            if (_messages.length == 1 && !_isTyping)
              Container(
                height: 44,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ActionChip(
                        label: Text(
                          suggestion,
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
                        ),
                        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[200],
                        onPressed: () => _sendMessage(suggestion),
                      ),
                    );
                  },
                ),
              ),

            // شريط إدخال الرسائل
            Container(
              padding: const EdgeInsets.all(12.0),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.send, color: primaryColor),
                    onPressed: () => _sendMessage(_messageController.text),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      decoration: const InputDecoration(
                        hintText: 'اكتب سؤالك هنا...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isDark, Color primaryColor, Color accentColor) {
    return Align(
      alignment: msg.isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: msg.isUser
              ? (isDark ? Colors.grey[800] : Colors.grey[200])
              : (isDark ? const Color(0xFF182D27) : const Color(0xFFEDF5F2)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: msg.isUser ? Radius.zero : const Radius.circular(16),
            bottomRight: msg.isUser ? const Radius.circular(16) : Radius.zero,
          ),
          border: msg.isUser 
              ? null 
              : Border.all(color: primaryColor.withOpacity(0.15), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 14.5,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.5,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 4),
            Text(
              '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[500],
              ),
              textAlign: msg.isUser ? TextAlign.left : TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }
}
