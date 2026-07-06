import 'dart:convert';
import 'dart:io';

void main() async {
  final inputPath = r'c:\Users\us mohamed\Desktop\مصحف\assets\data\aldaa_wadawaa.json';
  final backupPath = r'c:\Users\us mohamed\Desktop\مصحف\assets\data\aldaa_wadawaa_backup.json';

  // 1. قراءة الملف
  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    print('ERROR: File not found: $inputPath');
    exit(1);
  }

  // 2. نسخة احتياطية
  final backupFile = File(backupPath);
  if (!backupFile.existsSync()) {
    inputFile.copySync(backupPath);
    print('Backup saved: $backupPath');
  } else {
    print('Backup already exists, skipping');
  }

  // 3. قراءة وتحليل JSON
  final rawJson = inputFile.readAsStringSync(encoding: utf8);
  final List<dynamic> data = jsonDecode(rawJson);
  print('Loaded ${data.length} chapters');

  // 4. تنظيف وإعادة بناء البيانات
  final cleanData = <Map<String, dynamic>>[];
  for (int i = 0; i < data.length; i++) {
    final chapter = data[i] as Map<String, dynamic>;
    final cleanChapter = {
      'id': chapter['id'],
      'title': cleanTitle(chapter['title'] as String),
      'content': cleanContent(chapter['content'] as String),
      'page': chapter['page'],
    };
    cleanData.add(cleanChapter);
    if ((i + 1) % 10 == 0) print('  Processed ${i + 1} / ${data.length}');
  }
  print('All ${cleanData.length} chapters cleaned');

  // 5. حفظ
  const encoder = JsonEncoder.withIndent('  ');
  final outputJson = encoder.convert(cleanData);
  inputFile.writeAsStringSync(outputJson, encoding: utf8);
  print('Saved OK');

  // 6. معاينة
  print('\n=== Chapter 1 preview ===');
  final c1 = cleanData[0]['content'] as String;
  print(c1.substring(0, c1.length.clamp(0, 600)));
  print('\n=== Chapter 4 preview ===');
  final c4 = cleanData[3]['content'] as String;
  print(c4.substring(0, c4.length.clamp(0, 600)));
}

String cleanTitle(String title) {
  title = removeDirectionalChars(title);
  title = title.replaceAll(RegExp(r'[A-Za-z]'), '');
  title = title.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  return title;
}

String removeDirectionalChars(String text) {
  return text.replaceAll(
    RegExp(r'[\u200B-\u200F\u202A-\u202E\u2060-\u206F\uFEFF\u00AD]'),
    '',
  );
}

String cleanContent(String text) {
  // A: إزالة رموز التحكم في الاتجاه
  text = removeDirectionalChars(text);

  // B: معالجة سطر بسطر - حذف هوامش التحقيق
  final lines = text.split('\n');
  final keepLines = <String>[];

  for (final line in lines) {
    final t = line.trim();

    // هامش رقمي في بداية السطر: (۱) أو [2]
    if (RegExp(r'^\s*[\(\[]\s*[\d\u06F0-\u06F9\u0660-\u0669]{1,3}\s*[\)\]]').hasMatch(t)) continue;

    // اختصار نسخة: ف: س: ز: ل: خ: في بداية السطر مع نص قصير
    if (RegExp(r'^[\u0641\u0633\u0632\u0644\u062E\u0637\u062D\u0628\u0623\u0643\u0646\u064A\u0648]\s*[:]\s*.{0,100}$').hasMatch(t) &&
        t.length < 120) continue;

    // سطر رقم مجرد
    if (RegExp(r'^[\d\u06F0-\u06F9\u0660-\u0669\s]{1,6}$').hasMatch(t) && t.isNotEmpty) continue;

    keepLines.add(line);
  }
  text = keepLines.join('\n');

  // C: إزالة إشارات الهوامش المدمجة
  text = text.replaceAll(
    RegExp(r'\s*\(\s*[\d\u06F0-\u06F9\u0660-\u0669]{1,3}\s*\)\s*'),
    ' ',
  );
  text = text.replaceAll(
    RegExp(r'\s*\[\s*[\d\u06F0-\u06F9\u0660-\u0669]{1,3}\s*\]\s*'),
    ' ',
  );

  // D: إزالة الحروف اللاتينية الغريبة (1-5 أحرف بين مسافات)
  text = text.replaceAllMapped(
    RegExp(r'(?<![A-Za-z])\b[A-Za-z]{1,5}\b(?![A-Za-z])'),
    (m) => ' ',
  );

  // E: إزالة تسلسلات لاتينية متعددة متتالية (3+ كلمات)
  text = text.replaceAll(RegExp(r'([A-Za-z]{1,8}\s+){3,}'), ' ');

  // F: تنظيف رمز › و‹
  text = text.replaceAll('\u203A', '\u060C').replaceAll('\u2039', '\u060C');

  // G: تنظيف علامات اقتباس مضاعفة
  text = text.replaceAll(RegExp(r'"{2,}'), '"');

  // H: تنظيف الأسطر الفارغة الزائدة
  text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

  // I: تنظيف المسافات الزائدة
  text = text.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
  text = text.replaceAll(RegExp(r'^[ \t]+$', multiLine: true), '');

  return text.trim();
}
