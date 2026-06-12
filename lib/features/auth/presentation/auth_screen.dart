import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_state.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoggedIn = false;
  String _userEmail = '';
  bool _isSyncing = false;
  double _syncProgress = 0.0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('الرجاء إدخال البريد الإلكتروني وكلمة المرور.')),
      );
      return;
    }

    setState(() {
      _isLoggedIn = true;
      _userEmail = email;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('مرحباً بك! تم تسجيل الدخول بحساب $email')),
    );
  }

  void _handleLogout() {
    setState(() {
      _isLoggedIn = false;
      _userEmail = '';
      _emailController.clear();
      _passwordController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تسجيل الخروج بنجاح.')),
    );
  }

  // محاكاة المزامنة السحابية التفاعلية
  void _startCloudSync() async {
    if (!_isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('الرجاء تسجيل الدخول أولاً لتفعيل المزامنة السحابية.')),
      );
      return;
    }

    setState(() {
      _isSyncing = true;
      _syncProgress = 0.0;
    });

    // زيادة مؤشر تقدم المزامنة بشكل بصرى رائع
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (mounted) {
        setState(() {
          _syncProgress = i / 10;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isSyncing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'تمت مزامنة العلامات المرجعية وخطط الحفظ والإحصائيات بنجاح مع خادم "رفيق"! ☁️')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = appState.isDarkMode;
    const primaryColor = Color(0xFF0F5A47);
    const Color accentColor = Color(0xFFD4AF37);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : primaryColor,
        foregroundColor: Colors.white,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: const Text(
            'الحساب والمزامنة السحابية',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
              fontSize: 16,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F4),
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Icon(
                Icons.cloud_done,
                size: 80,
                color: _isLoggedIn ? Colors.teal : Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'مزامنة وحفظ بياناتك سحابياً',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'قم بتسجيل الدخول لمزامنة آخر موضع قراءة، والعلامات المرجعية، والإعدادات الخاصة بك تلقائياً بين أجهزتك المختلفة.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.4),
              ),
              const SizedBox(height: 30),
              if (!_isLoggedIn) ...[
                // واجهة تسجيل الدخول
                TextField(
                  controller: _emailController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('تسجيل الدخول / إنشاء حساب',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoggedIn = true;
                      _userEmail = 'user.tester@gmail.com';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('تم تسجيل الدخول السريع بحساب Google')),
                    );
                  },
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: const Text('تسجيل الدخول السريع بحساب Google'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : Colors.black87,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ] else ...[
                // واجهة المستخدم المسجل
                Card(
                  elevation: 2,
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.account_circle,
                              size: 48, color: Colors.teal),
                          title: const Text('المستخدم الحالي',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(_userEmail),
                        ),
                        const Divider(),
                        const SizedBox(height: 12),

                        // مؤشر المزامنة
                        if (_isSyncing) ...[
                          Text(
                              'جاري مزامنة البيانات السحابية... ${(_syncProgress * 100).toInt()}%'),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: _syncProgress,
                              minHeight: 8,
                              backgroundColor: Colors.grey[200],
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(primaryColor),
                            ),
                          ),
                        ] else ...[
                          ElevatedButton.icon(
                            onPressed: _startCloudSync,
                            icon: const Icon(Icons.sync),
                            label: const Text('مزامنة البيانات الآن'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _handleLogout,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('تسجيل الخروج'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
