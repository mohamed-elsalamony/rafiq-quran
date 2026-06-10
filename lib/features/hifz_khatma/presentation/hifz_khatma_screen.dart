import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran;
import '../../../core/services/app_state.dart';
import '../../../core/services/db_helper.dart';

class HifzKhatmaScreen extends StatefulWidget {
  const HifzKhatmaScreen({super.key});

  @override
  State<HifzKhatmaScreen> createState() => _HifzKhatmaScreenState();
}

class _HifzKhatmaScreenState extends State<HifzKhatmaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _khatmaPlans = [];
  List<Map<String, dynamic>> _hifzPlans = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPlans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadPlans() async {
    final khatmas = await DbHelper.getKhatmaPlans();
    final hifz = await DbHelper.getHifzPlans();
    if (mounted) {
      setState(() {
        _khatmaPlans = khatmas;
        _hifzPlans = hifz;
      });
    }
  }

  // --- حوار إنشاء خطة ختمة ---
  void _createNewKhatmaPlan() {
    final titleController = TextEditingController(text: 'ختمتي الخاصة');
    final durationController = TextEditingController(text: '30');
    final startPageController = TextEditingController(text: '1');
    final endPageController = TextEditingController(text: '604');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إنشاء خطة ختمة جديدة', textAlign: TextAlign.right),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(labelText: 'اسم الختمة'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(labelText: 'المدة بالأيام (مثلاً: 30 يوماً)'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: endPageController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(labelText: 'إلى صفحة'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: startPageController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(labelText: 'من صفحة'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F5A47)),
            onPressed: () async {
              final title = titleController.text.trim();
              final duration = int.tryParse(durationController.text) ?? 30;
              final start = int.tryParse(startPageController.text) ?? 1;
              final end = int.tryParse(endPageController.text) ?? 604;
              
              if (title.isNotEmpty && end >= start) {
                await DbHelper.addKhatmaPlan(
                  title: title,
                  daysDuration: duration,
                  startPage: start,
                  endPage: end,
                );
                _loadPlans();
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- حوار إنشاء خطة حفظ ---
  void _createNewHifzPlan() {
    final titleController = TextEditingController(text: 'خطة حفظ جزء عمَّ');
    final dailyTargetController = TextEditingController(text: '5');
    int startSurah = 78; // النبأ
    int endSurah = 114;  // الناس

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إنشاء خطة حفظ جديدة', textAlign: TextAlign.right),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'اسم خطة الحفظ'),
                ),
                const SizedBox(height: 16),
                // تحديد سورة البداية وسورة النهاية
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DropdownButton<int>(
                      value: endSurah,
                      items: List.generate(114, (i) => i + 1).map((sNum) {
                        return DropdownMenuItem(value: sNum, child: Text(quran.getSurahNameArabic(sNum)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => endSurah = val);
                        }
                      },
                    ),
                    const Text('إلى سورة:'),
                    DropdownButton<int>(
                      value: startSurah,
                      items: List.generate(114, (i) => i + 1).map((sNum) {
                        return DropdownMenuItem(value: sNum, child: Text(quran.getSurahNameArabic(sNum)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => startSurah = val);
                        }
                      },
                    ),
                    const Text('من سورة:'),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dailyTargetController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(labelText: 'الورد اليومي (عدد الآيات)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F5A47)),
            onPressed: () async {
              final title = titleController.text.trim();
              final target = int.tryParse(dailyTargetController.text) ?? 5;
              
              // حساب إجمالي الآيات المراد حفظها
              int total = 0;
              for (int s = startSurah; s <= endSurah; s++) {
                total += quran.getVerseCount(s);
              }

              if (title.isNotEmpty && endSurah >= startSurah) {
                await DbHelper.addHifzPlan(
                  title: title,
                  startSurah: startSurah,
                  endSurah: endSurah,
                  totalAyahs: total,
                  dailyTarget: target,
                );
                _loadPlans();
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _updateKhatmaPage(String planId, int curPage, int endPage) async {
    if (curPage < endPage) {
      await DbHelper.updateKhatmaProgress(planId, curPage + 1);
      _loadPlans();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تهانينا! لقد أتممت هذه الختمة بالكامل مبارك لك! 🎉')),
      );
    }
  }

  void _updateHifzProgress(String planId, int curProgress, int total) async {
    if (curProgress < total) {
      await DbHelper.updateHifzProgress(planId, curProgress + 1);
      _loadPlans();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أحسنت! أتممت حفظ هذه الخطة بالكامل جعله الله شفيعاً لك! 🌟')),
      );
    }
  }

  void _deletePlan(String id, bool isKhatma) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isKhatma ? 'حذف خطة الختمة' : 'حذف خطة الحفظ',
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Text(
          isKhatma 
              ? 'هل أنت متأكد من رغبتك في حذف خطة الختمة هذه؟ سيتم مسح كل التقدم المرتبط بها.'
              : 'هل أنت متأكد من رغبتك في حذف خطة الحفظ هذه؟ سيتم مسح كل التقدم المرتبط بها.',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
            onPressed: () async {
              Navigator.pop(context);
              if (isKhatma) {
                await DbHelper.deleteKhatmaPlan(id);
              } else {
                await DbHelper.deleteHifzPlan(id);
              }
              _loadPlans();
            },
            child: const Text('نعم، احذف', style: TextStyle(color: Colors.white)),
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
          'الورد والحفظ والختمات',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: accentColor,
          unselectedLabelColor: Colors.white70,
          indicatorColor: accentColor,
          tabs: const [
            Tab(text: 'الختمات القرآنيّة'),
            Tab(text: 'خطط الحفظ والمراجعة'),
          ],
        ),
      ),
      body: Container(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F4),
        child: TabBarView(
          controller: _tabController,
          children: [
            // تبويب الختمة
            _buildKhatmaTab(isDark, primaryColor, accentColor),
            // تبويب الحفظ
            _buildHifzTab(isDark, primaryColor, accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildKhatmaTab(bool isDark, Color primaryColor, Color accentColor) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _createNewKhatmaPlan,
            icon: const Icon(Icons.add),
            label: const Text('إنشاء خطة ختمة جديدة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: _khatmaPlans.isEmpty
              ? Center(
                  child: Text(
                    'لا توجد خطط ختمة نشطة حالياً.',
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _khatmaPlans.length,
                  itemBuilder: (context, index) {
                    final plan = _khatmaPlans[index];
                    final total = plan['endPage'] - plan['startPage'] + 1;
                    final current = plan['currentPage'] - plan['startPage'] + 1;
                    final double percent = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
                    
                    // حساب الصفحات المطلوبة يومياً
                    final dailyTarget = (total / (plan['daysDuration'] ?? 30)).ceil();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _deletePlan(plan['id'], true),
                                ),
                                Text(
                                  plan['title'] ?? 'ختمة القرآن الكبرى',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: percent,
                                minHeight: 10,
                                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${(percent * 100).toInt()}% منجز',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: accentColor),
                                ),
                                Text(
                                  'الهدف اليومي: $dailyTarget صفحات',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton.icon(
                                  style: TextButton.styleFrom(foregroundColor: primaryColor),
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('قراءة صفحة جديدة'),
                                  onPressed: () => _updateKhatmaPage(plan['id'], plan['currentPage'], plan['endPage']),
                                ),
                                Text(
                                  'الصفحة الحالية: ${plan['currentPage']} من ${plan['endPage']}',
                                  style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHifzTab(bool isDark, Color primaryColor, Color accentColor) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _createNewHifzPlan,
            icon: const Icon(Icons.add_task),
            label: const Text('إنشاء خطة حفظ جديدة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: _hifzPlans.isEmpty
              ? Center(
                  child: Text(
                    'لا توجد خطط حفظ نشطة حالياً.',
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _hifzPlans.length,
                  itemBuilder: (context, index) {
                    final plan = _hifzPlans[index];
                    final current = plan['currentProgress'] as int;
                    final total = plan['totalAyahs'] as int;
                    final double percent = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _deletePlan(plan['id'], false),
                                ),
                                Text(
                                  plan['title'] ?? 'خطة حفظ جديدة',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: percent,
                                minHeight: 10,
                                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'تم حفظ $current من أصل $total آية (${(percent * 100).toInt()}%)',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 12),
                                ),
                                Text(
                                  'المستهدف: ${plan['dailyTarget']} آيات/يوم',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton.icon(
                                  style: TextButton.styleFrom(foregroundColor: accentColor),
                                  icon: const Icon(Icons.add_task),
                                  label: const Text('حفظ آية جديدة'),
                                  onPressed: () => _updateHifzProgress(plan['id'], current, total),
                                ),
                                Text(
                                  'النطاق: ${quran.getSurahNameArabic(plan['startSurah'])} - ${quran.getSurahNameArabic(plan['endSurah'])}',
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
