import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final _supabase = Supabase.instance.client;

  static Future<List<dynamic>> fetchClothes({String? category}) async {
    var query = _supabase.from('clothes').select();
    if (category != null && category != 'all') {
      query = query.eq('category', category);
    }
    return await query.order('created_at', ascending: false);
  }

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
      if (oldImageUrl != null) {
        await deleteImage(oldImageUrl);
      }
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

  static Future<void> deleteClothes(Map item) async {
    final imageUrl = item['image_url'];
    if (imageUrl != null) {
      await deleteImage(imageUrl);
    }
    await _supabase.from('clothes').delete().eq('id', item['id']);
  }

  static Future<String> uploadImage(File imageFile) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _supabase.storage.from('clothes').upload(fileName, imageFile);
    return _supabase.storage.from('clothes').getPublicUrl(fileName);
  }

  static Future<void> deleteImage(String imageUrl) async {
    final fileName = imageUrl.toString().split('/').last;
    await _supabase.storage.from('clothes').remove([fileName]);
  }
}