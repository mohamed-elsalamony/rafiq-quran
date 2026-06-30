import 'dart:io';

void main() {
  final paths = [
    r"C:\Users\us mohamed\AppData\Local\Android\Sdk",
    r"C:\Android\Sdk",
    r"C:\Android\sdk",
    r"C:\sdk",
    r"C:\Sdk",
    r"D:\Android\Sdk",
    r"D:\Android\sdk",
    r"D:\sdk",
    r"D:\Sdk",
    r"C:\Program Files\Android",
    r"C:\Program Files (x86)\Android",
    r"C:\Users\us mohamed\develop\Android\Sdk",
    r"C:\Users\us mohamed\develop\sdk",
  ];

  print("Checking common Android SDK paths...");
  var found = false;
  for (var path in paths) {
    final dir = Directory(path);
    if (dir.existsSync()) {
      print("[FOUND] Directory exists: $path");
      // Check if platforms and platform-tools exist inside
      final platforms = Directory("$path/platforms");
      final platformTools = Directory("$path/platform-tools");
      print("  - platforms exists: ${platforms.existsSync()}");
      print("  - platform-tools exists: ${platformTools.existsSync()}");
      found = true;
    }
  }
  
  if (!found) {
    print("Android SDK not found in common locations.");
  }
}
