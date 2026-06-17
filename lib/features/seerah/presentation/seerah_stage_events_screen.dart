import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/seerah_service.dart';
import 'seerah_detail_screen.dart';

class SeerahStageEventsScreen extends StatefulWidget {
  final String stage;
  const SeerahStageEventsScreen({super.key, required this.stage});

  @override
  State<SeerahStageEventsScreen> createState() =>
      _SeerahStageEventsScreenState();
}

class _SeerahStageEventsScreenState extends State<SeerahStageEventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SeerahService _service = SeerahService();
  List<SeerahEvent> _filteredEvents = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _service.loadEvents();
    if (mounted) {
      setState(() {
        _filteredEvents = _service.getEventsByStage(widget.stage);
        _isLoading = false;
      });
    }
  }

  void _applySearch(String val) {
    setState(() {
      _searchQuery = val.trim();
      if (_searchQuery.isEmpty) {
        _filteredEvents = _service.getEventsByStage(widget.stage);
      } else {
        _filteredEvents = _service
            .searchEvents(_searchQuery)
            .where((e) => e.stage == widget.stage)
            .toList();
      }
    });
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
        title: Text(
          widget.stage,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Amiri',
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F4),
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: TextField(
                  controller: _searchController,
                  textAlign: TextAlign.right,
                  onChanged: _applySearch,
                  decoration: InputDecoration(
                    hintText: 'ابحث في هذا القسم من السيرة...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _applySearch('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),

            // Events List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: primaryColor))
                  : _filteredEvents.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'لا توجد أحداث في هذا القسم'
                                : 'لا توجد نتائج بحث مطابقة',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredEvents.length,
                          itemBuilder: (context, index) {
                            final event = _filteredEvents[index];
                            String snippet = event.content;
                            if (snippet.length > 120) {
                              snippet = '${snippet.substring(0, 120)}...';
                            }

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              color: isDark
                                  ? const Color(0xFF1E1E1E)
                                  : Colors.white,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          SeerahDetailScreen(event: event),
                                    ),
                                  ).then((_) => setState(() {}));
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: isDark
                                            ? const Color(0xFF1D3C34)
                                            : const Color(0xFFE8F3EF),
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? accentColor
                                                : primaryColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              event.title,
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? accentColor
                                                    : primaryColor,
                                                fontFamily: 'Amiri',
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              snippet,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: isDark
                                                    ? Colors.grey[400]
                                                    : Colors.grey[700],
                                                height: 1.5,
                                              ),
                                              textAlign: TextAlign.right,
                                              textDirection: TextDirection.rtl,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_back_ios,
                                        size: 14,
                                        color: Colors.grey,
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
