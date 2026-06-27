import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/db_helper.dart';

class KhatmCelebrationScreen extends StatefulWidget {
  final bool isNewCompletion;

  static const String supplicationText = """
اللَّهُمَّ ارْحَمْنِي بالقُرْآنِ وَاجْعَلهُ لِي إِمَاماً وَنُوراً وَهُدًى وَرَحْمَةً، اللَّهُمَّ ذَكِّرْنِي مِنْهُ مَا نَسِيتُ وَعَلِّمْنِي مِنْهُ مَا جَهِلْتُ وَارْزُقْنِي تِلاَوَتَهُ آنَاءَ اللَّيْلِ وَأَطْرَافَ النَّهَارِ وَاجْعَلْهُ لِي حُجَّةً يَا رَبَّ العَالَمِينَ.

اللَّهُمَّ أَصْلِحْ لِي دِينِي الَّذِي هُوَ عِصْمَةُ أَمْرِي، وَأَصْلِحْ لِي دُنْيَايَ الَّتِي فِيهَا مَعَاشِي، وَأَصْلِحْ لِي آخِرَتِي الَّتِي فِيهَا مَعَادِي، وَاجْعَلِ الحَيَاةَ زِيَادَةً لِي فِي كُلِّ خَيْرٍ وَاجْعَلِ المَوْتَ رَاحَةً لِي مِنْ كُلِّ شَرٍّ.

اللَّهُمَّ اجْعَلْ خَيْرَ عُمْرِي آخِرَهُ وَخَيْرَ عَمَلِي خَوَاتِمَهُ وَخَيْرَ أَيَّامِي يَوْمَ أَلْقَاكَ فِيهِ.

اللَّهُمَّ إِنِّي أَسْأَلُكَ عِيشَةً هَنِيَّةً وَمِيتَةً سَوِيَّةً وَمَرَدًّا غَيْرَ مُخْزٍ وَلاَ فَاضِحٍ.

اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ المَسْأَلَةِ وَخَيْرَ الدُّعَاءِ وَخَيْرَ النَّجَاحِ وَخَيْرَ العِلْمِ وَخَيْرَ العَمَلِ وَخَيْرَ الثَّوَابِ وَخَيْرَ الحَيَاةِ وَخَيْرَ المَمَاتِ وَثَبِّتْنِي وَثَقِّلْ مَوَازِينِي وَحَقِّقْ إِيمَانِي وَارْفَعْ دَرَجَتِي وَتَقَبَّلْ صَلاَتِي وَاغْفِرْ خَطِيئَاتِي وَأَسْأَلُكَ الدَّرَجَاتِ العُلَى مِنَ الجَنَّةِ.

اللَّهُمَّ إِنِّي أَسْأَلُكَ مُوجِبَاتِ رَحْمَتِكَ وَعَزَائِمَ مَغْفِرَتِكَ وَالسَّلاَمَةَ مِنْ كُلِّ إِثْمٍ وَالغَنِيمَةَ مِنْ كُلِّ بِرٍّ وَالفَوْزَ بِالجَنَّةِ وَالنَّجَاةَ مِنَ النَّارِ.

اللَّهُمَّ أَحْسِنْ عَاقِبَتَنَا فِي الأُمُورِ كُلِّهَا، وَأَجِرْنَا مِنْ خِزْيِ الدُّنْيَا وَعَذَابِ الآخِرَةِ.

اللَّهُمَّ اقْسِمْ لَنَا مِنْ خَشْيَتِكَ مَا تَحُولُ بِهِ بَيْنَنَا وَبَيْنَ مَعْصِيَتِكَ وَمِنْ طَاعَتِكَ مَا تُبَلِّغُنَا بِهِ جَنَّتَكَ وَمِنَ اليَقِينِ مَا تُهَوِّنُ بِهِ عَلَيْنَا مَصَائِبَ الدُّنْيَا وَمَتِّعْنَا بِأَسْمَاعِنَا وَأَبْصَارِنَا وَقُوَّتِنَا مَا أَحْيَيْتَنَا وَاجْعَلْهُ الوَارِثَ مِنَّا وَاجْعَلْ ثَأْرَنَا عَلَى مَنْ ظَلَمَنَا وَانْصُرْنَا عَلَى مَنْ عَادَانَا وَلاَ تَجْعَلِ مُصِيبَتَنَا فِي دِينَنَا وَلاَ تَجْعَلِ الدُّنْيَا أَكْبَرَ هَمِّنَا وَلاَ مَبْلَغَ عِلْمِنَا وَلاَ تُسَلِّطْ عَلَيْنَا مَنْ لاَ يَرْحَمُنَا.
""";

  const KhatmCelebrationScreen({
    super.key,
    this.isNewCompletion = false,
  });

  @override
  State<KhatmCelebrationScreen> createState() => _KhatmCelebrationScreenState();
}

