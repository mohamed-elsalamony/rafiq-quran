import 'package:flutter/material.dart';

class AudioPlayerWidget extends StatelessWidget {
  final bool isPlaying;
  final List<Map<String, String>> reciters;
  final String currentReciterId;
  final double playbackSpeed;
  final int repeatTimes;
  final VoidCallback onPlayToggle;
  final ValueChanged<String> onReciterChanged;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<int> onRepeatChanged;
  final VoidCallback onDownload;

  const AudioPlayerWidget({
    super.key,
    required this.isPlaying,
    required this.reciters,
    required this.currentReciterId,
    required this.playbackSpeed,
    required this.repeatTimes,
    required this.onPlayToggle,
    required this.onReciterChanged,
    required this.onSpeedChanged,
    required this.onRepeatChanged,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF0F5A47);
    final Color accentColor = const Color(0xFFD4AF37);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // شريط الضوابط العلوي: القارئ والتحميل
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // اختيار القارئ
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: currentReciterId,
                        isExpanded: true,
                        underline: const SizedBox(),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black87,
                          fontFamily: 'Outfit',
                        ),
                        items: reciters.map((r) {
                          return DropdownMenuItem<String>(
                            value: r['id'],
                            child: Text(r['name']!, textAlign: Alignment.centerRight.x > 0 ? TextAlign.left : TextAlign.right),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) onReciterChanged(val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // تحميل الصوت محلياً
              IconButton(
                icon: const Icon(Icons.download_for_offline, color: Colors.teal),
                onPressed: onDownload,
                tooltip: 'تحميل تلاوات الصفحة',
              ),
            ],
          ),
          const Divider(height: 8, thickness: 0.5),

          // شريط الضوابط السفلي: سرعة التشغيل، زر التشغيل، التكرار
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // خيار سرعة التشغيل
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.speed, color: Colors.grey, size: 16),
                  const SizedBox(width: 4),
                  DropdownButton<double>(
                    value: playbackSpeed,
                    underline: const SizedBox(),
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87),
                    items: const [
                      DropdownMenuItem(value: 0.75, child: Text('0.75x')),
                      DropdownMenuItem(value: 1.0, child: Text('1.0x')),
                      DropdownMenuItem(value: 1.25, child: Text('1.25x')),
                      DropdownMenuItem(value: 1.5, child: Text('1.5x')),
                      DropdownMenuItem(value: 2.0, child: Text('2.0x')),
                    ],
                    onChanged: (val) {
                      if (val != null) onSpeedChanged(val);
                    },
                  ),
                ],
              ),

              // زر التشغيل والتعطيل الرئيسي
              GestureDetector(
                onTap: onPlayToggle,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),

              // خيار تكرار الآية للحفظ
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.repeat, color: Colors.grey, size: 16),
                  const SizedBox(width: 4),
                  DropdownButton<int>(
                    value: repeatTimes,
                    underline: const SizedBox(),
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('تكرار: 1')),
                      DropdownMenuItem(value: 2, child: Text('تكرار: 2')),
                      DropdownMenuItem(value: 3, child: Text('تكرار: 3')),
                      DropdownMenuItem(value: 5, child: Text('تكرار: 5')),
                      DropdownMenuItem(value: 10, child: Text('تكرار: 10')),
                    ],
                    onChanged: (val) {
                      if (val != null) onRepeatChanged(val);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
