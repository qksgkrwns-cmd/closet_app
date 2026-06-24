import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static Future<Map<String, dynamic>> analyzeClothesImage(
    File imageFile,
  ) async {
    try {
      final model = GenerativeModel(
        model: dotenv.env['GEMINI_MODEL']!,
        apiKey: dotenv.env['GEMINI_API_KEY']!,
      );

      final imageBytes = await imageFile.readAsBytes();

      final prompt = TextPart('''
사진 속 의류를 분석하여 JSON만 반환하세요.

JSON 타입으로 만들어줘.

{
  "category":"상의",
  "brand":"Nike",
  "color":"검정",
  "seasons":["봄","가을"]
}

규칙:
- 브랜드 로고가 보이면 브랜드명 반환
- 모르면 "기타"
- category는 상의/하의/아우터/신발/모자
- seasons는 배열
- JSON 외 텍스트 금지
''');

      final response = await model.generateContent([
        Content.multi([
          prompt,
          DataPart('image/jpeg', imageBytes),
        ])
      ]);

      final text = response.text ?? '';
      final cleaned = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(cleaned);
    } catch (e) {
      rethrow;
    }
  }
}