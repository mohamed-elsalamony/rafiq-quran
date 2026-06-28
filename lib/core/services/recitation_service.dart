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

  /// Downloads a list of verses for offline playback.
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
          // Set a timeout of 15 seconds to prevent hanging indefinitely
          final response = await http.get(Uri.parse(url)).timeout(
                const Duration(seconds: 15),
                onTimeout: () => throw Exception(
                    'انتهت مهلة الاتصال بالخادم عند تحميل الآية $ayah.'),
              );

          if (response.statusCode == 200) {
            await file.writeAsBytes(response.bodyBytes);
          } else {
            throw Exception(
                'فشل تحميل الآية $ayah (رمز الاستجابة: ${response.statusCode}).');
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

  /// Prefetches a single verse silently in the background.
  static Future<void> prefetchVerse(
      int surah, int ayah, String reciterId) async {
    try {
      final file = await getLocalFile(surah, ayah, reciterId);
      if (!await file.exists()) {
        final url = getAudioUrl(surah, ayah, reciterId);
        final response = await http.get(Uri.parse(url)).timeout(
              const Duration(seconds: 15),
            );
        if (response.statusCode == 200) {
          await file.parent.create(recursive: true);
          await file.writeAsBytes(response.bodyBytes);
          debugPrint(
              "Prefetched successfully: Surah $surah, Ayah $ayah for $reciterId");
        }
      }
    } catch (e) {
      debugPrint("Prefetch verse error: $e");
    }
  }
}
