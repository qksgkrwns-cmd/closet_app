import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class DailyLookService {
  static final _supabase = Supabase.instance.client;

  static String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static Future<List<dynamic>> fetchMyLooksByDate(DateTime date) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    return await _supabase
        .from('daily_looks')
        .select()
        .eq('user_id', userId)
        .eq('wear_date', _dateKey(date))
        .order('created_at', ascending: false);
  }

        static Future<List<dynamic>> fetchMyLooksInRange(DateTime start, DateTime end) async {
          final userId = _supabase.auth.currentUser?.id;
          if (userId == null) return [];

          final startKey = _dateKey(start);
          final endKey = _dateKey(end);

          return await _supabase
          .from('daily_looks')
          .select()
          .eq('user_id', userId)
          .gte('wear_date', startKey)
          .lte('wear_date', endKey)
          .order('wear_date', ascending: true)
          .order('created_at', ascending: false);
        }

  static Future<Map<String, dynamic>> fetchLookById(int id) async {
    dynamic row;
    try {
      row = await _supabase
          .from('daily_looks')
          .select('*, profiles(username)')
          .eq('id', id)
          .single();
    } catch (_) {
      row = await _supabase
          .from('daily_looks')
          .select()
          .eq('id', id)
          .single();
    }
    final mapped = Map<String, dynamic>.from(row);
    final profile = mapped['profiles'];
    if (profile is Map && profile['username'] != null) {
      mapped['profile_username'] = profile['username'].toString();
    }
    return mapped;
  }

  static Future<List<dynamic>> fetchPublicFeed() async {
    dynamic rows;
    try {
      rows = await _supabase
          .from('daily_looks')
          .select('*, profiles(username)')
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .limit(100);
    } catch (_) {
      rows = await _supabase
          .from('daily_looks')
          .select()
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .limit(100);
    }

    return (rows as List).map((row) {
      final mapped = Map<String, dynamic>.from(row);
      final profile = mapped['profiles'];
      if (profile is Map && profile['username'] != null) {
        mapped['profile_username'] = profile['username'].toString();
      }
      return mapped;
    }).toList();
  }

  static Future<void> saveDailyLook({
    int? id,
    required DateTime wearDate,
    required String content,
    required List<String> hashtags,
    required bool isPublic,
    File? imageFile,
    String? oldImageUrl,
    int? topItemId,
    int? bottomItemId,
    int? shoesItemId,
    int? hatItemId,
    int? bagItemId,
    int? accessoryItemId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다.');

    if (id == null) {
      final existing = await _supabase
          .from('daily_looks')
          .select('id')
          .eq('user_id', userId)
          .eq('wear_date', _dateKey(wearDate))
          .limit(1);
      if ((existing as List).isNotEmpty) {
        throw Exception('하루에 한 번만 등록할 수 있습니다. 기존 코디를 수정해주세요.');
      }
    }

    String? imageUrl = oldImageUrl;
    if (imageFile != null) {
      imageUrl = await SupabaseService.uploadImage(imageFile, userId: userId);
    }

    final payload = {
      'user_id': userId,
      'wear_date': _dateKey(wearDate),
      'content': content,
      'hashtags': hashtags,
      'is_public': isPublic,
      'image_url': imageUrl,
      'top_item_id': topItemId,
      'bottom_item_id': bottomItemId,
      'shoes_item_id': shoesItemId,
      'hat_item_id': hatItemId,
      'bag_item_id': bagItemId,
      'accessory_item_id': accessoryItemId,
    };

    if (id == null) {
      await _supabase.from('daily_looks').insert(payload);
      return;
    }

    await _supabase.from('daily_looks').update(payload).eq('id', id);
  }

  static Future<Map<String, dynamic>> getReactionSummary(int dailyLookId) async {
    final userId = _supabase.auth.currentUser?.id;
    final rows = await _supabase
        .from('daily_look_reactions')
        .select('reaction_type, user_id')
        .eq('daily_look_id', dailyLookId);

    final list = rows as List;
    final likes = list.where((e) => e['reaction_type'] == 'like').length;
    final dislikes = list.where((e) => e['reaction_type'] == 'dislike').length;

    String? myReaction;
    if (userId != null) {
      for (final row in list) {
        if (row['user_id'] == userId) {
          myReaction = row['reaction_type']?.toString();
          break;
        }
      }
    }

    return {
      'likes': likes,
      'dislikes': dislikes,
      'myReaction': myReaction,
    };
  }

  static Future<void> setReaction(int dailyLookId, String reactionType) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다.');

    final existing = await _supabase
        .from('daily_look_reactions')
        .select('id, reaction_type')
        .eq('daily_look_id', dailyLookId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing == null) {
      await _supabase.from('daily_look_reactions').insert({
        'daily_look_id': dailyLookId,
        'user_id': userId,
        'reaction_type': reactionType,
      });
      return;
    }

    final existingType = existing['reaction_type']?.toString();
    final existingId = existing['id'];
    if (existingId == null) return;

    if (existingType == reactionType) {
      await _supabase.from('daily_look_reactions').delete().eq('id', existingId);
      return;
    }

    await _supabase
        .from('daily_look_reactions')
        .update({'reaction_type': reactionType})
        .eq('id', existingId);
  }

  static Future<bool> isBookmarked(int dailyLookId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final row = await _supabase
        .from('daily_look_bookmarks')
        .select('id')
        .eq('daily_look_id', dailyLookId)
        .eq('user_id', userId)
        .maybeSingle();
    return row != null;
  }

  static Future<void> toggleBookmark(int dailyLookId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다.');

    final existing = await _supabase
        .from('daily_look_bookmarks')
        .select('id')
        .eq('daily_look_id', dailyLookId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing == null) {
      await _supabase.from('daily_look_bookmarks').insert({
        'daily_look_id': dailyLookId,
        'user_id': userId,
      });
      return;
    }

    await _supabase
        .from('daily_look_bookmarks')
        .delete()
        .eq('id', existing['id']);
  }

  static Future<List<dynamic>> fetchBookmarkedLooks() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    dynamic rows;
    try {
      rows = await _supabase
          .from('daily_look_bookmarks')
          .select('daily_looks(*, profiles(username))')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
    } catch (_) {
      rows = await _supabase
          .from('daily_look_bookmarks')
          .select('daily_looks(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
    }

    return (rows as List).map((row) {
      final look = Map<String, dynamic>.from(row['daily_looks'] ?? {});
      final profile = look['profiles'];
      if (profile is Map && profile['username'] != null) {
        look['profile_username'] = profile['username'].toString();
      }
      return look;
    }).where((look) => look['id'] != null).toList();
  }
}
