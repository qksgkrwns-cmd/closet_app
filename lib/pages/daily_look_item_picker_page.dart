import 'package:flutter/material.dart';

import '../services/supabase_service.dart';

class DailyLookItemPickerPage extends StatefulWidget {
  final String categoryLabel;
  final String slotKey;
  final int? selectedItemId;

  const DailyLookItemPickerPage({
    super.key,
    required this.categoryLabel,
    required this.slotKey,
    this.selectedItemId,
  });

  @override
  State<DailyLookItemPickerPage> createState() => _DailyLookItemPickerPageState();
}

class _DailyLookItemPickerPageState extends State<DailyLookItemPickerPage> {
  final searchController = TextEditingController();
  List<dynamic> items = [];
  String searchKeyword = '';
  String selectedSeason = '전체';
  String selectedColor = '전체';
  String selectedSort = '등록일순';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final data = await SupabaseService.fetchClothes();
    final mapped = data.map((e) => Map<String, dynamic>.from(e)).toList();
    final filteredBySlot = mapped.where(_matchesSlot).toList();
    if (!mounted) return;
    setState(() {
      items = filteredBySlot;
      isLoading = false;
    });
  }

  bool _matchesSlot(Map<String, dynamic> item) {
    final fullCategory = (item['category'] ?? '').toString();
    final split = fullCategory.split('/');
    final parent = split.isNotEmpty ? split.first : fullCategory;
    final sub = split.length > 1 ? split[1] : '';

    switch (widget.slotKey) {
      case 'top_item_id':
        return parent == '상의';
      case 'bottom_item_id':
        return parent == '하의';
      case 'outer_item_id':
        return parent == '아우터';
      case 'shoes_item_id':
        return parent == '신발';
      case 'hat_item_id':
        return parent == '모자';
      case 'bag_item_id':
        return (parent == '잡동사니' && sub == '가방') || fullCategory == '가방';
      case 'accessory_item_id':
        if (parent != '잡동사니') return false;
        return sub != '가방';
      default:
        return true;
    }
  }

  List<dynamic> get filteredItems {
    final keyword = searchKeyword.toLowerCase();
    final filtered = items.where((item) {
      final brand = (item['brand'] ?? '').toString().toLowerCase();
      final color = (item['color'] ?? '').toString().toLowerCase();
      final comment = (item['comment'] ?? '').toString().toLowerCase();
      final seasons = ((item['seasons'] as List?) ?? []).map((e) => e.toString()).toList();

      final matchesKeyword = searchKeyword.isEmpty ||
          brand.contains(keyword) ||
          color.contains(keyword) ||
          comment.contains(keyword);
      final matchesSeason = selectedSeason == '전체' || seasons.contains(selectedSeason);
      final matchesColor = selectedColor == '전체' || (item['color'] ?? '').toString() == selectedColor;

      return matchesKeyword && matchesSeason && matchesColor;
    }).toList();

    filtered.sort((a, b) {
      switch (selectedSort) {
        case '브랜드순':
          return (a['brand'] ?? '').toString().compareTo((b['brand'] ?? '').toString());
        case '구입일순':
          final aDate = DateTime.tryParse((a['purchase_date'] ?? '').toString());
          final bDate = DateTime.tryParse((b['purchase_date'] ?? '').toString());
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        case '구매가격순':
          final aPrice = a['purchase_price'] is num
              ? (a['purchase_price'] as num).toInt()
              : int.tryParse((a['purchase_price'] ?? '').toString()) ?? -1;
          final bPrice = b['purchase_price'] is num
              ? (b['purchase_price'] as num).toInt()
              : int.tryParse((b['purchase_price'] ?? '').toString()) ?? -1;
          return bPrice.compareTo(aPrice);
        case '등록일순':
        default:
          final aDate = DateTime.tryParse((a['created_at'] ?? '').toString());
          final bDate = DateTime.tryParse((b['created_at'] ?? '').toString());
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
      }
    });

    return filtered;
  }

  List<String> get seasonOptions {
    final seasons = <String>{'전체'};
    for (final item in items) {
      for (final season in ((item['seasons'] as List?) ?? [])) {
        seasons.add(season.toString());
      }
    }
    return seasons.toList();
  }

  List<String> get colorOptions {
    final colors = <String>{'전체'};
    for (final item in items) {
      final color = (item['color'] ?? '').toString();
      if (color.isNotEmpty) colors.add(color);
    }
    return colors.toList();
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = filteredItems;
    return Scaffold(
      appBar: AppBar(title: Text('${widget.categoryLabel} 선택')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: '브랜드, 색상, 메모 검색',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchKeyword = value.trim();
                });
              },
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                ChoiceChip(
                  label: Text(widget.categoryLabel),
                  selected: true,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedSort,
                    decoration: const InputDecoration(labelText: '정렬'),
                    items: const ['등록일순', '브랜드순', '구입일순', '구매가격순']
                        .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedSort = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: seasonOptions
                  .map(
                    (season) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(season),
                        selected: selectedSeason == season,
                        onSelected: (_) => setState(() => selectedSeason = season),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: colorOptions
                  .map(
                    (color) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(color),
                        selected: selectedColor == color,
                        onSelected: (_) => setState(() => selectedColor = color),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : visibleItems.isEmpty
                    ? const Center(child: Text('선택 가능한 옷이 없습니다.'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.6,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: visibleItems.length,
                        itemBuilder: (context, index) {
                          final item = visibleItems[index];
                          final rawId = item['id'];
                          final itemId = rawId is num ? rawId.toInt() : int.tryParse(rawId.toString());
                          final isSelected = itemId != null && itemId == widget.selectedItemId;
                          return InkWell(
                            onTap: () => Navigator.pop(context, Map<String, dynamic>.from(item)),
                            child: Card(
                              color: isSelected ? Colors.black.withValues(alpha: 0.05) : null,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: isSelected ? Colors.black87 : Colors.grey.shade300,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: item['image_url'] != null
                                        ? Image.network(item['image_url'], fit: BoxFit.cover)
                                        : Container(
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.checkroom),
                                          ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                                    child: Text(
                                      (item['brand'] ?? 'No Brand').toString(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                    child: Text(
                                      (item['color'] ?? '').toString(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
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
