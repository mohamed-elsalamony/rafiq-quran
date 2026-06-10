import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_state.dart';
import 'ai_provider.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final aiProvider = Provider.of<AiProvider>(context, listen: false);
      aiProvider.addListener(_onProviderChange);
      _isInit = true;
    }
  }

  @override
  void dispose() {
    try {
      final aiProvider = Provider.of<AiProvider>(context, listen: false);
      aiProvider.removeListener(_onProviderChange);
    } catch (_) {}
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onProviderChange() {
    if (!mounted) return;
    final provider = Provider.of<AiProvider>(context, listen: false);

    // Scroll to bottom when new messages arrive
    _scrollToBottom();

    // Show error Snackbar if API call failed
    if (provider.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && provider.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage!, textAlign: TextAlign.right),
              backgroundColor: Colors.amber[900],
            ),
          );
          provider.clearError();
        }
      });
    }
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

  void _sendMessage(AiProvider provider, String text) {
    if (text.trim().isEmpty) return;
    provider.sendMessage(text);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final aiProvider = Provider.of<AiProvider>(context);
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
            // API key warning banner
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

            // Messages history list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: aiProvider.messages.length,
                itemBuilder: (context, index) {
                  final msg = aiProvider.messages[index];
                  return _buildMessageBubble(msg, isDark, primaryColor);
                },
              ),
            ),

            // Typing loader indicator
            if (aiProvider.isTyping)
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

            // Action suggestions chips
            if (aiProvider.messages.length == 1 && !aiProvider.isTyping)
              Container(
                height: 44,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: aiProvider.suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = aiProvider.suggestions[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ActionChip(
                        label: Text(
                          suggestion,
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
                        ),
                        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[200],
                        onPressed: () => _sendMessage(aiProvider, suggestion),
                      ),
                    );
                  },
                ),
              ),

            // Input message box
            Container(
              padding: const EdgeInsets.all(12.0),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.send, color: primaryColor),
                    onPressed: () => _sendMessage(aiProvider, _messageController.text),
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
                      onSubmitted: (text) => _sendMessage(aiProvider, text),
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

  Widget _buildMessageBubble(MessageModel msg, bool isDark, Color primaryColor) {
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
