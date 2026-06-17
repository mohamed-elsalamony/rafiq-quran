import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/seerah_service.dart';
import 'seerah_stage_events_screen.dart';
import 'seerah_detail_screen.dart';

class SeerahScreen extends StatefulWidget {
  const SeerahScreen({super.key});

  @override
  State<SeerahScreen> createState() => _SeerahScreenState();
}

class _SeerahScreenState extends State<SeerahScreen> {
  final SeerahService _service = SeerahService();
  bool _isLoading = true;

  final List<Map<String, dynamic>> _stages = [
    {
      'name': 'مرحلة مكة',
      'icon': Icons.explore_outlined,
      'desc': 'من المولد والبعثة المباركة والجهر بالدعوة حتى الهجرة',
    },
    {
      'name': 'مرحلة الهجرة',
      'icon': Icons.trending_flat_rounded,
      'desc': 'أحداث الهجرة النبوية المباركة وتأسيس المدينة المنورة',
    },
    {
      'name': 'مرحلة المدينة',
      'icon': Icons.mosque_rounded,
      'desc': 'المجتمع المدني الجديد والتشريعات والأحداث الهامة',
    },
    {
      'name': 'الغزوات',
      'icon': Icons.shield_outlined,
      'desc': 'المعارك الفاصلة من بدر الكبرى إلى تبوك دفاعاً عن الدين',
    },
    {
      'name': 'فتح مكة وحجة الوداع',
      'icon': Icons.verified_outlined,
      'desc': 'دخول مكة والوفود وتمام النعمة وخطبة الوداع التاريخية',
    },
    {
      'name': 'الوفاة',
      'icon': Icons.hourglass_empty_rounded,
      'desc': 'مرض النبي ﷺ ووفاته ووداع سيد الخلق والبشر',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _service.loadEvents();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
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
        title: const Text(
          'السيرة النبوية المطهرة',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F4),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryColor))
            : Column(
                children: [
                  // Resume Reading Card
                  if (appState.lastSeerahEventId > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Card(
                        color: isDark
                            ? const Color(0xFF1B3D34)
                            : const Color(0xFFE8F3EF),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          onTap: () {
                            final event = _service
                                .getEventById(appState.lastSeerahEventId);
                            if (event != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SeerahDetailScreen(event: event),
                                ),
                              ).then((_) => setState(() {}));
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.play_circle_filled,
                                    color: accentColor, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'متابعة القراءة من حيث توقفت',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      FutureBuilder(
                                        future: _service.loadEvents().then(
                                            (_) => _service.getEventById(
                                                appState.lastSeerahEventId)),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData &&
                                              snapshot.data != null) {
                                            final event =
                                                snapshot.data as SeerahEvent;
                                            return Text(
                                              'قسم: ${event.stage} - ${event.title}',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark
                                                      ? Colors.grey[300]
                                                      : Colors.grey[600]),
                                            );
                                          }
                                          return const SizedBox();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_back_ios,
                                    size: 14, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Stages Grid
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _stages.length,
                      itemBuilder: (context, index) {
                        final stage = _stages[index];
                        final String name = stage['name'] as String;
                        final IconData icon = stage['icon'] as IconData;
                        final String desc = stage['desc'] as String;

                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          color:
                              isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SeerahStageEventsScreen(stage: name),
                                ),
                              ).then((_) => setState(() {}));
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: isDark
                                        ? const Color(0xFF1D3C34)
                                        : const Color(0xFFE8F3EF),
                                    child: Icon(
                                      icon,
                                      size: 30,
                                      color:
                                          isDark ? accentColor : primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: Text(
                                      desc,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                        height: 1.3,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
