import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_service.dart';
import 'supabase_service.dart';

class DailyLookService {
  static final _supabase = Supabase.instance.client;

  static String _normalizeGender(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    if (value.isEmpty) return '미설정';
    if (value == '남성' || value == 'male' || value == 'man' || value == 'm') {
      return '남성';
    }
    if (value == '여성' || value == 'female' || value == 'woman' || value == 'f') {
      return '여성';
    }
    if (value == '미설정' || value == 'unset' || value == 'unknown') {
      return '미설정';
    }
    return raw ?? '미설정';
  }

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

  static bool _isBodySimilar({
    required Map<String, dynamic> me,
    required Map<String, dynamic> other,
  }) {
    final myBody = (me['body_type'] ?? '').toString();
    final otherBody = (other['body_type'] ?? '').toString();
    final myHeight = me['height'] is num ? (me['height'] as num).toInt() : int.tryParse('${me['height']}');
    final otherHeight = other['height'] is num ? (other['height'] as num).toInt() : int.tryParse('${other['height']}');
    final myWeight = me['weight'] is num ? (me['weight'] as num).toInt() : int.tryParse('${me['weight']}');
    final otherWeight = other['weight'] is num ? (other['weight'] as num).toInt() : int.tryParse('${other['weight']}');

    double score = 0;
    if (myBody.isNotEmpty && myBody == otherBody) {
      score += 0.45;
    }

    if (myHeight != null && otherHeight != null) {
      final diff = (myHeight - otherHeight).abs();
      if (diff <= 5) {
        score += 0.3;
      } else if (diff <= 10) {
        score += 0.2;
      } else if (diff <= 15) {
        score += 0.1;
      }
    }

    if (myWeight != null && otherWeight != null) {
      final diff = (myWeight - otherWeight).abs();
      if (diff <= 5) {
        score += 0.25;
      } else if (diff <= 10) {
        score += 0.15;
      } else if (diff <= 15) {
        score += 0.08;
      }
    }

    return score >= 0.5;
  }

  static bool _isStyleSimilar({
    required List<String> myStyles,
    required List<String> otherStyles,
  }) {
    if (myStyles.isEmpty || otherStyles.isEmpty) return false;
    final overlap = myStyles.where((s) => otherStyles.contains(s)).length;
    return overlap > 0;
  }

