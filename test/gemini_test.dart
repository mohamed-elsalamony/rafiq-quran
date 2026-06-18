import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rafiq_quran/core/services/gemini_service.dart';

void main() {
  test('Test Gemini Service inside the app', () async {
    // Setup Mock SharedPreferences so SharedPreferences.getInstance() doesn't throw.
    SharedPreferences.setMockInitialValues({});
    
    final service = GeminiService();
    final question = "كان في قصة زمان واحد كان ف الصحراء ف طلع عليه واحد كان عاوز يسرقة وياخد فلوية ويقتلة ف قالة استني اصلي ركعتين ودعا ربنا. هل تعرف هذه القصة وتفاصيلها ودعائها؟";
    print("----------------------------------------");
    print("Sending question to Gemini: $question");
    
    final response = await service.sendMessage(question);
    print("----------------------------------------");
    print("Response from App Model:");
    print(response);
    print("----------------------------------------");
  });
}
