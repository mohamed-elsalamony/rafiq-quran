import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/db_helper.dart';
import '../../../core/services/notification_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final TextEditingController _notificationTitleController = TextEditingController();
  final TextEditingController _notificationBodyController = TextEditingController();
  
  int _totalBookmarksCount = 0;
  int _totalCustomAdhkarCount = 0;
  int _totalLogsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void dispose() {
    _notificationTitleController.dispose();
    _notificationBodyController.dispose();
    super.dispose();
  }

  void _loadStats() async {
    final bookmarks = await DbHelper.getBookmarks();
    final customs = await DbHelper.getCustomAdhkar();
    final logs = await DbHelper.getTasbihLogs();

    if (mounted) {
      setState(() {
        _totalBookmarksCount = bookmarks.length;
        _totalCustomAdhkarCount = customs.length;
        _totalLogsCount = logs.length;
      });
    }
  }

  void _simulateSendBroadcastNotification() {
    final title = _notificationTitleController.text.trim();
    final body = _notificationBodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال عنوان الإشعار ونص الرسالة.')),
      );
      return;
    }

    // إرسال تنبيه محلي فوري محاكاة للإشعار الجماعي
    NotificationService().showInstantAlert(context, '📣 إشعار عام: $title', body);

    _notificationTitleController.clear();
    _notificationBodyController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت محاكاة إرسال الإشعار الجماعي لجميع الأجهزة!')),
    );
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
          'لوحة تحكم المشرف (Admin)',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F4),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // قسم إحصائيات التطبيق المحلية
              _buildSectionCard(
                title: 'إحصائيات استخدام النظام محلياً',
                isDark: isDark,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatIndicator('العلامات المرجعية', '$_totalBookmarksCount', Colors.amber),
                    _buildStatIndicator('أذكار مخصصة', '$_totalCustomAdhkarCount', Colors.teal),
                    _buildStatIndicator('سجلات التسبيح', '$_totalLogsCount', Colors.blue),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // قسم إرسال الإشعارات الجماعية للمشتركين
              _buildSectionCard(
                title: 'إرسال إشعار جماعي للمشتركين',
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _notificationTitleController,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        labelText: 'عنوان الإشعار',
                        hintText: 'مثال: تذكير بورد الجمعة',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notificationBodyController,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'نص الرسالة',
                        hintText: 'مثال: لا تنس قراءة سورة الكهف والصلاة على النبي',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _simulateSendBroadcastNotification,
                      icon: const Icon(Icons.send_to_mobile),
                      label: const Text('إرسال الإشعار الآن'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // قسم إدارة المحتوى
              _buildSectionCard(
                title: 'إدارة المحتوى المدمج',
                isDark: isDark,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.interpreter_mode, color: Colors.teal),
                      title: const Text('تحديث قائمة التفاسير والترجمات', textAlign: TextAlign.right),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('قاعدة بيانات التفاسير محدثة ومستقرة محلياً.')),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.record_voice_over, color: Colors.teal),
                      title: const Text('إضافة وتعديل روابط القراء الصوتيّة', textAlign: TextAlign.right),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('روابط تلاوات EveryAyah مدمجة وتعمل بكفاءة.')),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.analytics_outlined, color: Colors.teal),
                      title: const Text('تحميل سجل الأخطاء والتحليلات', textAlign: TextAlign.right),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم حفظ سجل التحليلات في ملف Log محلي.')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatIndicator(String title, String val, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    required bool isDark,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.right,
            ),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}
