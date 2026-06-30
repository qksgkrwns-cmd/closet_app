import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;

class SupabaseService {
  static final _supabase = Supabase.instance.client;

  static Future<List<dynamic>> fetchClothes({String? category, String? userId}) async {
    var query = _supabase.from('clothes').select();
    final normalizedCategory = category?.trim();
    final isAllCategory = normalizedCategory == null ||
        normalizedCategory.isEmpty ||
        normalizedCategory == 'all' ||
        normalizedCategory == '전체';

    if (!isAllCategory) {
      // 대분류로 필터링 (예: "상의"를 선택하면 "상의", "상의/반팔티" 등 모두 포함)
      query = query.filter('category', 'like', '$normalizedCategory%');
    }

    // 기본: 현재 로그인된 사용자의 옷만 반환 (내 옷장)
    final effectiveUserId = userId ?? _supabase.auth.currentUser?.id;
    if (effectiveUserId != null) {
      query = query.eq('user_id', effectiveUserId);
    }

    try {
      return await query.order('created_at', ascending: false);
    } on PostgrestException catch (e) {
      if (e.message.contains('row-level security')) {
        throw Exception('목록 조회 권한이 없습니다. clothes SELECT RLS 정책을 추가하세요.');
      }
      if (e.message.contains('created_at')) {
        return await query;
      }
      rethrow;
    }
  }

  static Future<void> saveClothes({
    required String category,
    required String brand,
    required String color,
    required List<String> seasons,
    String? size,
    DateTime? purchaseDate,
    int? purchasePrice,
    String? comment,
    File? imageFile,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    String? imageUrl;
    if (imageFile != null) {
      try {
        imageUrl = await uploadImage(imageFile, userId: currentUserId);
      } on StorageException catch (e) {
        final isRls403 =
            '${e.statusCode}' == '403' || e.message.contains('row-level security');
        if (isRls403) {
          // Storage policy misconfigured: continue saving metadata without image.
          imageUrl = null;
        } else {
          rethrow;
        }
      }
    }

    final payload = {
      'user_id': currentUserId,
      'category': category,
      'brand': brand,
      'color': color,
      'seasons': seasons,
      'size': size?.trim().isEmpty == true ? null : size?.trim(),
      'image_url': imageUrl,
      'purchase_date': purchaseDate?.toIso8601String(),
      'purchase_price': purchasePrice,
      'comment': comment?.trim().isEmpty == true ? null : comment?.trim(),
      'wear_count': 0,
    };

    try {
      await _insertWithSchemaFallback(payload);
    } on PostgrestException catch (e) {
      if (e.message.contains('row-level security')) {
        throw Exception('DB 권한 오류: row-level security로 인해 삽입이 거부되었습니다. Supabase에 적절한 RLS 정책을 추가하세요.');
      }
      rethrow;
    }
  }

  static Future<void> updateClothes({
    required int id,
    required String category,
    required String brand,
    required String color,
    required List<String> seasons,
    String? size,
    DateTime? purchaseDate,
    int? purchasePrice,
    String? comment,
    File? newImageFile,
    String? oldImageUrl,
  }) async {
    String? imageUrl = oldImageUrl;
    if (newImageFile != null) {
      if (oldImageUrl != null) {
        await deleteImage(oldImageUrl);
      }
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('로그인이 필요합니다.');
      }
      imageUrl = await uploadImage(newImageFile, userId: currentUserId);
    }
    final payload = {
      'category': category,
      'brand': brand,
      'color': color,
      'seasons': seasons,
      'size': size?.trim().isEmpty == true ? null : size?.trim(),
      'image_url': imageUrl,
      'purchase_date': purchaseDate?.toIso8601String(),
      'purchase_price': purchasePrice,
      'comment': comment?.trim().isEmpty == true ? null : comment?.trim(),
    };

    await _updateWithSchemaFallback(id, payload);
  }

  static Future<int?> incrementWearCount({
    required int id,
    required int currentWearCount,
  }) async {
    final nextCount = currentWearCount + 1;
    try {
      await _supabase.from('clothes').update({'wear_count': nextCount}).eq('id', id);
    } on PostgrestException catch (e) {
      if (e.message.contains('wear_count')) {
        throw Exception('DB에 wear_count 컬럼이 없어 착용횟수를 저장할 수 없습니다.');
      }
      rethrow;
    }

    return nextCount;
  }

  static Future<void> deleteClothes(Map item) async {
    final imageUrl = item['image_url'];
    if (imageUrl != null) {
      await deleteImage(imageUrl);
    }
    await _supabase.from('clothes').delete().eq('id', item['id']);
  }

