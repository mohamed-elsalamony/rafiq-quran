import 'dart:io';
import 'dart:convert';

void main() async {
  final url = "https://archive.org/download/way2llh22_20171016_1230/90079s_djvu.txt";
  final destPath = r"c:\Users\us mohamed\Desktop\مصحف\scratch\aldaa_full_text.txt";

  print("Downloading from $url...");
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final file = File(destPath);
      final sink = file.openWrite();
      await response.pipe(sink);
      print("Download completed successfully! Saved to $destPath");
      
      // Inspect the first 50 lines
      final lines = await file.openRead().transform(utf8.decoder).transform(const LineSplitter()).take(50).toList();
      print("\n--- First 50 lines of the file ---");
      for (var i = 0; i < lines.length; i++) {
        print("${i+1}: ${lines[i]}");
      }
    } else {
      print("Failed to download: Status Code ${response.statusCode}");
    }
  } catch (e) {
    print("Error: $e");
  } finally {
    client.close();
  }
}
