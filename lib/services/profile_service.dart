import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/profile.dart';

class ProfileService {
  static final _supabase = Supabase.instance.client;

  static Future<Profile?> getCurrentProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return Profile.fromJson(response);
    } catch (e) {
      debugPrint('Error: $e');
      return null;
    }
  }

  static Future<void> ensureDefaultProfile(User user) async {
    final existing = await getCurrentProfile();
    if (existing != null) return;

    final defaultProfile = Profile(
      id: user.id,
      username: user.email?.split('@').first ?? 'user_${user.id.substring(0, 6)}',
      bodyType: '미설정',
      skinTone: '미설정',
      stylePreferences: const [],
      createdAt: DateTime.now(),
    );

    await saveProfile(defaultProfile);
  }

  static bool isProfileComplete(Profile? profile) {
    if (profile == null) return false;
    if (profile.bodyType == '미설정' || profile.skinTone == '미설정') return false;
    return profile.stylePreferences.isNotEmpty;
  }

  static Future<void> saveProfile(Profile profile) async {
    final base = profile.toJson();

    try {
      await _supabase.from('profiles').upsert(base);
      return;
    } on PostgrestException catch (e) {
      // Some environments use different column names for style preferences.
      if (!e.message.contains('style_preferences')) rethrow;
    }

    final withStylePreference = Map<String, dynamic>.from(base)
      ..remove('style_preferences')
      ..['style_preference'] = profile.stylePreferences;
    try {
      await _supabase.from('profiles').upsert(withStylePreference);
      return;
    } on PostgrestException catch (e) {
      if (!e.message.contains('style_preference')) rethrow;
    }

    final withStyles = Map<String, dynamic>.from(base)
      ..remove('style_preferences')
      ..['styles'] = profile.stylePreferences;
    try {
      await _supabase.from('profiles').upsert(withStyles);
      return;
    } on PostgrestException catch (e) {
      if (!e.message.contains('styles')) rethrow;
    }

    // Last resort: save without style field so core profile can still be created.
    final withoutStyles = Map<String, dynamic>.from(base)..remove('style_preferences');
    await _supabase.from('profiles').upsert(withoutStyles);
  }

  static Future<Profile?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return Profile.fromJson(response);
    } catch (e) {
      debugPrint('Error: $e');
      return null;
    }
  }
}