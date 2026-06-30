import 'dart:io';
import 'dart:convert';

void main() async {
  final url = "https://archive.org/metadata/way2llh22_20171016_1230";
  print("Fetching metadata from $url...");
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode == 200) {
      final jsonString = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> metadata = json.decode(jsonString);
      final List<dynamic> files = metadata['files'] ?? [];
      print("Found ${files.length} files:");
      for (var f in files) {
        final name = f['name'] as String;
        final format = f['format'] as String?;
        final size = f['size'] as String?;
        if (name.toLowerCase().contains("txt") || name.toLowerCase().contains("epub") || name.toLowerCase().contains("pdf")) {
          print("- Name: $name, Format: $format, Size: $size");
        }
      }
    } else {
      print("Failed: Status Code ${response.statusCode}");
    }
  } catch (e) {
    print("Error: $e");
  } finally {
    client.close();
  }
}
