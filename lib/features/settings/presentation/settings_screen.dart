import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showResetConfirmation(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تحذير هام', textAlign: TextAlign.right, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text(
          'هل أنت متأكد تماماً من رغبتك في حذف جميع البيانات المحلية؟ سيؤدي ذلك إلى تصفير المسبحة، وحذف جميع خطط الحفظ والختمة والعلامات المرجعية والعودة للوضع الافتراضي.',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _showDoubleResetConfirmation(context, appState);
            },
            child: const Text('نعم، استمر', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDoubleResetConfirmation(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد أخير', textAlign: TextAlign.right, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text(
          'هذه الخطوة لا يمكن التراجع عنها! هل تؤكد حذف كل التقدم المحرز في الحفظ والورد اليومي بشكل نهائي؟',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء وتراجع'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
            onPressed: () async {
              Navigator.pop(context);
              await appState.clearAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تهيئة التطبيق بنجاح وحذف جميع البيانات المحلية!', textAlign: TextAlign.right),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('حذف نهائي للملفات', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
          'إعدادات التطبيق',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F7F5),
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // 1. المظهر والسمات
            _buildSectionHeader(title: 'المظهر والسمات', isDark: isDark, accentColor: accentColor),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: SwitchListTile(
                activeColor: accentColor,
                title: const Text('الوضع الليلي (Dark Mode)', textAlign: TextAlign.right),
                subtitle: Text(
                  isDark ? 'تفعيل المظهر الداكن المريح للعين ليلاً' : 'تفعيل المظهر الفاتح والساطع',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: accentColor),
                value: isDark,
                onChanged: (val) {
                  appState.toggleDarkMode(val);
                },
              ),
            ),
            const SizedBox(height: 20),

            // 2. خط المصحف والتصفح
            _buildSectionHeader(title: 'إعدادات خط المصحف', isDark: isDark, accentColor: accentColor),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'حجم الخط (${appState.fontSize.toInt()})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Icon(Icons.format_size, color: accentColor),
                      ],
                    ),
                    Slider(
                      value: appState.fontSize,
                      min: 16.0,
                      max: 36.0,
                      activeColor: primaryColor,
                      inactiveColor: primaryColor.withOpacity(0.2),
                      onChanged: (val) {
                        appState.setFontSize(val);
                      },
                    ),
                    const Divider(),
                    const Text(
                      'معاينة الخط العربي للآيات:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black26 : const Color(0xFFF9F7F3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                        style: GoogleFonts.amiri(
                          fontSize: appState.fontSize,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.amber[100] : primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. التنبيهات والإشعارات
            _buildSectionHeader(title: 'التنبيهات والإشعارات', isDark: isDark, accentColor: accentColor),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: SwitchListTile(
                activeColor: accentColor,
                title: const Text('تفعيل إشعارات التذكير اليومي', textAlign: TextAlign.right),
                subtitle: const Text(
                  'تذكير بقراءة الورد اليومي وأذكار الصباح والمساء',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                secondary: Icon(Icons.notifications_active, color: accentColor),
                value: appState.notificationsEnabled,
                onChanged: (val) {
                  appState.toggleNotifications(val);
                },
              ),
            ),
            const SizedBox(height: 20),

            // 4. إدارة البيانات والخصوصية
            _buildSectionHeader(title: 'إدارة البيانات المحلية', isDark: isDark, accentColor: accentColor),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('تهيئة التطبيق بالكامل (Factory Reset)', textAlign: TextAlign.right),
                subtitle: const Text(
                  'حذف كافة البيانات والتقدم والعودة للوضع الأصلي',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => _showResetConfirmation(context, appState),
              ),
            ),
            const SizedBox(height: 20),

            // 5. حول التطبيق
            _buildSectionHeader(title: 'حول رفيق القرآن', isDark: isDark, accentColor: accentColor),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('1.1.0', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('إصدار التطبيق', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'رفيق القرآن هو تطبيق إسلامي متكامل يهدف إلى مساعدتك في قراءة وتلاوة القرآن الكريم وحفظه وتدبر آياته، ومتابعة الورد اليومي والختمات مع المسبحة الإلكترونية والأذكار اليومية بطابع مريح وجميل وعملي.',
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[300] : Colors.grey[700], height: 1.5),
                      textAlign: TextAlign.justify,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'صدقة جارية لكل من ساهم في نشره واستخدمه 🤲',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required bool isDark, required Color accentColor}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.teal[100] : Colors.teal.shade800,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
