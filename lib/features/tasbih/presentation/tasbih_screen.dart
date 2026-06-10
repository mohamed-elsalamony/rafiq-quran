import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/db_helper.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  int _counter = 0;
  int _target = 33; // الهدف الافتراضي للتكرار
  String _selectedDhikr = 'سبحان الله';
  bool _isVibrationEnabled = true;
  bool _isSoundEnabled = true;
  
  List<String> _predefinedDhikrs = [
    'سبحان الله',
    'الحمد لله',
    'لا إله إلا الله',
    'الله أكبر',
    'أستغفر الله العظيم',
    'اللهم صلِّ وسلم على محمد'
  ];

  List<Map<String, dynamic>> _customDhikrs = [];
  List<Map<String, dynamic>> _tasbihStats = [];

  // حجم الزر للرسوم المتحركة عند الضغط
  double _btnScale = 1.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final customs = await DbHelper.getCustomAdhkar();
    final stats = await DbHelper.getTasbihLogs();
    if (mounted) {
      setState(() {
        _customDhikrs = customs;
        _tasbihStats = stats;
      });
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
      _btnScale = 0.93; // تأثير بصرى للضغط
    });

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) {
        setState(() {
          _btnScale = 1.0;
        });
      }
    });

    // الصوت والاهتزاز
    if (_isVibrationEnabled) {
      HapticFeedback.lightImpact();
    }
    if (_isSoundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }

    // إذا وصلنا للهدف
    if (_counter == _target) {
      if (_isVibrationEnabled) {
        HapticFeedback.vibrate(); // اهتزاز طويل للتنبيه
      }
      _showTargetCompletedAlert();
      // حفظ السجل
      DbHelper.addTasbihLog(_selectedDhikr, _target);
      _loadData();
    }
  }

  void _resetCounter() {
    if (_counter > 0) {
      // حفظ ما تم تسبيحه قبل التصفير
      DbHelper.addTasbihLog(_selectedDhikr, _counter);
      _loadData();
    }
    setState(() {
      _counter = 0;
    });
    HapticFeedback.mediumImpact();
  }

  void _showTargetCompletedAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'أحسنت! أتممت الورد لذكر "$_selectedDhikr" ($_target مرة).',
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: kIsWeb ? FontWeight.bold : FontWeight.w700),
        ),
        backgroundColor: Colors.teal.shade800,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // إضافة ذكر مخصص
  void _addNewCustomDhikr() {
    final textController = TextEditingController();
    final targetController = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة ذكر مخصص', textAlign: TextAlign.right),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: 'اكتب الذكر هنا...',
                labelText: 'نص الذكر',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                labelText: 'العدد المستهدف (مثلاً: 100)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F5A47)),
            onPressed: () async {
              if (textController.text.trim().isNotEmpty) {
                final target = int.tryParse(targetController.text) ?? 100;
                await DbHelper.addCustomAdhkar(textController.text.trim(), target);
                _loadData();
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('إضافة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // حذف ذكر مخصص
  void _deleteCustomDhikr(int index) async {
    await DbHelper.deleteCustomAdhkar(index);
    _loadData();
  }

  // --- حساب إحصائيات التسبيح الأسبوعية للتصميم البياني ---
  List<Map<String, dynamic>> _getWeeklyStats() {
    // سنقوم بتجميع إحصائيات آخر 7 أيام
    final Map<String, int> dailySums = {};
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);
      dailySums[dateStr] = 0;
    }

    for (final log in _tasbihStats) {
      final dateStr = log['date'] as String?;
      final count = log['count'] as int? ?? 0;
      if (dateStr != null && dailySums.containsKey(dateStr)) {
        dailySums[dateStr] = dailySums[dateStr]! + count;
      }
    }

    List<Map<String, dynamic>> stats = [];
    final List<String> weekdaysArabic = ['أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت'];
    
    dailySums.forEach((dateStr, count) {
      final parsedDate = DateTime.parse(dateStr);
      // رقم يوم الأسبوع من 1 (الاثنين) إلى 7 (الأحد)
      final weekdayIdx = parsedDate.weekday == 7 ? 0 : parsedDate.weekday;
      stats.add({
        'day': weekdaysArabic[weekdayIdx],
        'count': count,
      });
    });

    return stats;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = appState.isDarkMode;
    final primaryColor = const Color(0xFF0F5A47);
    final Color accentColor = const Color(0xFFD4AF37);
    
    final weeklyStats = _getWeeklyStats();
    final maxStatCount = weeklyStats.map<int>((e) => e['count'] as int).fold(0, (max, e) => e > max ? e : max);

    // دمج الأذكار الافتراضية مع المخصصة في قائمة منسدلة واحدة
    List<DropdownMenuItem<String>> dropdownItems = [];
    for (var d in _predefinedDhikrs) {
      dropdownItems.add(DropdownMenuItem(value: d, child: Text(d, textAlign: TextAlign.right)));
    }
    for (var cd in _customDhikrs) {
      dropdownItems.add(DropdownMenuItem(value: cd['text'], child: Text('👤 ${cd['text']}', textAlign: TextAlign.right)));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'المسبحة الإلكترونية',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _addNewCustomDhikr,
            tooltip: 'إضافة ذكر مخصص',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F7F5),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // لوحة تحديد الذكر والأهداف
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // اختيار الذكر الحالي
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedDhikr,
                              isExpanded: true,
                              underline: const SizedBox(),
                              alignment: Alignment.centerRight,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.amber[200] : primaryColor,
                              ),
                              items: dropdownItems,
                              onChanged: (val) {
                                if (val != null) {
                                  // التحقق من الهدف المخصص لهذا الذكر
                                  int target = 33;
                                  final cdIdx = _customDhikrs.indexWhere((element) => element['text'] == val);
                                  if (cdIdx != -1) {
                                    target = _customDhikrs[cdIdx]['target'] ?? 100;
                                  }
                                  setState(() {
                                    _selectedDhikr = val;
                                    _target = target;
                                    _counter = 0;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.auto_awesome, color: Colors.teal),
                        ],
                      ),
                      const Divider(height: 20),
                      // اختيار الهدف وتأثيرات الصوت والاهتزاز
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // أزرار سريعة لتغيير الهدف
                          Row(
                            children: [33, 100, 1000].map((t) {
                              final isSelected = _target == t;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: ChoiceChip(
                                  label: Text('$t'),
                                  selected: isSelected,
                                  selectedColor: primaryColor,
                                  backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[200],
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.black87),
                                  ),
                                  onSelected: (val) {
                                    if (val) {
                                      setState(() {
                                        _target = t;
                                        _counter = 0;
                                      });
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                          // أدوات الصوت والاهتزاز
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isSoundEnabled ? Icons.volume_up : Icons.volume_off,
                                  color: _isSoundEnabled ? Colors.teal : Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isSoundEnabled = !_isSoundEnabled;
                                  });
                                },
                                tooltip: 'تفعيل الصوت',
                              ),
                              IconButton(
                                icon: Icon(
                                  _isVibrationEnabled ? Icons.vibration : Icons.phone_android,
                                  color: _isVibrationEnabled ? Colors.teal : Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isVibrationEnabled = !_isVibrationEnabled;
                                  });
                                },
                                tooltip: 'تفعيل الاهتزاز',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // العداد الدائري اللمسي الرئيسي للتسبيح
              Center(
                child: AnimatedScale(
                  scale: _btnScale,
                  duration: const Duration(milliseconds: 80),
                  child: GestureDetector(
                    onTap: _incrementCounter,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark 
                              ? [const Color(0xFF0F5A47), const Color(0xFF073A2F)]
                              : [const Color(0xFF127F65), const Color(0xFF0A4F3E)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.08),
                            inset: true,
                            blurRadius: 8,
                            offset: const Offset(4, 4),
                          )
                        ],
                        border: Border.all(
                          color: accentColor.withOpacity(0.6),
                          width: 6,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_counter',
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Outfit',
                            ),
                          ),
                          Text(
                            'الهدف: $_target',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.teal[100],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Icon(
                            Icons.touch_app,
                            color: Colors.white54,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // أزرار التحكم بالعداد
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _resetCounter,
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة تعيين'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // لوحة الإحصائيات الأسبوعية
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'إحصائيات التسبيح الأسبوعية',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 20),
                      // رسم بياني بالأعمدة
                      SizedBox(
                        height: 120,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: weeklyStats.map((stat) {
                            final count = stat['count'] as int;
                            final percent = maxStatCount > 0 ? (count / maxStatCount).clamp(0.0, 1.0) : 0.0;
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  count > 0 ? '$count' : '',
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 14,
                                  height: (percent * 80).clamp(4.0, 80.0),
                                  decoration: BoxDecoration(
                                    color: count > 0 ? primaryColor : Colors.grey.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  stat['day'],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
