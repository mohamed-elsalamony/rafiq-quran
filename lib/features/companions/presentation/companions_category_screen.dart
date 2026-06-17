import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/app_state.dart';
import '../../../core/services/companions_service.dart';
import 'companion_detail_screen.dart';

class CompanionsCategoryScreen extends StatefulWidget {
  final String categoryName;
  const CompanionsCategoryScreen({super.key, required this.categoryName});

  @override
  State<CompanionsCategoryScreen> createState() =>
      _CompanionsCategoryScreenState();
}

class _CompanionsCategoryScreenState extends State<CompanionsCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CompanionsService _service = CompanionsService();
  List<Companion> _filteredCompanions = [];
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
    await _service.loadCompanions();
    if (mounted) {
      setState(() {
        _filteredCompanions =
            _service.getCompanionsByCategory(widget.categoryName);
        _isLoading = false;
      });
    }
  }

  void _applySearch(String val) {
    setState(() {
      _searchQuery = val.trim();
      _filteredCompanions = _service.searchCompanions(_searchQuery,
          category: widget.categoryName);
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
          widget.categoryName,
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
                    hintText: 'ابحث عن صحابي في هذا القسم...',
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

            // Main List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: primaryColor))
                  : _filteredCompanions.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'لا يوجد صحابة في هذا القسم'
                                : 'لا توجد نتائج بحث مطابقة',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredCompanions.length,
                          itemBuilder: (context, index) {
                            final companion = _filteredCompanions[index];
                            // Create a short description snippet for the card
                            String snippet = companion.lineage;
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
                                          CompanionDetailScreen(
                                              companion: companion),
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
                                              companion.name,
                                              style: TextStyle(
                                                fontSize: 18,
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