  static Future<List<dynamic>> fetchPublicFeed({
    bool onlySimilarBody = false,
    bool onlyFollowing = false,
    bool onlyStyleMatch = false,
    bool onlyBookmarked = false,
    String sortBy = 'popular', // 'popular' or 'latest'
  }) async {
    final myProfile = await ProfileService.getCurrentProfile();
    final myGender = _normalizeGender(myProfile?.gender);
    if (myProfile == null || myGender == '미설정') {
      return [];
    }

    dynamic rows;
    try {
      rows = await _supabase
          .from('daily_looks')
          .select('*, profiles(id, username, gender, body_type, height, weight, style_preferences)')
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .limit(300);
    } catch (_) {
      rows = await _supabase
          .from('daily_looks')
          .select()
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .limit(300);
    }

    final mappedRows = (rows as List).map((row) {
      final mapped = Map<String, dynamic>.from(row);
      final profile = mapped['profiles'];
      if (profile is Map) {
        if (profile['username'] != null) {
          mapped['profile_username'] = profile['username'].toString();
          mapped['uploader_name'] = profile['username'].toString();
        }
      }
      return mapped;
    }).toList();

    // If relation select fails or returns null profiles, recover profile info by user_id lookup.
    final missingProfileUserIds = mappedRows
        .where((row) => row['profiles'] == null && row['user_id'] != null)
        .map((row) => row['user_id'].toString())
        .toSet()
        .toList();

    if (missingProfileUserIds.isNotEmpty) {
      try {
        final profileRows = await _supabase
            .from('profiles')
            .select('id, username, gender, body_type, height, weight, style_preferences')
            .inFilter('id', missingProfileUserIds);

        final profileById = <String, Map<String, dynamic>>{};
        for (final row in (profileRows as List)) {
          final p = Map<String, dynamic>.from(row);
          final id = p['id']?.toString();
          if (id == null || id.isEmpty) continue;
          profileById[id] = p;
        }

        for (final row in mappedRows) {
          if (row['profiles'] != null) continue;
          final uid = row['user_id']?.toString();
          if (uid == null || uid.isEmpty) continue;
          final p = profileById[uid];
          if (p == null) continue;
          row['profiles'] = p;
          if (p['username'] != null) {
            row['profile_username'] = p['username'].toString();
            row['uploader_name'] = p['username'].toString();
          }
        }
      } catch (_) {
        // Keep original rows even if fallback profile lookup is blocked.
      }
    }

    // Get following list
    final followingList = <String>[];
    if (onlyFollowing) {
      try {
        final following = await _supabase
            .from('user_follows')
            .select('following_id')
            .eq('user_id', _supabase.auth.currentUser?.id ?? '');
        followingList.addAll((following as List).map((f) => f['following_id'].toString()));
      } catch (_) {
        // If following table doesn't exist, just proceed
      }
    }

    // Get bookmarked looks
    final bookmarkedIds = <int>{};
    if (onlyBookmarked) {
      try {
        final bookmarks = await _supabase
            .from('daily_look_bookmarks')
            .select('daily_look_id')
            .eq('user_id', _supabase.auth.currentUser?.id ?? '');
        bookmarkedIds.addAll((bookmarks as List)
            .map((b) => b['daily_look_id'])
            .whereType<num>()
            .map((e) => e.toInt()));
      } catch (_) {
        // Proceed
      }
    }

    final sameGenderOnly = mappedRows.where((row) {
      final profile = row['profiles'];
      final uploaderId = row['user_id']?.toString();
      final currentUserId = _supabase.auth.currentUser?.id;

      // Always include my own public posts.
      if (uploaderId != null && currentUserId != null && uploaderId == currentUserId) {
        return true;
      }

      if (profile is! Map) return false;
      final gender = _normalizeGender(profile['gender']?.toString());
      return gender != '미설정' && gender == myGender;
    }).toList();

    var filtered = sameGenderOnly;

    // Apply body similarity filter
    if (onlySimilarBody) {
      filtered = filtered.where((row) {
        final profile = row['profiles'];
        if (profile is! Map) return false;
        return _isBodySimilar(
          me: myProfile.toJson(),
          other: Map<String, dynamic>.from(profile),
        );
      }).toList();
    }

    // Apply following filter
    if (onlyFollowing) {
      filtered = filtered.where((row) {
        final uploaderId = row['user_id']?.toString();
        final currentUserId = _supabase.auth.currentUser?.id;
        // Always include my own posts
        if (uploaderId == currentUserId) return true;
        return followingList.contains(uploaderId);
      }).toList();
    }

    // Apply style preference filter
    if (onlyStyleMatch) {
      filtered = filtered.where((row) {
        final profile = row['profiles'];
        if (profile is! Map) return false;
        final otherStyles = (profile['style_preferences'] as List?)?.map((s) => s.toString()).toList() ?? [];
        return _isStyleSimilar(
          myStyles: myProfile.stylePreferences,
          otherStyles: otherStyles,
        );
      }).toList();
    }

    // Apply bookmarked filter
    if (onlyBookmarked) {
      filtered = filtered.where((row) {
        final rawId = row['id'];
        final id = rawId is num ? rawId.toInt() : int.tryParse(rawId.toString());
        return id != null && bookmarkedIds.contains(id);
      }).toList();
    }

    final lookIds = filtered
        .map((row) => row['id'])
        .whereType<num>()
        .map((e) => e.toInt())
        .toList();

    if (lookIds.isEmpty) return filtered;

    final reactions = await _supabase
        .from('daily_look_reactions')
        .select('daily_look_id, reaction_type')
        .inFilter('daily_look_id', lookIds);
    final bookmarks = await _supabase
        .from('daily_look_bookmarks')
        .select('daily_look_id')
        .inFilter('daily_look_id', lookIds);

    final likeCounts = <int, int>{};
    for (final row in (reactions as List)) {
      if (row['reaction_type'] != 'like') continue;
      final rawId = row['daily_look_id'];
      final id = rawId is num ? rawId.toInt() : int.tryParse(rawId.toString());
      if (id == null) continue;
      likeCounts[id] = (likeCounts[id] ?? 0) + 1;
    }

    final bookmarkCounts = <int, int>{};
    for (final row in (bookmarks as List)) {
      final rawId = row['daily_look_id'];
      final id = rawId is num ? rawId.toInt() : int.tryParse(rawId.toString());
      if (id == null) continue;
      bookmarkCounts[id] = (bookmarkCounts[id] ?? 0) + 1;
    }

    final bodySimilarByLookId = <int, bool>{};
    for (final row in filtered) {
      final rawId = row['id'];
      final id = rawId is num ? rawId.toInt() : int.tryParse(rawId.toString());
      if (id == null) continue;
      final profile = row['profiles'];
      if (profile is! Map) {
        bodySimilarByLookId[id] = false;
        continue;
      }
      bodySimilarByLookId[id] = _isBodySimilar(
        me: myProfile.toJson(),
        other: Map<String, dynamic>.from(profile),
      );
    }

    // Sort by selection
    filtered.sort((a, b) {
      final aRawId = a['id'];
      final bRawId = b['id'];
      final aId = aRawId is num ? aRawId.toInt() : int.tryParse(aRawId.toString()) ?? 0;
      final bId = bRawId is num ? bRawId.toInt() : int.tryParse(bRawId.toString()) ?? 0;

      // Highest priority: same body type/similarity first.
      final aBodySimilar = bodySimilarByLookId[aId] == true;
      final bBodySimilar = bodySimilarByLookId[bId] == true;
      if (aBodySimilar != bBodySimilar) {
        return bBodySimilar ? 1 : -1;
      }

      if (sortBy == 'popular') {
        final aScore = (likeCounts[aId] ?? 0) + (bookmarkCounts[aId] ?? 0);
        final bScore = (likeCounts[bId] ?? 0) + (bookmarkCounts[bId] ?? 0);
        if (aScore != bScore) return bScore.compareTo(aScore);
      }

      final aCreated = DateTime.tryParse((a['created_at'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bCreated = DateTime.tryParse((b['created_at'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bCreated.compareTo(aCreated);
    });

    return filtered;
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
    int? outerItemId,
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
      'outer_item_id': outerItemId,
      'shoes_item_id': shoesItemId,
      'hat_item_id': hatItemId,
      'bag_item_id': bagItemId,
      'accessory_item_id': accessoryItemId,
    };

    final linkedItemIds = [
      topItemId,
      bottomItemId,
      outerItemId,
      shoesItemId,
      hatItemId,
      bagItemId,
      accessoryItemId,
    ].whereType<int>().toSet().toList();

    if (id == null) {
      await _insertDailyLookWithSchemaFallback(payload);
      await _incrementWearCountForItems(linkedItemIds);
      return;
    }

    late final List<dynamic> previousRows;
    try {
      previousRows = await _supabase
          .from('daily_looks')
          .select('top_item_id, bottom_item_id, outer_item_id, shoes_item_id, hat_item_id, bag_item_id, accessory_item_id')
          .eq('id', id)
          .limit(1);
    } on PostgrestException catch (e) {
      if (!e.message.contains("'outer_item_id' column")) rethrow;
      previousRows = await _supabase
          .from('daily_looks')
          .select('top_item_id, bottom_item_id, shoes_item_id, hat_item_id, bag_item_id, accessory_item_id')
          .eq('id', id)
          .limit(1);
    }
    final previousLook = previousRows.isNotEmpty
      ? Map<String, dynamic>.from(previousRows.first as Map)
      : <String, dynamic>{};
    final previousLinkedItemIds = [
      previousLook['top_item_id'],
      previousLook['bottom_item_id'],
      previousLook['outer_item_id'],
      previousLook['shoes_item_id'],
      previousLook['hat_item_id'],
      previousLook['bag_item_id'],
      previousLook['accessory_item_id'],
    ].map((raw) {
      if (raw is num) return raw.toInt();
      return int.tryParse(raw?.toString() ?? '');
    }).whereType<int>().toSet();

    await _updateDailyLookWithSchemaFallback(id, payload);
    final newlyAddedItemIds = linkedItemIds.where((itemId) => !previousLinkedItemIds.contains(itemId)).toList();
    await _incrementWearCountForItems(newlyAddedItemIds);

  }

  static Future<void> updateLookVisibility({
    required int id,
    required bool isPublic,
  }) async {
    await _supabase
        .from('daily_looks')
        .update({'is_public': isPublic})
        .eq('id', id);
  }

  static Future<void> _incrementWearCountForItems(List<int> itemIds) async {
    if (itemIds.isEmpty) return;
    try {
      final clothes = await SupabaseService.fetchClothesByIds(itemIds);
      for (final row in clothes) {
        final rawId = row['id'];
        final id = rawId is num ? rawId.toInt() : int.tryParse(rawId.toString());
        if (id == null) continue;
        final current = row['wear_count'] is num
            ? (row['wear_count'] as num).toInt()
            : int.tryParse(row['wear_count']?.toString() ?? '0') ?? 0;
        await SupabaseService.incrementWearCount(
          id: id,
          currentWearCount: current,
        );
      }
    } catch (_) {
      // Keep daily look save successful even if wear count sync fails.
    }
  }

  static String? _extractMissingColumn(PostgrestException error) {
    final match = RegExp("'([^']+)' column").firstMatch(error.message);
    return match?.group(1);
  }

  static Future<void> _insertDailyLookWithSchemaFallback(Map<String, dynamic> payload) async {
    final mutable = Map<String, dynamic>.from(payload);
    for (var i = 0; i < 8; i++) {
      try {
        await _supabase.from('daily_looks').insert(mutable);
        return;
      } on PostgrestException catch (e) {
        final missingColumn = _extractMissingColumn(e);
        if (missingColumn == null || !mutable.containsKey(missingColumn)) {
          rethrow;
        }
        mutable.remove(missingColumn);
      }
    }
    await _supabase.from('daily_looks').insert(mutable);
  }

  static Future<void> _updateDailyLookWithSchemaFallback(int id, Map<String, dynamic> payload) async {
    final mutable = Map<String, dynamic>.from(payload);
    for (var i = 0; i < 8; i++) {
      try {
        await _supabase.from('daily_looks').update(mutable).eq('id', id);
        return;
      } on PostgrestException catch (e) {
        final missingColumn = _extractMissingColumn(e);
        if (missingColumn == null || !mutable.containsKey(missingColumn)) {
          rethrow;
        }
        mutable.remove(missingColumn);
      }
    }
    await _supabase.from('daily_looks').update(mutable).eq('id', id);
  }

  static Future<Map<String, dynamic>> getReactionSummary(int dailyLookId) async {
    final userId = _supabase.auth.currentUser?.id;
    final rows = await _supabase
        .from('daily_look_reactions')
        .select('reaction_type, user_id')
        .eq('daily_look_id', dailyLookId);
    final bookmarkRows = await _supabase
      .from('daily_look_bookmarks')
      .select('id')
      .eq('daily_look_id', dailyLookId);

    final list = rows as List;
    final likes = list.where((e) => e['reaction_type'] == 'like').length;
    final dislikes = list.where((e) => e['reaction_type'] == 'dislike').length;
    final bookmarkCount = (bookmarkRows as List).length;

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
      'bookmarkCount': bookmarkCount,
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

  /// Follow/Following methods
  static Future<bool> isFollowing(String userId) async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null || myId == userId) return false;

    try {
      final row = await _supabase
          .from('user_follows')
          .select('id')
          .eq('user_id', myId)
          .eq('following_id', userId)
          .maybeSingle();
      return row != null;
    } catch (_) {
      return false;
    }
  }

  static Future<void> toggleFollow(String userId) async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null || myId == userId) throw Exception('자신을 팔로우할 수 없습니다.');

    final existing = await _supabase
        .from('user_follows')
        .select('id')
        .eq('user_id', myId)
        .eq('following_id', userId)
        .maybeSingle()
        .catchError((_) => null);

    if (existing == null) {
      // Follow
      try {
        await _supabase.from('user_follows').insert({
          'user_id': myId,
          'following_id': userId,
        });
      } catch (_) {
        // Table might not exist yet, silently fail
      }
    } else {
      // Unfollow
      try {
        await _supabase
            .from('user_follows')
            .delete()
            .eq('id', existing['id']);
      } catch (_) {
        // Silently fail
      }
    }
  }

  static Future<Map<String, dynamic>> getUserStats(String userId) async {
    int followers = 0;
    int following = 0;
    int posts = 0;

    try {
      final followersRows = await _supabase
          .from('user_follows')
          .select('id')
          .eq('following_id', userId)
          .count(CountOption.exact);
      followers = followersRows.count;
    } catch (_) {
      // Silently fail
    }

    try {
      final followingRows = await _supabase
          .from('user_follows')
          .select('id')
          .eq('user_id', userId)
          .count(CountOption.exact);
      following = followingRows.count;
    } catch (_) {
      // Silently fail
    }

    try {
      final postsRows = await _supabase
          .from('daily_looks')
          .select('id')
          .eq('user_id', userId)
          .eq('is_public', true)
          .count(CountOption.exact);
      posts = postsRows.count;
    } catch (_) {
      // Silently fail
    }

    return {
      'followers': followers,
      'following': following,
      'posts': posts,
    };
  }
}
