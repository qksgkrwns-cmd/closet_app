import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/outfit.dart';

class OutfitService {
  static final _supabase = Supabase.instance.client;

  static Future<List<Outfit>> getUserOutfits(String userId) async {
    try {
      final response = await _supabase
          .from('outfits')
          .select()
          .eq('user_id', userId);

      return (response as List).map((json) => Outfit.fromJson(json)).toList();
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  static Future<void> likeOutfit(String userId, String outfitId) async {
    await _supabase.from('outfit_likes').insert({
      'user_id': userId,
      'outfit_id': outfitId,
    });
  }

  static Future<void> unlikeOutfit(String userId, String outfitId) async {
    await _supabase
        .from('outfit_likes')
        .delete()
        .eq('user_id', userId)
        .eq('outfit_id', outfitId);
  }

  static Future<void> saveOutfit(String userId, String outfitId) async {
    await _supabase.from('saved_outfits').insert({
      'user_id': userId,
      'outfit_id': outfitId,
    });
  }

  static Future<List<Outfit>> getSavedOutfits(String userId) async {
    try {
      final response = await _supabase
          .from('saved_outfits')
          .select('outfits(*)')
          .eq('user_id', userId);

      return (response as List)
          .map((item) => Outfit.fromJson(item['outfits']))
          .toList();
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }
}