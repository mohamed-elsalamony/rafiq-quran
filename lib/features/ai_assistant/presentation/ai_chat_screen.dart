import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/gemini_service.dart';
import '../../settings/presentation/settings_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _dotAnimController;

  static const _primaryColor = Color(0xFF0F5A47);
  static const _accentColor = Color(0xFFD4AF37);

  final List<String> _suggestions = [
    'تفسير آية الكرسي وسياقها',
    'شرح حديث: "إنما الأعمال بالنيات"',
    'ما هي شروط وأوقات إجابة الدعاء؟',
    'ما فضل سورة الكهف وما يتعلق بها؟',
    'ما حكم صلاة الجماعة عند الفقهاء؟',
    'ما هي أركان الإسلام وأدلتها؟',
  ];

  @override
  void initState() {
    super.initState();
    _dotAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _dotAnimController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _messageController.clear();
    _scrollToBottom();

    final appState = Provider.of<AppState>(context, listen: false);
    try {
      await GeminiService().sendMessage(trimmed, appState);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = appState.isDarkMode;
    final history = GeminiService().getChatHistory();

    final bool hasContent =
        history.isNotEmpty || _isLoading || _errorMessage != null;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF4F7F5),
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          _buildDisclaimerBanner(isDark),
          Expanded(
            child: hasContent
                ? _buildChatListView(history, isDark)
                : _buildWelcomeView(isDark),
          ),
          _buildInputArea(isDark),
        ],
      ),
    );
  }

  AppBar _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1F1F1F) : _primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'رفيق - المساعد الإسلامي',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Consumer<AppState>(
            builder: (context, appState, _) {
              Color statusColor = Colors.orange[200]!;
              String statusText = 'وضع قاعدة البيانات المحلية';
              if (appState.assistantStatus == 'online') {
                statusColor = Colors.tealAccent[100]!;
                statusText = 'الوضع الذكي نشط (Gemini AI)';
              } else if (appState.assistantStatus == 'failed') {
                statusColor = Colors.red[200]!;
                statusText = 'فشل الاتصال بالسيرفر';
              }
              return Text(
                statusText,
                style: TextStyle(
                  fontSize: 10,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'محادثة جديدة',
          onPressed: _confirmReset,
        ),
      ],
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('محادثة جديدة', textAlign: TextAlign.right),
        content: const Text(
          'هل تريد حذف المحادثة الحالية والبدء من جديد؟',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            onPressed: () async {
              await GeminiService().resetChat();
              Navigator.pop(ctx);
              setState(() {
                _errorMessage = null;
              });
            },
            child: const Text('نعم، ابدأ من جديد',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.amber.shade900.withOpacity(0.18)
            : Colors.amber.shade50,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.amber.withOpacity(0.15)
                : Colors.amber.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: isDark ? Colors.amber[300] : Colors.amber.shade800,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'الردود للاسترشاد فقط — تُراجَع المسائل الشرعية المهمة مع أهل العلم',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.amber[200] : Colors.amber.shade900,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeView(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        children: [
          // أيقونة مع تدرج
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: RadialGradient(colors: [
                _accentColor.withOpacity(0.18),
                _primaryColor.withOpacity(0.06),
              ]),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.auto_awesome, size: 44, color: _accentColor),
          ),
          const SizedBox(height: 18),
          const Text(
            'مرحباً، أنا رفيق',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'مساعدك الإسلامي الذكي. اسألني عن تفسير الآيات، شرح الأحاديث، أحكام الفقه، قصص الأنبياء وسير الصحابة الكرام.',
            style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.65),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          // شارة نموذج المساعد الذكية
          Consumer<AppState>(
            builder: (context, appState, _) {
              final isOnline = appState.assistantStatus == 'online';
              final Color badgeColor = isOnline ? _primaryColor : Colors.orange;
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: badgeColor.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOnline ? Icons.bolt_rounded : Icons.cloud_off_rounded,
                        size: 13,
                        color: badgeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOnline
                            ? 'مساعد متقدم نشط (Gemini 2.5 Pro)'
                            : 'الوضع المحلي (اضغط هنا لتفعيل المساعد الذكي)',
                        style: TextStyle(
                            fontSize: 11,
                            color: isOnline ? badgeColor : Colors.orange.shade800,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          // عنوان الاقتراحات
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'جرّب أحد هذه الأسئلة:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // بطاقات الاقتراحات
          ..._suggestions.map(
            (prompt) => _SuggestionCard(
              text: prompt,
              isDark: isDark,
              onTap: () => _sendMessage(prompt),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatListView(List<ChatMessage> history, bool isDark) {
    final int extra = (_isLoading ? 1 : 0) + (_errorMessage != null ? 1 : 0);
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: history.length + extra,
      itemBuilder: (context, index) {
        if (index < history.length) {
          final msg = history[index];
          return _ChatBubble(
            key: ValueKey('msg_$index'),
            text: msg.content,
            isUser: msg.role == 'user',
            isDark: isDark,
          );
        } else if (_isLoading && index == history.length) {
          return _TypingIndicator(
              isDark: isDark, animController: _dotAnimController);
        } else {
          return _ErrorBubble(message: _errorMessage, isDark: isDark);
        }
      },
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : Colors.grey.withOpacity(0.15),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // حقل الإدخال
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2C)
                      : const Color(0xFFF0F4F2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _focusNode.hasFocus
                        ? _primaryColor.withOpacity(0.4)
                        : Colors.transparent,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  textDirection: TextDirection.rtl,
                  maxLines: null,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87),
                  decoration: const InputDecoration(
                    hintText: 'اكتب سؤالك هنا...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: _isLoading
                      ? null
                      : (val) {
                          if (val.trim().isNotEmpty) _sendMessage(val);
                        },
                ),
              ),
            ),
            const SizedBox(width: 8),
            // زر الإرسال
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: GestureDetector(
                onTap: (_isLoading ||
                        _messageController.text.trim().isEmpty)
                    ? null
                    : () => _sendMessage(_messageController.text),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: (_isLoading ||
                            _messageController.text.trim().isEmpty)
                        ? Colors.grey.withOpacity(0.3)
                        : _primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: (_isLoading ||
                            _messageController.text.trim().isEmpty)
                        ? []
                        : [
                            BoxShadow(
                              color: _primaryColor.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(13),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
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

// ==================== مكونات منفصلة ====================

class _SuggestionCard extends StatelessWidget {
  final String text;
  final bool isDark;
  final VoidCallback onTap;
  const _SuggestionCard(
      {required this.text, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2A26) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF0F5A47).withOpacity(0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 13,
                color: Color(0xFFD4AF37),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[200] : Colors.grey[800],
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isDark;

  const _ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.isDark,
  });

  static const _primaryColor = Color(0xFF0F5A47);
  static const _accentColor = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          // تسمية المرسل
          Padding(
            padding: EdgeInsets.only(
              bottom: 4,
              left: isUser ? 0 : 4,
              right: isUser ? 4 : 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUser) ...[
                  Icon(Icons.auto_awesome,
                      size: 12, color: _accentColor.withOpacity(0.8)),
                  const SizedBox(width: 4),
                  Text('رفيق',
                      style: TextStyle(
                          fontSize: 10,
                          color: _accentColor.withOpacity(0.9),
                          fontWeight: FontWeight.bold)),
                ],
                if (isUser) ...[
                  Text('أنت',
                      style: TextStyle(
                          fontSize: 10,
                          color: _primaryColor.withOpacity(0.7),
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Icon(Icons.person,
                      size: 12, color: _primaryColor.withOpacity(0.7)),
                ],
              ],
            ),
          ),
          // فقاعة الرسالة
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.83,
            ),
            decoration: BoxDecoration(
              color: isUser
                  ? (isDark
                      ? const Color(0xFF0D4D3D)
                      : _primaryColor.withOpacity(0.07))
                  : (isDark ? const Color(0xFF252525) : Colors.white),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 16),
              ),
              border: Border.all(
                color: isUser
                    ? _primaryColor.withOpacity(0.18)
                    : (isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.grey.withOpacity(0.12)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 36),
                  child: SelectableText(
                    text,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.65,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                // زر النسخ في الأسفل
                if (!isUser)
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('تم نسخ الرد',
                                textAlign: TextAlign.right),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: _primaryColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.copy_rounded,
                                size: 12,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[400]),
                            const SizedBox(width: 3),
                            Text('نسخ',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? Colors.grey[500]
                                        : Colors.grey[400])),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  final bool isDark;
  final AnimationController animController;

  const _TypingIndicator(
      {required this.isDark, required this.animController});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252525) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.grey.withOpacity(0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('رفيق يكتب',
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600])),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: animController,
              builder: (_, __) {
                return Row(
                  children: List.generate(3, (i) {
                    final delay = i / 3;
                    final opacity = (animController.value - delay)
                        .clamp(0.0, 0.5) *
                        2;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Opacity(
                        opacity: (0.3 + opacity).clamp(0.3, 1.0),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD4AF37),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBubble extends StatelessWidget {
  final String? message;
  final bool isDark;
  const _ErrorBubble({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message ?? 'حدث خطأ غير متوقع. الرجاء المحاولة مرة أخرى.',
              style: const TextStyle(
                  fontSize: 12.5, color: Colors.red, height: 1.5),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