  static Future<String> uploadImage(File imageFile, {required String userId}) async {
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    final processed = decoded == null
        ? bytes
        : img.encodeJpg(
            img.copyResize(
              img.bakeOrientation(decoded),
              width: decoded.width > 960 ? 960 : decoded.width,
            ),
            quality: 70,
          );
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final objectPath = '$userId/$fileName';
    await _supabase.storage.from('clothes').uploadBinary(
          objectPath,
          processed,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
        );
    return _supabase.storage.from('clothes').getPublicUrl(objectPath);
  }

  static Future<void> deleteImage(String imageUrl) async {
    final objectPath = _extractStorageObjectPath(imageUrl);
    if (objectPath == null) return;
    await _supabase.storage.from('clothes').remove([objectPath]);
  }

  static String? _extractStorageObjectPath(String imageUrl) {
    final uri = Uri.tryParse(imageUrl);
    if (uri == null) return null;
    final bucketIndex = uri.pathSegments.indexOf('clothes');
    if (bucketIndex == -1 || bucketIndex + 1 >= uri.pathSegments.length) return null;
    return uri.pathSegments.sublist(bucketIndex + 1).join('/');
  }

  static String? _extractMissingColumn(PostgrestException error) {
    final match = RegExp("'([^']+)' column").firstMatch(error.message);
    return match?.group(1);
  }

  static Future<void> _insertWithSchemaFallback(Map<String, dynamic> payload) async {
    final mutable = Map<String, dynamic>.from(payload);
    for (var i = 0; i < 8; i++) {
      try {
        await _supabase.from('clothes').insert(mutable);
        return;
      } on PostgrestException catch (e) {
        final missingColumn = _extractMissingColumn(e);
        if (missingColumn == null || !mutable.containsKey(missingColumn)) {
          rethrow;
        }
        mutable.remove(missingColumn);
      }
    }
    await _supabase.from('clothes').insert(mutable);
  }

  static Future<void> _updateWithSchemaFallback(int id, Map<String, dynamic> payload) async {
    final mutable = Map<String, dynamic>.from(payload);
    for (var i = 0; i < 8; i++) {
      try {
        await _supabase.from('clothes').update(mutable).eq('id', id);
        return;
      } on PostgrestException catch (e) {
        final missingColumn = _extractMissingColumn(e);
        if (missingColumn == null || !mutable.containsKey(missingColumn)) {
          rethrow;
        }
        mutable.remove(missingColumn);
      }
    }
    await _supabase.from('clothes').update(mutable).eq('id', id);
  }

  static Future<int> getClothesLikesCount(int clothesId) async {
    final response = await _supabase
        .from('clothes_likes')
        .select('id')
        .eq('clothes_id', clothesId);
    return (response as List).length;
  }

  static Future<bool> isClothesLiked(int clothesId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;
    final response = await _supabase
        .from('clothes_likes')
        .select('id')
        .eq('clothes_id', clothesId)
        .eq('user_id', userId)
        .limit(1);
    return (response as List).isNotEmpty;
  }

  static Future<void> likeClothes(int clothesId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다.');
    await _supabase.from('clothes_likes').insert({
      'clothes_id': clothesId,
      'user_id': userId,
    });
  }

  static Future<void> unlikeClothes(int clothesId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다.');
    await _supabase
        .from('clothes_likes')
        .delete()
        .eq('clothes_id', clothesId)
        .eq('user_id', userId);
  }

  static Future<bool> isClothesBookmarked(int clothesId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;
    final response = await _supabase
        .from('saved_clothes')
        .select('id')
        .eq('clothes_id', clothesId)
        .eq('user_id', userId)
        .limit(1);
    return (response as List).isNotEmpty;
  }

  static Future<void> bookmarkClothes(int clothesId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다.');
    final alreadySaved = await _supabase
        .from('saved_clothes')
        .select('id')
        .eq('clothes_id', clothesId)
        .eq('user_id', userId)
        .limit(1);
    if ((alreadySaved as List).isNotEmpty) return;

    await _supabase.from('saved_clothes').insert({
      'clothes_id': clothesId,
      'user_id': userId,
    });
  }

  static Future<void> unbookmarkClothes(int clothesId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다.');
    await _supabase
        .from('saved_clothes')
        .delete()
        .eq('clothes_id', clothesId)
        .eq('user_id', userId);
  }

  static Future<List<dynamic>> fetchBookmarkedClothes() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('saved_clothes')
        .select('clothes(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => row['clothes'])
        .where((row) => row != null)
        .toList();
  }

  static Future<List<dynamic>> fetchClothesByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    return await _supabase
        .from('clothes')
        .select()
        .inFilter('id', ids)
        .order('created_at', ascending: false);
  }
}