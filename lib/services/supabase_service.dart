import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final _supabase = Supabase.instance.client;

  /// 모든 옷 데이터 조회
  static Future<List<dynamic>> fetchClothes({String? category}) async {
    var query = _supabase.from('clothes').select();

    if (category != null && category != '전체') {
      query = query.eq('category', category);
    }

    return await query.order('created_at', ascending: false);
  }

  /// 옷 저장
  static Future<void> saveClothes({
    required String category,
    required String brand,
    required String color,
    required List<String> seasons,
    File? imageFile,
  }) async {
    String? imageUrl;

    if (imageFile != null) {
      imageUrl = await uploadImage(imageFile);
    }

    await _supabase.from('clothes').insert({
      'category': category,
      'brand': brand,
      'color': color,
      'seasons': seasons,
      'image_url': imageUrl,
    });
  }

  /// 옷 수정
  static Future<void> updateClothes({
    required int id,
    required String category,
    required String brand,
    required String color,
    required List<String> seasons,
    File? newImageFile,
    String? oldImageUrl,
  }) async {
    String? imageUrl = oldImageUrl;

    if (newImageFile != null) {
      // 기존 이미지 삭제
      if (oldImageUrl != null) {
        await deleteImage(oldImageUrl);
      }
      // 새 이미지 업로드
      imageUrl = await uploadImage(newImageFile);
    }

    await _supabase.from('clothes').update({
      'category': category,
      'brand': brand,
      'color': color,
      'seasons': seasons,
      'image_url': imageUrl,
    }).eq('id', id);
  }

  /// 옷 삭제
  static Future<void> deleteClothes(Map item) async {
    final imageUrl = item['image_url'];

    if (imageUrl != null) {
      await deleteImage(imageUrl);
    }

    await _supabase.from('clothes').delete().eq('id', item['id']);
  }

  /// 이미지 업로드
  static Future<String> uploadImage(File imageFile) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _supabase.storage.from('clothes').upload(fileName, imageFile);

    return _supabase.storage.from('clothes').getPublicUrl(fileName);
  }

  /// 이미지 삭제
  static Future<void> deleteImage(String imageUrl) async {
    final fileName = imageUrl.toString().split('/').last;
    await _supabase.storage.from('clothes').remove([fileName]);
  }
}