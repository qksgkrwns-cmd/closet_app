import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class GeminiService {
  static final _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  static final _model = dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.0-flash';

  static Future<Map<String, dynamic>?> analyzeClothesImage(
    File imageFile, {
    bool enableAnalysis = true,
  }) async {
    if (!enableAnalysis || _apiKey.isEmpty) return null;

    try {
      final client = GenerativeAI(apiKey: _apiKey).generativeModel(model: _model);
      final imageBytes = await imageFile.readAsBytes();

      final prompt = '''
Analyze this clothing image and return the following information in JSON format (respond in Korean):
{
  "category": "Choose one: top/bottom/outerwear/shoes/hat",
  "brand": "Estimated brand (or 'unknown')",
  "color": "Main color",
  "seasons": ["Suitable seasons"]
}
      ''';

      final response = await client.generateContent(
        [
          Content.multi([
            TextPart(prompt),
            DataPart('image/jpeg', imageBytes),
          ]),
        ],
      );

      final jsonStr = response.text?.replaceAll('```json', '').replaceAll('```', '').trim() ?? '{}';
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return json;
    } catch (e) {
      print('Gemini API Error: $e');
      return null;
    }
  }
}