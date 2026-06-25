import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import '../services/supabase_service.dart';
import 'add_clothes_page.dart';
import 'clothes_detail_page.dart';
import 'profile_setup_page.dart';
import 'similar_users_page.dart';
import 'saved_outfits_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedFilter = '전체';
  String searchKeyword = '';
  List<dynamic> clothes = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    loadClothes();
  }

  Future<void> _onTapSimilarUsers() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    final profile = await ProfileService.getCurrentProfile();
    final isComplete = ProfileService.isProfileComplete(profile);

    if (!isComplete) {
      if (!mounted) return;
      final shouldSetup = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('프로필 보완'),
          content: const Text('비슷한 사람 추천을 위해 체형/피부톤/스타일 정보를 입력해주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('나중에'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('지금 입력'),
            ),
          ],
        ),
      );

      if (shouldSetup != true || !mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfileSetupPage(),
        ),
      );

      final refreshed = await ProfileService.getCurrentProfile();
      if (!ProfileService.isProfileComplete(refreshed) || !mounted) return;
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SimilarUsersPage(),
      ),
    );
  }

  Future<void> loadClothes() async {
    try {
      final data = await SupabaseService.fetchClothes(
        category: selectedFilter,
      );
      setState(() {
        clothes = data;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  List<dynamic> getFilteredClothes() {
    return clothes.where((item) {
      if (searchKeyword.isEmpty) return true;
      final keyword = searchKeyword.toLowerCase();
      final category = (item['category'] ?? '').toString().toLowerCase();
      final color = (item['color'] ?? '').toString().toLowerCase();
      final brand = (item['brand'] ?? '').toString().toLowerCase();
      return category.contains(keyword) ||
          color.contains(keyword) ||
          brand.contains(keyword);
    }).toList();
  }

  String _formatCreatedAt(dynamic raw) {
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    if (parsed == null) return '';
    return '${parsed.year}.${parsed.month}.${parsed.day}';
  }

  @override
  Widget build(BuildContext context) {
    final filteredClothes = getFilteredClothes();
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 옷장'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileSetupPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: '카테고리, 브랜드, 색상 검색',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchKeyword = value;
                });
              },
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['전체', '상의', '하의', '아우터', '신발', '모자']
                  .map((category) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: selectedFilter == category,
                        onSelected: (_) {
                          setState(() {
                            selectedFilter = category;
                          });
                          loadClothes();
                        },
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.58,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: filteredClothes.length,
              itemBuilder: (context, index) {
                final item = filteredClothes[index];
                return InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClothesDetailPage(item: item),
                      ),
                    );
                    loadClothes();
                  },
                  onLongPress: () async {
                    final shouldDelete = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('삭제'),
                        content: const Text('이 옷을 삭제할까요?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('삭제'),
                          ),
                        ],
                      ),
                    );

                    if (shouldDelete == true) {
                      await SupabaseService.deleteClothes(item);
                      loadClothes();
                    }
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
                                  child: const Icon(Icons.checkroom, size: 32),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                          child: Text(
                            (item['brand'] ?? 'No Brand').toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                          child: Text(
                            _formatCreatedAt(item['created_at']),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddClothesPage(),
            ),
          );
          loadClothes();
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '옷장'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: '비슷한 사람'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: '저장됨'),
        ],
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 1) {
            _onTapSimilarUsers();
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SavedOutfitsPage(),
              ),
            );
          }
        },
      ),
    );
  }
}