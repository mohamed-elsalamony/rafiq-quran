import 'dart:io';
import 'dart:convert';

void main() async {
  final file = File(r"c:\Users\us mohamed\Desktop\مصحف\scratch\aldaa_full_text.txt");
  if (!file.existsSync()) {
    print("Full text file not found!");
    return;
  }
  
  final lines = await file.openRead().transform(utf8.decoder).transform(const LineSplitter()).toList();
  print("Loaded ${lines.length} lines.");
  
  final keywords = [
    "سئل الشيخ الإمام",
    "والدعاء هو من أنفع الأدوية",
    "ومن أنفع الأدوية في دفع البلاء والكروب: الإلحاح",
    "وإذا جمع الدعاء حضور القلب",
    "المعاصي والذنوب والظلم والشهوات هي بمثابة أقفال",
    "حرمان العلم النافع",
    "الوحشة العظيمة التي يجدها العاصي",
    "تعسير أمور العاصي",
    "ظلمة يجدها العاصي في قلبه",
    "تقطع طريق الطاعة",
    "التوبة الصادقة النصوح هي الترياق",
    "القرآن الكريم هو الشفاء",
    "الذكر هو قوت القلوب",
    "الصبر هو نصف الإيمان",
    "الحسد والغل هما داءان",
    "الغضب والشهوة هما جمرتان",
    "التوكل على الله هو صدق",
    "الرقية الشرعية بالقرآن",
    "عشق الصور والتعلق بالخلق",
    "الكبر والعجب والرياء",
    "تسلب العبد مهابته وتكسو صاحبها ذلاً",
    "تسقط الجاه والمنزلة",
    "تسلب صاحبها أسماء المدح",
    "تفسد العقل وتنقصه",
    "طبع الله على قلب صاحبها",
    "لعنة الله ورسوله لفاعلها",
    "حرمان العبد من بركة وأجر دعاء رسول الله",
    "شؤمها العام الذي يتعدى العاصي",
    "تطفئ من قلب العاصي نار الغيرة",
    "ذهاب الحياء وسلخه من القلب",
    "تضعف وقار الله وتعظيمه",
    "أن الله سبحانه ينسى عبده العاصي",
    "حرمان العبد من معية الله الخاصة",
    "تضعف سير القلب إلى الله",
    "زوال النعم الحاضرة وحلول النقم",
    "الذنوب درجات وكبائر وصغائر",
    "الشرك ينقسم إلى شرك أكبر",
    "اللسان من أعظم الجوارح خطراً",
    "النظر هو سهم مسموم",
    "حفظ الفرج عن الحرام",
    "عشق الصور والتعلق بالمخلوقين",
    "ينشأ داء العشق المحرم من أسباب",
    "ودواء هذا الداء العضال (عشق الصور)",
    "الصبر عن الشهوات والمجاهدة للنفس",
    "التوبة النصوح هي المخرج النهائي"
  ];
  
  for (var kw in keywords) {
    var found = false;
    // We search for a simplified version (without diacritics or exact punctuation)
    final cleanKw = kw.replaceAll(RegExp(r'[^\w\s\u0621-\u064A]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    for (var i = 0; i < lines.length; i++) {
      final cleanLine = lines[i].replaceAll(RegExp(r'[^\w\s\u0621-\u064A]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
      if (cleanLine.contains(cleanKw) || (cleanKw.length > 15 && cleanLine.contains(cleanKw.substring(0, 15)))) {
        print("Keyword: '$kw' found at line ${i+1}: '${lines[i].trim()}'");
        found = true;
        break;
      }
    }
    if (!found) {
      print("Keyword: '$kw' NOT FOUND");
    }
  }
}
