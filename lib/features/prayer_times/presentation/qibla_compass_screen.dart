import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'prayer_provider.dart';

class QiblaCompassScreen extends StatefulWidget {
  const QiblaCompassScreen({super.key});

  @override
  State<QiblaCompassScreen> createState() => _QiblaCompassScreenState();
}

class _QiblaCompassScreenState extends State<QiblaCompassScreen> {
  bool _hasPermission = false;
  bool _isLoading = true;
  double _qiblaAngle = 0.0;
  Position? _currentPosition;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _checkLocationAndCalculateQibla();
  }

  Future<void> _checkLocationAndCalculateQibla() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMsg = 'خدمات تحديد الموقع (GPS) مغلقة. يرجى تفعيلها من إعدادات الهاتف.';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMsg = 'صلاحية تحديد الموقع مرفوضة. لا يمكن تحديد اتجاه القبلة بدقة دون موقعك.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMsg = 'صلاحية الموقع مرفوضة بشكل دائم. يرجى تفعيل الصلاحية من إعدادات الهاتف.';
          _isLoading = false;
        });
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
        ).timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint("Error getting current location: $e. Attempting last known position...");
        try {
          position = await Geolocator.getLastKnownPosition();
        } catch (_) {}
      }

      double lat;
      double lon;
      if (position != null) {
        lat = position.latitude;
        lon = position.longitude;
      } else {
        // Fallback to active city in provider
        final prayerProvider = Provider.of<PrayerProvider>(context, listen: false);
        lat = prayerProvider.currentCity.latitude;
        lon = prayerProvider.currentCity.longitude;
      }

      final coordinates = Coordinates(lat, lon);
      final qiblaDirection = Qibla(coordinates).direction;

      setState(() {
        _currentPosition = position;
        _qiblaAngle = qiblaDirection;
        _hasPermission = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = 'حدث خطأ أثناء الحصول على الموقع: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF0F5A47);
    final Color goldColor = const Color(0xFFD4AF37);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0B1412), // Premium dark background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'بوصلة القبلة التفاعلية',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        ),
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFFD4AF37)),
                    SizedBox(height: 16),
                    Text(
                      'جاري حساب القبلة وتحديد موقعك الجغرافي...',
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else if (_errorMsg != null)
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.location_off, color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      _errorMsg!,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: goldColor),
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _errorMsg = null;
                        });
                        _checkLocationAndCalculateQibla();
                      },
                      child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              )
            else if (_hasPermission)
              Expanded(
                child: StreamBuilder<CompassEvent>(
                  stream: FlutterCompass.events,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'خطأ في قراءة اتجاه البوصلة: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                    }

                    double? heading = snapshot.data?.heading;

                    if (heading == null) {
                      return const Center(
                        child: Text(
                          'جهازك لا يحتوي على حساس البوصلة (Compass Sensor). لا يمكن استخدام البوصلة التفاعلية الحية.',
                          style: TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    // Calculate rotation angles
                    final double compassRotation = -heading * pi / 180;
                    final double qiblaRotation = (_qiblaAngle - heading) * pi / 180;

                    // Check if phone is aligned with Mecca (within 5 degrees)
                    final double diff = (heading - _qiblaAngle).abs();
                    final bool isAligned = diff < 5 || (360 - diff) < 5;

                    // Play soft feedback once when aligned
                    if (isAligned) {
                      HapticFeedback.selectionClick();
                    }

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Details
                        Text(
                          'زاوية القبلة: ${_qiblaAngle.toInt()}° من الشمال',
                          style: TextStyle(color: goldColor, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentPosition != null
                              ? 'إحداثياتك: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}'
                              : '',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        const SizedBox(height: 32),

                        // Interactive Compass Design
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // 1. Rotating Outer Compass Card (North Indicator)
                            Transform.rotate(
                              angle: compassRotation,
                              child: Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF162220),
                                  border: Border.all(
                                    color: isAligned ? Colors.teal : primaryColor,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isAligned ? Colors.teal : primaryColor).withOpacity(0.3),
                                      blurRadius: 24,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const Positioned(top: 10, child: Text('N', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18))),
                                    const Positioned(bottom: 10, child: Text('S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                                    const Positioned(left: 10, child: Text('W', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                                    const Positioned(right: 10, child: Text('E', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                                    
                                    // Degrees markings
                                    ...List.generate(12, (index) {
                                      final double angle = index * 30 * pi / 180;
                                      return Transform.rotate(
                                        angle: angle,
                                        child: Align(
                                          alignment: Alignment.topCenter,
                                          child: Column(
                                            children: [
                                              const SizedBox(height: 25),
                                              Container(width: 2, height: 6, color: Colors.white30),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),

                            // 2. Qibla Needle pointing to Kaaba
                            Transform.rotate(
                              angle: qiblaRotation,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.navigation,
                                    size: 100,
                                    color: goldColor,
                                  ),
                                  const SizedBox(height: 100), // Push the center pivot
                                ],
                              ),
                            ),

                            // 3. Central Kaaba Center Piece
                            Container(
                              width: 54,
                              height: 54,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black,
                                boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 6)],
                              ),
                              child: Icon(Icons.mosque, color: goldColor, size: 24),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),

                        // Alignment Indicator Text
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: isAligned ? Colors.teal.withOpacity(0.2) : Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isAligned ? Colors.teal : Colors.white12,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            isAligned ? 'أنت الآن باتجاه الكعبة المشرّفة 🕋' : 'قم بتدوير الهاتف لتوجيه السهم الذهبي للأعلى',
                            style: TextStyle(
                              color: isAligned ? Colors.teal[100] : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
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
