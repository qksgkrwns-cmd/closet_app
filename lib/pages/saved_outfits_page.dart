import 'package:flutter/material.dart';
import '../services/outfit_service.dart';
import '../models/outfit.dart';
import '../widgets/outfit_card.dart';

class SavedOutfitsPage extends StatefulWidget {
  const SavedOutfitsPage({super.key});

  @override
  State<SavedOutfitsPage> createState() => _SavedOutfitsPageState();
}

class _SavedOutfitsPageState extends State<SavedOutfitsPage> {
  late Future<List<Outfit>> savedOutfitsFuture;

  @override
  void initState() {
    super.initState();
    _loadSavedOutfits();
  }

  Future<void> _loadSavedOutfits() async {
    // TODO: Get current user ID from Supabase auth
    // savedOutfitsFuture = OutfitService.getSavedOutfits(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('저장된 코디')),
      body: FutureBuilder<List<Outfit>>(
        future: savedOutfitsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('저장된 코디가 없습니다.'));
          }
          final outfits = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: outfits.length,
            itemBuilder: (context, index) {
              return OutfitCard(outfit: outfits[index]);
            },
          );
        },
      ),
    );
  }
}