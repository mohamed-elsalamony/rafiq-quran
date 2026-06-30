import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class RecitationService {
  /// Gets the remote URL for a recitation verse.
  static String getAudioUrl(int surah, int ayah, String reciterId) {
    final sStr = surah.toString().padLeft(3, '0');
    final aStr = ayah.toString().padLeft(3, '0');
    return 'https://www.everyayah.com/data/$reciterId/$sStr$aStr.mp3';
  }

  /// Gets the local file path for a recitation verse.
  static Future<File> getLocalFile(
      int surah, int ayah, String reciterId) async {
    final directory = await getApplicationDocumentsDirectory();
    final sStr = surah.toString().padLeft(3, '0');
    final aStr = ayah.toString().padLeft(3, '0');
    return File('${directory.path}/recitations/$reciterId/${sStr}_$aStr.mp3');
  }

  /// Checks if a recitation verse exists offline.
  static Future<bool> isOfflineAvailable(
      int surah, int ayah, String reciterId) async {
    try {
      final file = await getLocalFile(surah, ayah, reciterId);
      return await file.exists();
    } catch (_) {
      return false;
    }
  }

  /// Downloads a list of verses for offline playback with retry logic.
  /// Reports progress callback.
  static Future<void> downloadVerses({
    required List<Map<String, int>> verses,
    required String reciterId,
    required Function(double progress) onProgress,
    required Function() onSuccess,
    required Function(String error) onFailure,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dirPath = '${directory.path}/recitations/$reciterId';

      // Ensure the directory exists
      await Directory(dirPath).create(recursive: true);

      int total = verses.length;
      int completed = 0;

      for (final verse in verses) {
        final surah = verse['surah']!;
        final ayah = verse['ayah']!;
        final file = await getLocalFile(surah, ayah, reciterId);

        if (!await file.exists()) {
          final url = getAudioUrl(surah, ayah, reciterId);
          int attempts = 0;
          bool success = false;
          dynamic lastError;

          while (attempts < 3 && !success) {
            try {
              final response = await http.get(Uri.parse(url)).timeout(
                    const Duration(seconds: 15),
                  );

              if (response.statusCode == 200) {
                await file.writeAsBytes(response.bodyBytes);
                success = true;
              } else {
                throw Exception(
                    'رمز الاستجابة: ${response.statusCode}');
              }
            } catch (e) {
              attempts++;
              lastError = e;
              if (attempts < 3) {
                await Future.delayed(const Duration(seconds: 2));
              }
            }
          }

          if (!success) {
            throw Exception(
                'فشل تحميل الآية $ayah بعد 3 محاولات. (التفاصيل: $lastError)');
          }
        }

        completed++;
        onProgress(completed / total);
      }
      onSuccess();
    } catch (e) {
      debugPrint("RecitationService download error: $e");
      onFailure(e.toString().replaceAll('Exception:', '').trim());
    }
  }

  /// Prefetches a single verse silently in the background with retry logic.
  static Future<void> prefetchVerse(
      int surah, int ayah, String reciterId) async {
    try {
      final file = await getLocalFile(surah, ayah, reciterId);
      if (!await file.exists()) {
        final url = getAudioUrl(surah, ayah, reciterId);
        int attempts = 0;
        bool success = false;
        while (attempts < 2 && !success) {
          try {
            final response = await http.get(Uri.parse(url)).timeout(
                  const Duration(seconds: 10),
                );
            if (response.statusCode == 200) {
              await file.parent.create(recursive: true);
              await file.writeAsBytes(response.bodyBytes);
              success = true;
              debugPrint(
                  "Prefetched successfully: Surah $surah, Ayah $ayah for $reciterId");
            } else {
              attempts++;
            }
          } catch (_) {
            attempts++;
            if (attempts < 2) {
              await Future.delayed(const Duration(seconds: 2));
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Prefetch verse error: $e");
    }
  }
}
