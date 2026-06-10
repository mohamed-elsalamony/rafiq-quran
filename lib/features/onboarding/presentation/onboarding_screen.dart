import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/app_state.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'مرحباً بك في رفيق القرآن',
      'description': 'رفيقك الأمثل لقراءة وتدبر آيات كتاب الله الكريم بتصميم متناسق وتجربة قراءة مريحة وهادئة.',
      'icon': Icons.menu_book_rounded,
      'color': const Color(0xFF0F5A47),
    },
    {
      'title': 'تلاوات عذبة وتفاسير ميسرة',
      'description': 'استمع لكبار القراء مع ميزة المتابعة الذكية، واطلع على تفسير الآيات وتدبرها بلمسة واحدة.',
      'icon': Icons.music_note_rounded,
      'color': const Color(0xFF156E58),
    },
    {
      'title': 'الختمات والأذكار اليومية',
      'description': 'نظم أورادك اليومية وأذكارك، وتابع تقدم ختمتك وحفظك للمصحف الشريف خطوة بخطوة وبكل سهولة.',
      'icon': Icons.assignment_turned_in_rounded,
      'color': const Color(0xFF1C826A),
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onFinish() async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.completeOnboarding();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF0F5A47);
    final Color accentColor = const Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1412) : const Color(0xFFF9FBF9),
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _onFinish,
                  child: Text(
                    'تخطي',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (idx) {
                  setState(() {
                    _currentPage = idx;
                  });
                },
                itemBuilder: (context, idx) {
                  final slide = _slides[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(36),
                          decoration: BoxDecoration(
                            color: slide['color'].withOpacity(0.08),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accentColor.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            slide['icon'],
                            size: 100,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          slide['title'],
                          style: GoogleFonts.amiri(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide['description'],
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicator and Navigation
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Next / Finish Button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _onFinish();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: accentColor.withOpacity(0.5)),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      _currentPage == _slides.length - 1 ? 'ابدأ الآن' : 'التالي',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),

                  // Indicator dots
                  Row(
                    children: List.generate(_slides.length, (idx) {
                      final isSelected = _currentPage == idx;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        width: isSelected ? 24.0 : 8.0,
                        height: 8.0,
                        decoration: BoxDecoration(
                          color: isSelected ? accentColor : (isDark ? Colors.grey[700] : Colors.grey[300]),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      );
                    }).toList(),
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