class _KhatmCelebrationScreenState extends State<KhatmCelebrationScreen> {
  bool _isSaved = false;
  List<Map<String, dynamic>> _khatmHistory = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _handleCompletionLog();
  }

  Future<void> _handleCompletionLog() async {
    if (widget.isNewCompletion && !_isSaved) {
      await DbHelper.addKhatmLog();
      setState(() {
        _isSaved = true;
      });
    }
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await DbHelper.getKhatmHistory();
    if (mounted) {
      setState(() {
        _khatmHistory = history.reversed.toList(); // Newest first
        _isLoadingHistory = false;
      });
    }
  }

  String _formatDateString(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final months = [
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر'
      ];
      final year = dt.year;
      final monthName = months[dt.month - 1];
      final day = dt.day;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day $monthName $year - الساعة $hour:$minute';
    } catch (_) {
      return isoString;
    }
  }

  void _shareSupplication() {
    final textToShare =
        "الحمد لله الذي بنعمته تتم الصالحات، أتممت ختم القرآن الكريم 🤲\n\n"
        "دعاء ختم القرآن:\n\n${KhatmCelebrationScreen.supplicationText}\n\n"
        "تمت الختمة عبر تطبيق رفيق القرآن الكريم 🕌";
    Share.share(textToShare);
  }

  void _copySupplication() {
    Clipboard.setData(
        const ClipboardData(text: KhatmCelebrationScreen.supplicationText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ نص دعاء الختم إلى الحافظة',
            textAlign: TextAlign.right),
        backgroundColor: Colors.teal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = appState.isDarkMode;
    const primaryColor = Color(0xFF0F5A47);
    const accentColor = Color(0xFFD4AF37);

    // Apply reader theme mode configuration to display text
    final themeMode = appState.quranThemeMode;
    Color containerBgColor;
    Color textColor;
    if (themeMode == 'dark') {
      containerBgColor = const Color(0xFF1E1E1E);
      textColor = Colors.grey[200]!;
    } else if (themeMode == 'sepia') {
      containerBgColor = const Color(0xFFF4ECD8);
      textColor = const Color(0xFF5B4636);
    } else {
      containerBgColor = const Color(0xFFFDFBF7);
      textColor = Colors.black87;
    }

    TextStyle contentTextStyle;
    if (appState.quranFontFamily == 'Scheherazade') {
      contentTextStyle = GoogleFonts.scheherazadeNew(
        fontSize: appState.fontSize + 4,
        height: 1.8,
        color: textColor,
      );
    } else {
      contentTextStyle = GoogleFonts.amiri(
        fontSize: appState.fontSize,
        height: 1.8,
        color: textColor,
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF4F7F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'دعاء ختم القرآن الكريم',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Celebratory Top Card
            if (widget.isNewCompletion)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                color:
                    isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE8F3EE),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(Icons.stars, size: 50, color: accentColor),
                      const SizedBox(height: 12),
                      const Text(
                        'مبارك ختم كتاب الله 🌸',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                          fontFamily: 'Amiri',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'هنيئاً لك ختم كتاب الله عز وجل. نسأل الله أن يجعله ربيعاً لقلبك، ونوراً لصدرك، وشفيعاً لك يوم القيامة.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : primaryColor,
                          height: 1.5,
                          fontFamily: 'Amiri',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Supplication Content Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: containerBgColor,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book, color: accentColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'الأدعية المأثورة للختم',
                          style: GoogleFonts.amiri(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    SelectableText(
                      KhatmCelebrationScreen.supplicationText,
                      style: contentTextStyle,
                      textAlign: TextAlign.justify,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _shareSupplication,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('مشاركة الدعاء',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        OutlinedButton.icon(
                          onPressed: _copySupplication,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: const BorderSide(color: primaryColor),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('نسخ الدعاء',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // History Registry Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'إجمالي الختمات: ${_khatmHistory.length}',
                            style: const TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const Row(
                          children: [
                            Text(
                              'سجل الختمات السابقة',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.history, color: accentColor),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _isLoadingHistory
                        ? const Center(child: CircularProgressIndicator())
                        : _khatmHistory.isEmpty
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16.0),
                                child: Text(
                                  'لا يوجد ختمات مسجلة بعد.',
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _khatmHistory.length,
                                itemBuilder: (context, index) {
                                  final log = _khatmHistory[index];
                                  final numLabel = _khatmHistory.length - index;
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          primaryColor.withOpacity(0.1),
                                      foregroundColor: primaryColor,
                                      radius: 14,
                                      child: Text(
                                        '$numLabel',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    title: Text(
                                      _formatDateString(log['date'] ?? ''),
                                      style: const TextStyle(fontSize: 13),
                                      textAlign: TextAlign.right,
                                    ),
                                    trailing: const Icon(Icons.check_circle,
                                        color: Colors.green, size: 18),
                                  );
                                },
                              ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
