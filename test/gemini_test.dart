import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rafiq_quran/core/services/gemini_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('Test Gemini Service inside the app', () async {
    // Setup Mock SharedPreferences so SharedPreferences.getInstance() doesn't throw.
    SharedPreferences.setMockInitialValues({
      'backend_url': 'http://127.0.0.1:3000'
    });

    final mockClient = MockClient((request) async {
      final responseString = json.encode({
        'success': true,
        'reply': 'هذه قصة التاجر الصالح واللص الذي دعا الله فرعاه ونجاه ببركة صلاته ودعائه.',
        'model': 'gemini-2.5-flash'
      });
      return http.Response(responseString, 200, headers: {
        'content-type': 'application/json; charset=utf-8'
      });
    });

    await http.runWithClient(() async {
      final service = GeminiService();
      final question = "كان في قصة زمان واحد كان ف الصحراء ف طلع عليه واحد كان عاوز يسرقة وياخد فلوية ويقتلة ف قالة استني اصلي ركعتين ودعا ربنا. هل تعرف هذه القصة وتفاصيلها ودعائها؟";
      print("----------------------------------------");
      print("Sending question to Gemini: $question");
      
      final response = await service.sendMessage(question);
      print("----------------------------------------");
      print("Response from App Model:");
      print(response);
      print("----------------------------------------");
      
      expect(response, contains('قصة'));
    }, () => mockClient);
  });
}
