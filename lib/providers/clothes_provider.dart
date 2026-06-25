import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

final clothesProvider = FutureProvider<List<dynamic>>((ref) async {
  return await SupabaseService.fetchClothes();
});

final clothesByCategoryProvider = FutureProvider.family<List<dynamic>, String>((ref, category) async {
  return await SupabaseService.fetchClothes(category: category);
});
