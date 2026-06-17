import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_state.dart';
import 'tasbih_provider.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final tasbihProvider =
          Provider.of<TasbihProvider>(context, listen: false);
      tasbihProvider.addListener(_onProviderChange);
      _isInit = true;
    }
  }

  @override
  void dispose() {
    try {
      final tasbihProvider =
          Provider.of<TasbihProvider>(context, listen: false);
      tasbihProvider.removeListener(_onProviderChange);
    } catch (_) {}
    super.dispose();
  }

  void _onProviderChange() {
    if (!mounted) return;
    final provider = Provider.of<TasbihProvider>(context, listen: false);

    if (provider.alertMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && provider.alertMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                provider.alertMessage!,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.teal.shade800,
              duration: const Duration(seconds: 2),
            ),
          );
          provider.clearAlert();
        }
      });
    }
  }

  // --- Dialog helper to reset counter with confirmation ---
  void _showResetConfirmation(BuildContext context, TasbihProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد إعادة التعيين',
            textAlign: TextAlign.right,
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'هل أنت متأكد من رغبتك في إعادة تعيين عداد التسبيح الحالي إلى الصفر؟',
            textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
            onPressed: () {
              provider.reset();
              Navigator.pop(context);
            },
            child:
                const Text('نعم، تصفير', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- Dialog helper to add custom Zekr ---
  void _addNewCustomDhikr(TasbihProvider provider) {
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
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F5A47)),
            onPressed: () async {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                final target = int.tryParse(targetController.text) ?? 100;
                await provider.addNewCustomDhikr(text, target);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('إضافة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final tasbihProvider = Provider.of<TasbihProvider>(context);
    final isDark = appState.isDarkMode;
    final primaryColor = const Color(0xFF0F5A47);
    final Color accentColor = const Color(0xFFD4AF37);

    final weeklyStats = tasbihProvider.getWeeklyStats();
    final maxStatCount = weeklyStats
        .map<int>((e) => e['count'] as int)
        .fold(0, (max, e) => e > max ? e : max);

    // Merge predefined & custom list items
    List<DropdownMenuItem<String>> dropdownItems = [];
    for (var d in tasbihProvider.predefinedDhikrs) {
      dropdownItems.add(DropdownMenuItem(
          value: d, child: Text(d, textAlign: TextAlign.right)));
    }
    for (var cd in tasbihProvider.customDhikrs) {
      dropdownItems.add(DropdownMenuItem(
          value: cd['text'],
          child: Text('👤 ${cd['text']}', textAlign: TextAlign.right)));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : primaryColor,
        foregroundColor: Colors.white,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: const Text(
            'المسبحة الإلكترونية',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
              fontSize: 16,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _addNewCustomDhikr(tasbihProvider),
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
              // Zekr selector and options panel
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Selected Zekr selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.keyboard_arrow_down,
                              color: Colors.grey),
                          Expanded(
                            child: DropdownButton<String>(
                              value: tasbihProvider.selectedDhikr,
                              isExpanded: true,
                              underline: const SizedBox(),
                              alignment: Alignment.centerRight,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDark ? Colors.amber[200] : primaryColor,
                              ),
                              items: dropdownItems,
                              onChanged: (val) {
                                if (val != null) {
                                  tasbihProvider.setDhikr(val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.auto_awesome, color: Colors.teal),
                        ],
                      ),
                      const Divider(height: 20),
                      // Target chips & vibration/sound control
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [33, 100, 1000].map((t) {
                              final isSelected = tasbihProvider.target == t;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                child: ChoiceChip(
                                  label: Text('$t'),
                                  selected: isSelected,
                                  selectedColor: primaryColor,
                                  backgroundColor: isDark
                                      ? const Color(0xFF2C2C2C)
                                      : Colors.grey[200],
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.grey[300]
                                            : Colors.black87),
                                  ),
                                  onSelected: (val) {
                                    if (val) {
                                      tasbihProvider.setTarget(t);
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(
                                  tasbihProvider.isSoundEnabled
                                      ? Icons.volume_up
                                      : Icons.volume_off,
                                  color: tasbihProvider.isSoundEnabled
                                      ? Colors.teal
                                      : Colors.grey,
                                ),
                                onPressed: tasbihProvider.toggleSound,
                                tooltip: 'تفعيل الصوت',
                              ),
                              const SizedBox(width: 24),
                              IconButton(
                                icon: Icon(
                                  tasbihProvider.isVibrationEnabled
                                      ? Icons.vibration
                                      : Icons.phone_android,
                                  color: tasbihProvider.isVibrationEnabled
                                      ? Colors.teal
                                      : Colors.grey,
                                ),
                                onPressed: tasbihProvider.toggleVibration,
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

              // Interactive central click button
              Center(
                child: AnimatedScale(
                  scale: tasbihProvider.btnScale,
                  duration: const Duration(milliseconds: 80),
                  child: GestureDetector(
                    onTap: tasbihProvider.increment,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xFF0F5A47),
                                  const Color(0xFF073A2F)
                                ]
                              : [
                                  const Color(0xFF127F65),
                                  const Color(0xFF0A4F3E)
                                ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(4, 4),
                          )
                        ],
                        border: Border.all(
                          color: accentColor.withOpacity(0.6),
                          width: 6,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${tasbihProvider.counter}',
                                style: const TextStyle(
                                  fontSize: 60,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Outfit',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'الهدف: ${tasbihProvider.target}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.teal[100],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Icon(
                                Icons.touch_app,
                                color: Colors.white54,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () =>
                        _showResetConfirmation(context, tasbihProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة تعيين'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Weekly statistics chart panel
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'إحصائيات التسبيح الأسبوعية',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 140,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: weeklyStats.map((stat) {
                            final count = stat['count'] as int;
                            final percent = maxStatCount > 0
                                ? (count / maxStatCount).clamp(0.0, 1.0)
                                : 0.0;
                            return Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  count > 0
                                      ? FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            '$count',
                                            style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        )
                                      : const SizedBox(height: 11),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 14,
                                    height: (percent * 80).clamp(4.0, 80.0),
                                    decoration: BoxDecoration(
                                      color: count > 0
                                          ? primaryColor
                                          : Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      stat['day'],
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
