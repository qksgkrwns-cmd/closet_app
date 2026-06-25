import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../widgets/clothes_list_item.dart';
import 'add_clothes_page.dart';
import 'profile_setup_page.dart';
import 'similar_users_page.dart';

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

  Future<void> loadClothes() async {
    final data = await SupabaseService.fetchClothes(
      category: selectedFilter,
    );
    setState(() {
      clothes = data;
    });
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

  @override
  Widget build(BuildContext context) {
    final filteredClothes = getFilteredClothes();
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 옷장'),
        actions: [
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
            child: ListView.builder(
              itemCount: filteredClothes.length,
              itemBuilder: (context, index) {
                final item = filteredClothes[index];
                return ClothesListItem(
                  item: item,
                  onDelete: () async {
                    await SupabaseService.deleteClothes(item);
                    loadClothes();
                  },
                  onUpdate: () {
                    loadClothes();
                  },
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SimilarUsersPage(),
              ),
            );
          }
        },
      ),
    );
  }
}