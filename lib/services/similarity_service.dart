import '../models/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SimilarityService {
  static Future<List<Map<String, dynamic>>> findSimilarUsers(
    Profile currentProfile,
  ) async {
    try {
      final supabase = Supabase.instance.client;
      final allProfiles = await supabase.from('profiles').select();

      List<Map<String, dynamic>> similarUsers = [];

      for (var profileJson in allProfiles) {
        if (profileJson['id'] == currentProfile.id) continue;

        final profile = Profile.fromJson(profileJson);
        final score = _calculateSimilarity(currentProfile, profile);

        if (score > 0.3) {
          similarUsers.add({
            'profile': profile,
            'similarity_score': score,
          });
        }
      }

      similarUsers.sort(
        (a, b) => (b['similarity_score'] as double)
            .compareTo(a['similarity_score'] as double),
      );

      return similarUsers.take(10).toList();
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  static double _calculateSimilarity(Profile profile1, Profile profile2) {
    double score = 0.0;

    if (profile1.bodyType == profile2.bodyType) score += 0.3;
    if (profile1.skinTone == profile2.skinTone) score += 0.2;

    final commonStyles = profile1.stylePreferences
        .where((style) => profile2.stylePreferences.contains(style))
        .length;
    score += (commonStyles / (profile1.stylePreferences.length + profile2.stylePreferences.length)) * 0.5;

    return score;
  }
}