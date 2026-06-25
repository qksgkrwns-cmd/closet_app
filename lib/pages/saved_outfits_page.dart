import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'clothes_detail_page.dart';

class SavedOutfitsPage extends StatefulWidget {
  const SavedOutfitsPage({super.key});

  @override
  State<SavedOutfitsPage> createState() => _SavedOutfitsPageState();
}

class _SavedOutfitsPageState extends State<SavedOutfitsPage> {
  late Future<List<dynamic>> savedOutfitsFuture;

  @override
  void initState() {
    super.initState();
    _loadSavedOutfits();
  }

  Future<void> _loadSavedOutfits() async {
    savedOutfitsFuture = SupabaseService.fetchBookmarkedClothes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('저장된 코디')),
      body: FutureBuilder<List<dynamic>>(
        future: savedOutfitsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('북마크한 옷이 없습니다.'));
          }
          final clothes = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: clothes.length,
            itemBuilder: (context, index) {
              final item = clothes[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClothesDetailPage(
                        item: item,
                        isReadOnly: true,
                      ),
                    ),
                  );
                },
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: item['image_url'] != null
                            ? Image.network(item['image_url'], fit: BoxFit.cover)
                            : Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.checkroom, size: 40),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          (item['brand'] ?? 'No Brand').toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}