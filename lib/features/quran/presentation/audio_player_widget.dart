import 'package:flutter/material.dart';

class AudioPlayerWidget extends StatefulWidget {
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

  // AutoScroll parameters
  final VoidCallback? onAutoScrollToggle;
  final bool isAutoScrollOn;

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
    this.onAutoScrollToggle,
    this.isAutoScrollOn = false,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0F5A47);
    const Color accentColor = Color(0xFFD4AF37);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: _isExpanded ? 12.0 : 8.0,
        ),
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
        child: _isExpanded ? _buildExpandedLayout(primaryColor, accentColor, isDark) : _buildCollapsedLayout(primaryColor, accentColor, isDark),
      ),
    );
  }

  Widget _buildCollapsedLayout(Color primaryColor, Color accentColor, bool isDark) {
    final currentReciterName = widget.reciters.firstWhere(
      (r) => r['id'] == widget.currentReciterId,
      orElse: () => {'name': 'قارئ غير معروف'},
    )['name']!;

    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = true;
        });
      },
      child: Row(
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: widget.onPlayToggle,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Reciter text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'القارئ الحالي',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontFamily: 'Amiri',
                  ),
                ),
                Text(
                  currentReciterName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: 'Amiri',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // AutoScroll button
          if (widget.onAutoScrollToggle != null)
            IconButton(
              icon: Icon(
                Icons.swap_vertical_circle,
                color: widget.isAutoScrollOn ? accentColor : Colors.grey,
                size: 24,
              ),
              onPressed: widget.onAutoScrollToggle,
              tooltip: 'التمرير التلقائي',
            ),
          // Expand arrow
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up, color: Colors.grey),
            onPressed: () {
              setState(() {
                _isExpanded = true;
              });
            },
            tooltip: 'توسيع الإعدادات',
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedLayout(Color primaryColor, Color accentColor, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'خيارات التلاوة والحفظ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontFamily: 'Amiri',
              ),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              onPressed: () {
                setState(() {
                  _isExpanded = false;
                });
              },
              tooltip: 'طي الإعدادات',
            ),
          ],
        ),
        const Divider(height: 8, thickness: 0.5),

        // Row 1: Reciter Selection & Download button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: widget.currentReciterId,
                      isExpanded: true,
                      underline: const SizedBox(),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                        fontFamily: 'Amiri',
                      ),
                      items: widget.reciters.map((r) {
                        return DropdownMenuItem<String>(
                          value: r['id'],
                          child: Text(r['name']!),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) widget.onReciterChanged(val);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.download_for_offline, color: Colors.teal),
              onPressed: widget.onDownload,
              tooltip: 'تحميل تلاوات الصفحة',
            ),
          ],
        ),
        const Divider(height: 8, thickness: 0.5),

        // Row 2: Playback Speed, Auto Scroll, Play toggle, Repetition
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Playback speed
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.speed, color: Colors.grey, size: 16),
                const SizedBox(width: 4),
                DropdownButton<double>(
                  value: widget.playbackSpeed,
                  underline: const SizedBox(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  items: const [
                    DropdownMenuItem(value: 0.75, child: Text('0.75x')),
                    DropdownMenuItem(value: 1.0, child: Text('1.0x')),
                    DropdownMenuItem(value: 1.25, child: Text('1.25x')),
                    DropdownMenuItem(value: 1.5, child: Text('1.5x')),
                    DropdownMenuItem(value: 2.0, child: Text('2.0x')),
                  ],
                  onChanged: (val) {
                    if (val != null) widget.onSpeedChanged(val);
                  },
                ),
              ],
            ),

            // Auto-scroll toggle
            if (widget.onAutoScrollToggle != null)
              IconButton(
                icon: Icon(
                  Icons.swap_vertical_circle,
                  color: widget.isAutoScrollOn ? accentColor : Colors.grey,
                ),
                onPressed: widget.onAutoScrollToggle,
                tooltip: 'التشغيل والتمرير التلقائي للصفحات',
              ),

            // Play/Pause button
            GestureDetector(
              onTap: widget.onPlayToggle,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),

            // Repetition (repeat for hifz)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.repeat, color: Colors.grey, size: 16),
                const SizedBox(width: 4),
                DropdownButton<int>(
                  value: widget.repeatTimes,
                  underline: const SizedBox(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: 'Amiri',
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('تكرار: 1')),
                    DropdownMenuItem(value: 2, child: Text('تكرار: 2')),
                    DropdownMenuItem(value: 3, child: Text('تكرار: 3')),
                    DropdownMenuItem(value: 5, child: Text('تكرار: 5')),
                    DropdownMenuItem(value: 10, child: Text('تكرار: 10')),
                  ],
                  onChanged: (val) {
                    if (val != null) widget.onRepeatChanged(val);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
