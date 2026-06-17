import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/gemini_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _suggestions = [
    'تفسير آية الكرسي وسياقها',
    'شرح حديث: "إنما الأعمال بالنيات"',
    'ما هي شروط وأوقات إجابة الدعاء؟',
    'كيف يساعدني هذا التطبيق في ختم القرآن؟',
    'ما فضل سورة الكهف وما يتعلق بها؟',
    'ما حكم صلاة الجماعة؟',
  ];

  @override
  void initState() {
    super.initState();
    // تهيئة المساعد تلقائياً دون الحاجة لمفتاح من المستخدم
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GeminiService().isInitialized; // يستدعي _ensureInitialized داخلياً
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      await GeminiService().sendMessage(text);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = appState.isDarkMode;
    const primaryColor = Color(0xFF0F5A47);
    const accentColor = Color(0xFFD4AF37);

    // Build chat history representation
    final history = GeminiService().getChatHistory();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'اسأل عن دينك (مساعد AI)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'إعادة بدء المحادثة',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('إعادة بدء المحادثة',
                      textAlign: TextAlign.right),
                  content: const Text(
                    'هل تريد حذف المحادثة الحالية والبدء من جديد؟',
                    textAlign: TextAlign.right,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor),
                      onPressed: () {
                        GeminiService().resetChat();
                        Navigator.pop(context);
                        setState(() {});
                      },
                      child: const Text('نعم، ابدأ من جديد',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F7F5),
        child: Column(
          children: [
            // Safe fatwa disclaimer alert
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.amber.shade900.withOpacity(isDark ? 0.2 : 0.1),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: isDark ? Colors.amber[200] : Colors.amber.shade900,
                      size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'تنبيه: الردود استرشادية فقط. لا يغني هذا المساعد عن سؤال أهل العلم المتخصصين والرجوع لجهات الإفتاء الرسمية.',
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            isDark ? Colors.amber[100] : Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: (history.isEmpty && !_isLoading)
                  ? _buildEmptyWelcomeView(isDark, primaryColor, accentColor)
                  : _buildChatListView(
                      history, isDark, primaryColor, accentColor),
            ),
            _buildInputArea(isDark, primaryColor, accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWelcomeView(
      bool isDark, Color primaryColor, Color accentColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome, size: 50, color: accentColor),
          ),
          const SizedBox(height: 16),
          const Text(
            'مرحباً بك في المساعد الإسلامي الذكي',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'اسألني عن تفسير الآيات وشرح الأحاديث والمسائل الدينية البسيطة وسأجيبك من المصادر الإسلامية المعتمدة بإذن الله.',
            style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
              child: Text(
                'أسئلة مقترحة للبدء:',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: primaryColor),
              ),
            ),
          ),
          ..._suggestions.map((prompt) => Card(
                elevation: 0,
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: primaryColor.withOpacity(0.1)),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(
                    prompt,
                    style: const TextStyle(fontSize: 13),
                    textAlign: TextAlign.right,
                  ),
                  leading: Icon(Icons.arrow_back, color: accentColor, size: 18),
                  onTap: () {
                    _sendMessage(prompt);
                  },
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildChatListView(List<Content> history, bool isDark,
      Color primaryColor, Color accentColor) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: history.length +
          (_isLoading ? 1 : 0) +
          (_errorMessage != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < history.length) {
          final content = history[index];
          final isUser = content.role == 'user';
          final text =
              content.parts.whereType<TextPart>().map((p) => p.text).join('\n');
          return _buildChatBubble(
              text, isUser, isDark, primaryColor, accentColor);
        } else if (index == history.length && _isLoading) {
          return _buildLoadingBubble(isDark, primaryColor);
        } else {
          return _buildErrorBubble(isDark);
        }
      },
    );
  }

  Widget _buildChatBubble(String text, bool isUser, bool isDark,
      Color primaryColor, Color accentColor) {
    return Align(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser
              ? (isDark
                  ? const Color(0xFF0D4D3D)
                  : primaryColor.withOpacity(0.08))
              : (isDark ? const Color(0xFF232323) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                isUser ? const Radius.circular(0) : const Radius.circular(16),
            bottomRight:
                isUser ? const Radius.circular(16) : const Radius.circular(0),
          ),
          border: Border.all(
            color: isUser
                ? primaryColor.withOpacity(0.2)
                : (isDark
                    ? Colors.grey.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Role label
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUser ? Icons.person : Icons.auto_awesome,
                  size: 14,
                  color: isUser ? primaryColor : accentColor,
                ),
                const SizedBox(width: 6),
                Text(
                  isUser ? 'أنت' : 'المساعد الذكي',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isUser ? primaryColor : accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SelectableText(
              text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBubble(bool isDark, Color primaryColor) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF232323) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'المساعد يبحث ويصيغ الرد...',
              style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBubble(bool isDark) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _errorMessage ?? 'حدث خطأ غير متوقع. الرجاء المحاولة مرة أخرى.',
                style: const TextStyle(
                    fontSize: 12, color: Colors.red, height: 1.4),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isDark, Color primaryColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.grey.withOpacity(0.1)
                : Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textDirection: TextDirection.rtl,
                maxLines: null,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'اكتب سؤالك هنا عن تفسير آية أو شرح حديث...',
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: isDark
                      ? const Color(0xFF2C2C2C)
                      : const Color(0xFFF4F7F5),
                  filled: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: _isLoading ? null : (val) => _sendMessage(val),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isLoading
                  ? null
                  : () => _sendMessage(_messageController.text),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isLoading ? Colors.grey : primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Transform.scale(
                  scaleX: -1,
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
