import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'add_clothes_page.dart';
import 'clothes_detail_page.dart';
import 'profile_setup_page.dart';
import 'saved_outfits_page.dart';
import 'daily_look_calendar_page.dart';
import 'daily_look_feed_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Map<String, List<String>> _subcategoryMap = {
    '상의': ['전체', '반팔티', '긴팔티', '셔츠', '후드', '니트'],
    '하의': ['전체', '청바지', '면바지', '트레이닝', '치마'],
    '아우터': ['전체', '자켓', '코트', '점퍼'],
    '신발': ['전체', '스니커즈', '로퍼', '구두'],
    '모자': ['전체', '야구모', '비니'],
    '잡동사니': ['전체', '가방', '시계', '목도리', '장갑'],
  };

  String selectedFilter = '전체';
  String selectedSubFilter = '전체';
  String searchKeyword = '';
  List<dynamic> clothes = [];
  bool favoritesOnly = false;
  Map<int, bool> bookmarkStatus = {};
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    loadClothes();
  }

  Future<void> loadClothes() async {
    try {
      final data = await SupabaseService.fetchClothes(
        category: selectedFilter,
      );
      setState(() {
        clothes = data;
      });
      await _loadBookmarkStatus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  List<dynamic> getFilteredClothes() {
    return clothes.where((item) {
      final rawId = item['id'];
      final itemId = rawId is num ? rawId.toInt() : int.tryParse(rawId.toString());
      
      if (favoritesOnly && itemId != null && !bookmarkStatus.containsKey(itemId)) {
        return false;
      }
      if (favoritesOnly && itemId != null && bookmarkStatus[itemId] != true) {
        return false;
      }

      final fullCategory = (item['category'] ?? '').toString();
      final split = fullCategory.split('/');
      final parentCategory = split.isNotEmpty ? split.first : fullCategory;
      final subCategory = split.length > 1 ? split[1] : parentCategory;

      if (selectedFilter != '전체' && parentCategory != selectedFilter) {
        return false;
      }
      if (selectedSubFilter != '전체' && subCategory != selectedSubFilter) {
        return false;
      }
      
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

  Future<void> _loadBookmarkStatus() async {
    final ids = clothes.map((item) {
      final rawId = item['id'];
      return rawId is num ? rawId.toInt() : int.tryParse(rawId.toString());
    }).whereType<int>().toList();

    final status = <int, bool>{};
    for (final id in ids) {
      try {
        status[id] = await SupabaseService.isClothesBookmarked(id);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => bookmarkStatus = status);
  }

  Future<void> _toggleBookmark(int id) async {
    try {
      if (bookmarkStatus[id] == true) {
        await SupabaseService.unbookmarkClothes(id);
        setState(() => bookmarkStatus[id] = false);
      } else {
        await SupabaseService.bookmarkClothes(id);
        setState(() => bookmarkStatus[id] = true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('즐겨찾기 처리 실패: $e')),
      );
    }
  }

  List<String> _currentSubcategories() {
    if (selectedFilter == '전체') return const [];
    return _subcategoryMap[selectedFilter] ?? const ['전체'];
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
                suffixIcon: IconButton(
                  tooltip: '즐겨찾기만 보기',
                  onPressed: () {
                    setState(() => favoritesOnly = !favoritesOnly);
                  },
                  icon: Icon(
                    favoritesOnly ? Icons.favorite : Icons.favorite_border,
                    color: favoritesOnly ? Colors.red : null,
                  ),
                ),
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
              children: ['전체', '상의', '하의', '아우터', '신발', '모자', '잡동사니']
                  .map((category) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: selectedFilter == category,
                        onSelected: (_) {
                          setState(() {
                            selectedFilter = category;
                            selectedSubFilter = '전체';
                          });
                          loadClothes();
                        },
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: selectedFilter == '전체' ? 0 : 50,
            child: selectedFilter == '전체'
                ? const SizedBox.shrink()
                : ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: _currentSubcategories()
                        .map(
                          (sub) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(sub),
                              selected: selectedSubFilter == sub,
                              onSelected: (_) {
                                setState(() => selectedSubFilter = sub);
                              },
                            ),
                          ),
                        )
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
                final rawId = item['id'];
                final itemId = rawId is num ? rawId.toInt() : int.tryParse(rawId.toString());
                final isBookmarked = itemId != null && bookmarkStatus[itemId] == true;
                
                return InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClothesDetailPage(
                          item: item,
                          isReadOnly: false,
                        ),
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
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              item['image_url'] != null
                                  ? Image.network(item['image_url'], fit: BoxFit.cover)
                                  : Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.checkroom, size: 32),
                                    ),
                              Positioned(
                                bottom: 6,
                                right: 6,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: itemId == null ? null : () => _toggleBookmark(itemId),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.95),
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(6),
                                      child: Icon(
                                        isBookmarked ? Icons.favorite : Icons.favorite_border,
                                        color: isBookmarked ? Colors.red : Colors.grey,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: '데일리룩'),
          BottomNavigationBarItem(icon: Icon(Icons.dynamic_feed), label: '피드'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: '저장됨'),
        ],
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DailyLookCalendarPage(),
              ),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DailyLookFeedPage(),
              ),
            );
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