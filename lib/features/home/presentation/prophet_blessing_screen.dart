import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/prophet_blessing_service.dart';

class ProphetBlessingScreen extends StatefulWidget {
  const ProphetBlessingScreen({super.key});

  @override
  State<ProphetBlessingScreen> createState() => _ProphetBlessingScreenState();
}

class _ProphetBlessingScreenState extends State<ProphetBlessingScreen>
    with SingleTickerProviderStateMixin {
  int _targetGoal = 100;
  bool _isSoundEnabled = true;
  bool _isVibrationEnabled = true;
  double _btnScale = 1.0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatNumber(int number) {
    // Custom Arabic digit formatting or comma formatting
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  void _handleBlessing(ProphetBlessingService service) {
    setState(() {
      _btnScale = 0.92;
    });

    // Increment counter
    service.increment();

    // Trigger haptic & audio
    if (_isVibrationEnabled) {
      HapticFeedback.lightImpact();
    }
    if (_isSoundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }

    // Goal reached celebration
    final currentPersonal = service.personalCount +
        1; // plus 1 because the state will update asynchronously
    if (currentPersonal % _targetGoal == 0) {
      if (_isVibrationEnabled) {
        HapticFeedback.vibrate();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تقبل الله منك! حققت هدفك الحالي ($_targetGoal صلاة على النبي ﷺ).',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontFamily: 'Amiri'),
          ),
          backgroundColor: const Color(0xFF0F5A47),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _btnScale = 1.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final service = Provider.of<ProphetBlessingService>(context);
    final isDark = appState.isDarkMode;

    final Color primaryColor = const Color(0xFF0F5A47);
    final Color accentColor = const Color(0xFFD4AF37);
    final Color cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final progress = (service.personalCount % _targetGoal) / _targetGoal;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: const Text(
            'مليونية الصلاة على النبي ﷺ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Amiri',
              fontSize: 18,
            ),
          ),
        ),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.track_changes),
            tooltip: 'تغيير الهدف اليومي',
            onSelected: (value) {
              setState(() {
                _targetGoal = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 33,
                  child: Text('الهدف: 33 صلاة', textAlign: TextAlign.right)),
              const PopupMenuItem(
                  value: 100,
                  child: Text('الهدف: 100 صلاة', textAlign: TextAlign.right)),
              const PopupMenuItem(
                  value: 500,
                  child: Text('الهدف: 500 صلاة', textAlign: TextAlign.right)),
              const PopupMenuItem(
                  value: 1000,
                  child: Text('الهدف: 1000 صلاة', textAlign: TextAlign.right)),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F2520), const Color(0xFF0B1412)]
                : [const Color(0xFFF0F5F2), const Color(0xFFFAFBF9)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner/Header
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF0A3C30), const Color(0xFF06241D)]
                          : [primaryColor, const Color(0xFF0A3E31)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accentColor.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'قال رسول الله ﷺ:',
                        style: TextStyle(
                          fontSize: 13,
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Amiri',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '«مَنْ صَلَّى عَلَيَّ صَلَاةً وَاحِدَةً صَلَّى اللهُ عَلَيْهِ بِهَا عَشْرًا»',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Amiri',
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Global Counter Card
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withOpacity(0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: service.isUsingFirebase
                                      ? Colors.green
                                      : accentColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (service.isUsingFirebase
                                              ? Colors.green
                                              : accentColor)
                                          .withOpacity(
                                              0.5 * _pulseController.value),
                                      blurRadius: 8 * _pulseController.value,
                                      spreadRadius: 3 * _pulseController.value,
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            service.isUsingFirebase
                                ? 'العداد العالمي (مباشر)'
                                : 'العداد العالمي (محاكاة نشطة)',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _formatNumber(service.globalCount),
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                            fontFamily: 'Outfit',
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'إجمالي صلوات المشاركين في الحملة',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[550] : Colors.grey[650],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Interactive Tap Button & Progress Ring
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glowing aura
                      Container(
                        width: 230,
                        height: 230,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor.withOpacity(0.04),
                        ),
                      ),
                      // Progress Indicator
                      SizedBox(
                        width: 190,
                        height: 190,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 10,
                          backgroundColor: isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.grey[200]!,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(accentColor),
                        ),
                      ),
                      // Inner Clickable Circle
                      GestureDetector(
                        onTap: () => _handleBlessing(service),
                        child: AnimatedScale(
                          scale: _btnScale,
                          duration: const Duration(milliseconds: 100),
                          curve: Curves.easeOutBack,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        const Color(0xFF104A3C),
                                        const Color(0xFF092E25)
                                      ]
                                    : [primaryColor, const Color(0xFF0A4436)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.4),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                              border: Border.all(
                                color: accentColor.withOpacity(0.8),
                                width: 2,
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
                                      'ﷺ',
                                      style: TextStyle(
                                        fontSize: 52,
                                        color: accentColor,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Amiri',
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'صَلِّ على النبي',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${service.personalCount}',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Outfit',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'هدفك اليومي الحالي: $_targetGoal صلاة',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Control panel styled as Card inside ScrollView
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  color: cardBgColor,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Vibration Toggle
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isVibrationEnabled
                                      ? Icons.vibration
                                      : Icons.videogame_asset_off_outlined,
                                  color: _isVibrationEnabled
                                      ? primaryColor
                                      : Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isVibrationEnabled = !_isVibrationEnabled;
                                  });
                                },
                              ),
                              Text(
                                'الاهتزاز',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // Sound Toggle
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isSoundEnabled
                                      ? Icons.volume_up
                                      : Icons.volume_off,
                                  color: _isSoundEnabled
                                      ? primaryColor
                                      : Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isSoundEnabled = !_isSoundEnabled;
                                  });
                                },
                              ),
                              Text(
                                'الصوت',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // Reset Button
                          TextButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('تصفير العداد',
                                      textAlign: TextAlign.right),
                                  content: const Text(
                                    'هل تريد تصفير عدادك الشخصي الحالي؟ (لن يؤثر ذلك على العداد العالمي)',
                                    textAlign: TextAlign.right,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('إلغاء'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await service.resetPersonalCount();
                                      },
                                      child: const Text('تصفير العداد',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.refresh,
                                color: Colors.red, size: 18),
                            label: const Text('تصفير',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 100), // navigation clearance
              ],
            ),
          ),
        ),
      ),
    );
  }
}
