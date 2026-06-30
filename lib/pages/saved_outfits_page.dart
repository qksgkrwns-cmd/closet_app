import 'package:flutter/material.dart';
import '../services/daily_look_service.dart';
import '../services/supabase_service.dart';
import '../widgets/app_network_image.dart';
import '../widgets/empty_state_view.dart';
import 'clothes_detail_page.dart';
import 'daily_look_detail_page.dart';

class SavedOutfitsPage extends StatefulWidget {
  const SavedOutfitsPage({super.key});

  @override
  State<SavedOutfitsPage> createState() => _SavedOutfitsPageState();
}

class _SavedOutfitsPageState extends State<SavedOutfitsPage> {
  late Future<List<dynamic>> savedOutfitsFuture;
  late Future<List<dynamic>> savedLooksFuture;

  @override
  void initState() {
    super.initState();
    _loadSavedOutfits();
  }

  Future<void> _loadSavedOutfits() async {
    savedOutfitsFuture = SupabaseService.fetchBookmarkedClothes();
    savedLooksFuture = DailyLookService.fetchBookmarkedLooks();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('보관함'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '아이템'),
              Tab(text: '데일리룩'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            FutureBuilder<List<dynamic>>(
              future: savedOutfitsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.checkroom,
                    title: '저장된 아이템이 없습니다.',
                    subtitle: '홈 화면에서 하트를 눌러 보관해보세요.',
                  );
                }
                final clothes = snapshot.data!;
                return GridView.builder(
                  key: const PageStorageKey<String>('saved-items-grid'),
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.58,
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
                              child: AppNetworkImage(
                                imageUrl: item['image_url']?.toString(),
                                fit: BoxFit.cover,
                                fallbackIcon: Icons.checkroom,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                (item['brand'] ?? 'No Brand').toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
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
            FutureBuilder<List<dynamic>>(
              future: savedLooksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.photo_library_outlined,
                    title: '저장된 데일리룩이 없습니다.',
                    subtitle: '피드에서 북마크한 룩이 여기에 표시됩니다.',
                  );
                }

                final looks = snapshot.data!;
                return GridView.builder(
                  key: const PageStorageKey<String>('saved-looks-grid'),
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.76,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: looks.length,
                  itemBuilder: (context, index) {
                    final look = Map<String, dynamic>.from(looks[index]);
                    final content = (look['content'] ?? '').toString();
                    final username = (look['profile_username'] ?? '사용자').toString();
                    final dateText = (look['wear_date'] ?? '').toString();

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DailyLookDetailPage(look: look),
                          ),
                        );
                      },
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: AppNetworkImage(
                                imageUrl: look['image_url']?.toString(),
                                fit: BoxFit.contain,
                                fallbackIcon: Icons.image_not_supported,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                              child: Text(
                                content,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '@$username',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  if (dateText.isNotEmpty)
                                    Text(
                                      dateText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                ],
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
          ],
        ),
      ),
    );
  }
}