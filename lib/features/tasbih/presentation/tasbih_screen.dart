import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_state.dart';
import 'tasbih_provider.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen>
    with TickerProviderStateMixin {
  bool _isInit = false;
  late AnimationController _pulseCtrl;
  late AnimationController _completionCtrl;
  late Animation<double> _completionScale;

  static const _primary = Color(0xFF0F5A47);
  static const _accent = Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _completionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _completionScale = Tween<double>(begin: 1.0, end: 1.06)
        .animate(CurvedAnimation(
            parent: _completionCtrl, curve: Curves.elasticOut));
  }

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
    _pulseCtrl.dispose();
    _completionCtrl.dispose();
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
      // Target completed!
      HapticFeedback.heavyImpact();
      _completionCtrl.forward(from: 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && provider.alertMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded,
                      color: Color(0xFFD4AF37), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    provider.alertMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              backgroundColor: Colors.teal.shade800,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
          provider.clearAlert();
        }
      });
    }
  }

  void _showResetConfirmation(BuildContext context, TasbihProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد إعادة التعيين',
            textAlign: TextAlign.right,
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'هل أنت متأكد من رغبتك في إعادة تعيين عداد التسبيح إلى الصفر؟',
            textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade900,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              provider.reset();
              Navigator.pop(context);
            },
            child: const Text('نعم، تصفير'),
          ),
        ],
      ),
    );
  }

  void _addNewCustomDhikr(TasbihProvider provider) {
    final textController = TextEditingController();
    final targetController = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إضافة ذكر مخصص', textAlign: TextAlign.right),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'اكتب الذكر هنا...',
                labelText: 'نص الذكر',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'العدد المستهدف',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
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
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                final target = int.tryParse(targetController.text) ?? 100;
                await provider.addNewCustomDhikr(text, target);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
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

    final weeklyStats = tasbihProvider.getWeeklyStats();
    final maxStatCount = weeklyStats
        .map<int>((e) => e['count'] as int)
        .fold(0, (max, e) => e > max ? e : max);

    final double progress = tasbihProvider.target > 0
        ? (tasbihProvider.counter / tasbihProvider.target).clamp(0.0, 1.0)
        : 0.0;
    final bool isTargetReached = tasbihProvider.counter >= tasbihProvider.target;

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
      backgroundColor:
          isDark ? const Color(0xFF0E1A17) : const Color(0xFFF2F5F3),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF0E1A17) : _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'المسبحة الإلكترونية',
          style: GoogleFonts.amiri(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _addNewCustomDhikr(tasbihProvider),
            tooltip: 'إضافة ذكر مخصص',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Dhikr selector card ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF182420) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.07)
                      : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  // Dhikr dropdown
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child:
                            const Icon(Icons.auto_awesome, color: _primary, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButton<String>(
                          value: tasbihProvider.selectedDhikr,
                          isExpanded: true,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.keyboard_arrow_down,
                              color: Colors.grey),
                          alignment: Alignment.centerRight,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.amber[200] : _primary,
                            fontFamily: 'Amiri',
                          ),
                          items: dropdownItems,
                          onChanged: (val) {
                            if (val != null) tasbihProvider.setDhikr(val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Target chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [33, 100, 1000].map((t) {
                      final isSelected = tasbihProvider.target == t;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: GestureDetector(
                          onTap: () => tasbihProvider.setTarget(t),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _primary
                                  : (isDark
                                      ? const Color(0xFF1E2D28)
                                      : Colors.grey[100]),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? _primary
                                    : (isDark
                                        ? Colors.white12
                                        : Colors.grey.shade300),
                              ),
                            ),
                            child: Text(
                              '$t',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white60
                                        : Colors.black54),
                                fontFamily: 'Outfit',
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),

                  // Sound/Vibration controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ControlButton(
                        icon: tasbihProvider.isSoundEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        label: 'الصوت',
                        isActive: tasbihProvider.isSoundEnabled,
                        onTap: tasbihProvider.toggleSound,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 16),
                      _ControlButton(
                        icon: tasbihProvider.isVibrationEnabled
                            ? Icons.vibration_rounded
                            : Icons.phone_android_rounded,
                        label: 'الاهتزاز',
                        isActive: tasbihProvider.isVibrationEnabled,
                        onTap: tasbihProvider.toggleVibration,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Main counter button with progress ring ──
            Center(
              child: ScaleTransition(
                scale: _completionScale,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    tasbihProvider.increment();
                  },
                  child: SizedBox(
                    width: 240,
                    height: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Progress ring
                        SizedBox(
                          width: 240,
                          height: 240,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: progress),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            builder: (_, v, __) => CustomPaint(
                              painter: _RingPainter(
                                progress: v,
                                color: isTargetReached
                                    ? Colors.green.shade400
                                    : _accent,
                                bgColor: isDark
                                    ? Colors.white.withOpacity(0.07)
                                    : Colors.grey.shade200,
                              ),
                            ),
                          ),
                        ),
                        // Main button circle
                        AnimatedScale(
                          scale: tasbihProvider.btnScale,
                          duration: const Duration(milliseconds: 80),
                          child: Container(
                            width: 190,
                            height: 190,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isTargetReached
                                    ? [Colors.green.shade700, Colors.green.shade900]
                                    : isDark
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
                                  color: (isTargetReached
                                          ? Colors.green
                                          : _primary)
                                      .withOpacity(0.5),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 150),
                                  child: Text(
                                    '${tasbihProvider.counter}',
                                    key: ValueKey(tasbihProvider.counter),
                                    style: GoogleFonts.outfit(
                                      fontSize: 56,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isTargetReached
                                      ? 'اكتملت! 🌟'
                                      : 'الهدف: ${tasbihProvider.target}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.75),
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Amiri',
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Icon(
                                  isTargetReached
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.touch_app_rounded,
                                  color: Colors.white.withOpacity(0.5),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
            // Progress text
            Center(
              child: Text(
                '${tasbihProvider.counter} / ${tasbihProvider.target} • ${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontFamily: 'Outfit',
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Reset button ──
            Center(
              child: OutlinedButton.icon(
                onPressed: () =>
                    _showResetConfirmation(context, tasbihProvider),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('إعادة تعيين'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300, width: 1.2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Weekly stats ──
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF182420) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.07)
                      : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.bar_chart_rounded,
                            color: _accent, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'إحصائيات الأسبوع',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 120,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: weeklyStats.asMap().entries.map((entry) {
                        final stat = entry.value;
                        final count = stat['count'] as int;
                        final percent = maxStatCount > 0
                            ? (count / maxStatCount).clamp(0.0, 1.0)
                            : 0.0;
                        final isToday = entry.key == weeklyStats.length - 1;

                        return Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (count > 0)
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: isToday
                                          ? _accent
                                          : (isDark
                                              ? Colors.white54
                                              : Colors.black54),
                                    ),
                                  ),
                                )
                              else
                                const SizedBox(height: 12),
                              const SizedBox(height: 4),
                              TweenAnimationBuilder<double>(
                                tween: Tween(
                                    begin: 0.0,
                                    end: (percent * 80).clamp(4.0, 80.0)),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOut,
                                builder: (_, h, __) => Container(
                                  width: 16,
                                  height: h,
                                  decoration: BoxDecoration(
                                    color: count > 0
                                        ? (isToday
                                            ? _accent
                                            : _primary.withOpacity(0.6))
                                        : Colors.grey.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  stat['day'],
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isToday
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isToday
                                        ? _primary
                                        : (isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600]),
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
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Control Button
// ══════════════════════════════════════════════════════════════
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.isDark,
  });

  static const _primary = Color(0xFF0F5A47);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? _primary.withOpacity(0.1)
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? _primary.withOpacity(0.3)
                : (isDark ? Colors.white12 : Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? _primary : (isDark ? Colors.white38 : Colors.grey),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color:
                    isActive ? _primary : (isDark ? Colors.white38 : Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Ring Painter
// ══════════════════════════════════════════════════════════════
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 7.0;

    // Background ring
    final bgPaint = Paint()
      ..color = bgColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2, // Start from top
        2 * pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
