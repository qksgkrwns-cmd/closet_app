import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'clothes_detail_page.dart';

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
  String selectedFilter = '전체';
  String searchKeyword = '';
  List<dynamic> clothes = [];

  @override
  void initState() {
    super.initState();
    loadClothes();
  }

  Future<void> loadClothes() async {
    final data = await SupabaseService.fetchClothes(
      userId: widget.userId,
      category: selectedFilter,
    );
    if (!mounted) return;
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

  String _formatCreatedAt(dynamic raw) {
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    if (parsed == null) return '';
    return '${parsed.year}.${parsed.month}.${parsed.day}';
  }

  @override
  Widget build(BuildContext context) {
    final filteredClothes = getFilteredClothes();

    return Scaffold(
      appBar: AppBar(title: Text('${widget.userName}의 옷장')),
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
          if (clothes.isEmpty)
            const Expanded(
              child: Center(child: Text('옷이 없습니다.')),
            )
          else
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
    );
  }
}