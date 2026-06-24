import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/outfit.dart';
import '../services/outfit_service.dart';

class OutfitDetailPage extends StatefulWidget {
  final Outfit outfit;
  final bool isOwnOutfit;

  const OutfitDetailPage({
    super.key,
    required this.outfit,
    this.isOwnOutfit = false,
  });

  @override
  State<OutfitDetailPage> createState() => _OutfitDetailPageState();
}

class _OutfitDetailPageState extends State<OutfitDetailPage> {
  late bool isLiked;
  late bool isSaved;
  int likesCount = 0;

  @override
  void initState() {
    super.initState();
    isLiked = false;
    isSaved = false;
    likesCount = widget.outfit.likesCount;
  }

  Future<void> toggleLike() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      if (isLiked) {
        await OutfitService.unlikeOutfit(userId, widget.outfit.id);
        setState(() {
          isLiked = false;
          likesCount--;
        });
      } else {
        await OutfitService.likeOutfit(userId, widget.outfit.id);
        setState(() {
          isLiked = true;
          likesCount++;
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> toggleSave() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      if (!isSaved) {
        await OutfitService.saveOutfit(userId, widget.outfit.id);
        setState(() => isSaved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('코디가 저장되었습니다!')),
        );
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.outfit.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.outfit.imageUrl != null)
              Image.network(widget.outfit.imageUrl!, height: 400, fit: BoxFit.cover)
            else
              Container(
                height: 400,
                color: Colors.grey[300],
                child: const Center(child: Icon(Icons.image)),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.outfit.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                      const SizedBox(width: 4),
                      Text('$likesCount'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: toggleLike,
                          icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border),
                          label: Text(isLiked ? '좋아요 취소' : '좋아요'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: toggleSave,
                          icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
                          label: Text(isSaved ? '저장됨' : '저장'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}