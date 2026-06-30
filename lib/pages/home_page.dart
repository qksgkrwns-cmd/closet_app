import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import '../services/supabase_service.dart';
import '../widgets/color_selector.dart';
import '../widgets/app_network_image.dart';
import '../widgets/empty_state_view.dart';
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
    '상의': ['전체', '반팔티', '긴팔티', '셔츠', '맨투맨', '후드', '니트', '블라우스'],
    '하의': ['전체', '청바지', '슬랙스', '면바지', '반바지', '치마', '트레이닝', '레깅스'],
    '아우터': ['전체', '자켓', '코트', '패딩', '가디건', '점퍼', '바람막이', '베스트'],
    '신발': ['전체', '스니커즈', '로퍼', '구두', '샌들', '부츠', '슬리퍼', '런닝화'],
    '모자': ['전체', '볼캡', '버킷햇', '비니', '베레모', '페도라', '썬캡', '니트모자'],
    '잡동사니': ['전체', '가방', '시계', '목도리', '장갑', '벨트', '양말', '선글라스'],
  };

  String selectedFilter = '전체';
  String selectedSubFilter = '전체';
  String searchKeyword = '';
  List<dynamic> clothes = [];
  bool favoritesOnly = false;
  String sortOption = '최신 등록순';
  final Set<String> selectedColors = {};
  final Set<String> selectedSeasons = {};
  String wearFilter = '전체';
  Map<int, bool> bookmarkStatus = {};
  int _selectedIndex = 0;
  bool _showProfileSetupBanner = false;

  @override
  void initState() {
    super.initState();
    loadClothes();
    _loadProfileCompletionState();
  }

  Future<void> _loadProfileCompletionState() async {
    final profile = await ProfileService.getCurrentProfile();
    if (!mounted) return;
    setState(() {
      _showProfileSetupBanner = !ProfileService.isProfileComplete(profile);
    });
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
    final filtered = clothes.where((item) {
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

      if (selectedColors.isNotEmpty) {
        final normalized = normalizeColorLabel(item['color']?.toString());
        if (!selectedColors.contains(normalized)) return false;
      }

      if (selectedSeasons.isNotEmpty) {
        final seasons = ((item['seasons'] as List?) ?? const [])
            .map((e) => e.toString())
            .toSet();
        if (!selectedSeasons.any((season) => seasons.contains(season))) {
          return false;
        }
      }

      final wearCount = (item['wear_count'] is num)
          ? (item['wear_count'] as num).toInt()
          : int.tryParse(item['wear_count']?.toString() ?? '0') ?? 0;
      if (wearFilter == '미착용' && wearCount > 0) return false;
      if (wearFilter == '착용완료' && wearCount == 0) return false;
      
      if (searchKeyword.isEmpty) return true;
      final keyword = searchKeyword.toLowerCase();
      final category = (item['category'] ?? '').toString().toLowerCase();
      final color = (item['color'] ?? '').toString().toLowerCase();
      final brand = (item['brand'] ?? '').toString().toLowerCase();
      return category.contains(keyword) ||
          color.contains(keyword) ||
          brand.contains(keyword);
    }).toList();

    filtered.sort((a, b) {
      final aBrand = (a['brand'] ?? '').toString().toLowerCase();
      final bBrand = (b['brand'] ?? '').toString().toLowerCase();
      final aWear = (a['wear_count'] is num)
          ? (a['wear_count'] as num).toInt()
          : int.tryParse(a['wear_count']?.toString() ?? '0') ?? 0;
      final bWear = (b['wear_count'] is num)
          ? (b['wear_count'] as num).toInt()
          : int.tryParse(b['wear_count']?.toString() ?? '0') ?? 0;
      final aCreated = DateTime.tryParse((a['created_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bCreated = DateTime.tryParse((b['created_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);

      switch (sortOption) {
        case '오래된 등록순':
          return aCreated.compareTo(bCreated);
        case '브랜드순':
          return aBrand.compareTo(bBrand);
        case '착용 많은순':
          return bWear.compareTo(aWear);
        case '착용 적은순':
          return aWear.compareTo(bWear);
        case '최신 등록순':
        default:
          return bCreated.compareTo(aCreated);
      }
    });

    return filtered;
  }

  Future<void> _showAdvancedFilterSheet() async {
    final tempColors = Set<String>.from(selectedColors);
    final tempSeasons = Set<String>.from(selectedSeasons);
    var tempWearFilter = wearFilter;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '필터',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempColors.clear();
                                tempSeasons.clear();
                                tempWearFilter = '전체';
                              });
                            },
                            child: const Text('초기화'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('색상', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: kSupportedColors
                            .map(
                              (color) => FilterChip(
                                label: Text(color),
                                selected: tempColors.contains(color),
                                onSelected: (selected) {
                                  setModalState(() {
                                    if (selected) {
                                      tempColors.add(color);
                                    } else {
                                      tempColors.remove(color);
                                    }
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text('계절', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: ['봄', '여름', '가을', '겨울']
                            .map(
                              (season) => FilterChip(
                                label: Text(season),
                                selected: tempSeasons.contains(season),
                                onSelected: (selected) {
                                  setModalState(() {
                                    if (selected) {
                                      tempSeasons.add(season);
                                    } else {
                                      tempSeasons.remove(season);
                                    }
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text('착용 상태', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['전체', '미착용', '착용완료']
                            .map(
                              (option) => ChoiceChip(
                                label: Text(option),
                                selected: tempWearFilter == option,
                                onSelected: (_) {
                                  setModalState(() => tempWearFilter = option);
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              selectedColors
                                ..clear()
                                ..addAll(tempColors);
                              selectedSeasons
                                ..clear()
                                ..addAll(tempSeasons);
                              wearFilter = tempWearFilter;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('적용'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
    final hasActiveAdvancedFilters = selectedColors.isNotEmpty || selectedSeasons.isNotEmpty || wearFilter != '전체';
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
              ).then((_) => _loadProfileCompletionState());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showProfileSetupBanner)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '프로필을 완성하면 추천 정확도가 올라갑니다.',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '성별, 체형, 스타일을 입력해 더 맞는 데일리룩 피드를 받아보세요.',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileSetupPage(),
                            ),
                          ).then((_) => _loadProfileCompletionState());
                        },
                        child: const Text('완성하기'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: sortOption,
                    decoration: const InputDecoration(
                      labelText: '정렬',
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: '최신 등록순', child: Text('최신 등록순')),
                      DropdownMenuItem(value: '오래된 등록순', child: Text('오래된 등록순')),
                      DropdownMenuItem(value: '브랜드순', child: Text('브랜드순')),
                      DropdownMenuItem(value: '착용 많은순', child: Text('착용 많은순')),
                      DropdownMenuItem(value: '착용 적은순', child: Text('착용 적은순')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => sortOption = value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _showAdvancedFilterSheet,
                  icon: const Icon(Icons.tune),
                  label: Text(
                    hasActiveAdvancedFilters
                        ? '필터 적용중'
                        : '필터',
                  ),
                ),
                if (hasActiveAdvancedFilters) ...[
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedColors.clear();
                        selectedSeasons.clear();
                        wearFilter = '전체';
                      });
                    },
                    child: const Text('전체 초기화'),
                  ),
                ],
              ],
            ),
          ),
          if (hasActiveAdvancedFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ...selectedColors.map((c) => Chip(label: Text(c), visualDensity: VisualDensity.compact)),
                    ...selectedSeasons.map((s) => Chip(label: Text(s), visualDensity: VisualDensity.compact)),
                    if (wearFilter != '전체') Chip(label: Text(wearFilter), visualDensity: VisualDensity.compact),
                  ],
                ),
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
            child: filteredClothes.isEmpty
                ? const EmptyStateView(
                    icon: Icons.search_off,
                    title: '조건에 맞는 아이템이 없습니다.',
                    subtitle: '필터를 초기화하거나 검색어를 변경해보세요.',
                  )
                : GridView.builder(
                    key: const PageStorageKey<String>('home-clothes-grid'),
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
                                    AppNetworkImage(
                                      imageUrl: item['image_url']?.toString(),
                                      fit: BoxFit.cover,
                                      fallbackIcon: Icons.checkroom,
                                    ),
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: SizedBox(
                                        width: 44,
                                        height: 44,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            customBorder: const CircleBorder(),
                                            onTap: itemId == null ? null : () => _toggleBookmark(itemId),
                                            child: Center(
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
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
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
          BottomNavigationBarItem(icon: Icon(Icons.dynamic_feed), label: '비체코'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: '보관함'),
        ],
        onTap: (index) async {
          setState(() => _selectedIndex = index);
          if (index == 0) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DailyLookCalendarPage(),
              ),
            );
          } else if (index == 1) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DailyLookFeedPage(),
              ),
            );
          } else if (index == 2) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SavedOutfitsPage(),
              ),
            );
          }
          if (!mounted) return;
          setState(() => _selectedIndex = 0);
        },
      ),
    );
  }
}