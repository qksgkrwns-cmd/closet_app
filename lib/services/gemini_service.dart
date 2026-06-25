import 'dart:io';
import 'package:flutter/foundation.dart';
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
    if (!enableAnalysis) {
      debugPrint('[AI] Analysis skipped: disabled by user setting.');
      return null;
    }
    if (_apiKey.isEmpty) {
      debugPrint('[AI] Analysis skipped: GEMINI_API_KEY is missing.');
      return null;
    }

    try {
      final model = GenerativeModel(model: _model, apiKey: _apiKey);
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

      final response = await model.generateContent(
        [
          Content.multi([
            TextPart(prompt),
            DataPart('image/jpeg', imageBytes),
          ]),
        ],
      );

      final jsonStr = response.text?.replaceAll('```json', '').replaceAll('```', '').trim() ?? '{}';
      debugPrint('[AI] Gemini text response: $jsonStr');
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return json;
    } catch (e) {
      debugPrint('[AI] Gemini API error: $e');
      return null;
    }
  }
}