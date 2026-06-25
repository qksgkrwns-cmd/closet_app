import 'package:flutter/material.dart';
import '../models/outfit.dart';
import '../services/outfit_service.dart';
import '../widgets/outfit_card.dart';

class UserClosetPage extends StatefulWidget {
  final String userId;
  final String userName;

  const UserClosetPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserClosetPage> createState() => _UserClosetPageState();
}

class _UserClosetPageState extends State<UserClosetPage> {
  late Future<List<Outfit>> outfitsFuture;

  @override
  void initState() {
    super.initState();
    outfitsFuture = OutfitService.getUserOutfits(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.userName}의 옷장')),
      body: FutureBuilder<List<Outfit>>(
        future: outfitsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('코디가 없습니다.'));
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
              final outfit = outfits[index];
              return OutfitCard(outfit: outfit);
            },
          );
        },
      ),
    );
  }
}