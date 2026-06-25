import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/outfit.dart';
import '../services/outfit_service.dart';

final outfitsProvider = FutureProvider.family<List<Outfit>, String>((ref, userId) async {
  return await OutfitService.getUserOutfits(userId);
});

final savedOutfitsProvider = FutureProvider.family<List<Outfit>, String>((ref, userId) async {
  return await OutfitService.getSavedOutfits(userId);
});
