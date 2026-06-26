import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/daily_look_service.dart';
import '../services/supabase_service.dart';
import 'clothes_detail_page.dart';
import 'daily_look_editor_page.dart';
import 'user_closet_page.dart';

class DailyLookDetailPage extends StatefulWidget {
  final Map<String, dynamic> look;

  const DailyLookDetailPage({
    super.key,
    required this.look,
  });

  @override
  State<DailyLookDetailPage> createState() => _DailyLookDetailPageState();
}

class _DailyLookDetailPageState extends State<DailyLookDetailPage> {
  late Map<String, dynamic> look;
  final Map<int, Map<String, dynamic>> linkedItems = {};

  int likes = 0;
  int dislikes = 0;
  String? myReaction;

  bool loading = true;

  final List<Map<String, String>> itemConfig = const [
    {'label': '상의', 'key': 'top_item_id'},
    {'label': '하의', 'key': 'bottom_item_id'},
    {'label': '신발', 'key': 'shoes_item_id'},
    {'label': '모자', 'key': 'hat_item_id'},
    {'label': '가방', 'key': 'bag_item_id'},
    {'label': '액세서리', 'key': 'accessory_item_id'},
  ];

  @override
  void initState() {
    super.initState();
    look = Map<String, dynamic>.from(widget.look);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => loading = true);
    await Future.wait([
      _loadReactionSummary(),
      _loadLinkedItems(),
    ]);
    if (mounted) setState(() => loading = false);
  }

  Future<void> _loadReactionSummary() async {
    final id = look['id'];
    if (id is! num) return;
    final summary = await DailyLookService.getReactionSummary(id.toInt());
    if (!mounted) return;
    setState(() {
      likes = summary['likes'] ?? 0;
      dislikes = summary['dislikes'] ?? 0;
      myReaction = summary['myReaction']?.toString();
    });
  }

  Future<void> _loadLinkedItems() async {
    final ids = <int>[];
    for (final cfg in itemConfig) {
      final raw = look[cfg['key']];
      if (raw is num) ids.add(raw.toInt());
      if (raw is String) {
        final parsed = int.tryParse(raw);
        if (parsed != null) ids.add(parsed);
      }
    }

    final rows = await SupabaseService.fetchClothesByIds(ids);
    linkedItems.clear();
    for (final row in rows) {
      final rawId = row['id'];
      final id = rawId is num ? rawId.toInt() : int.tryParse(rawId.toString());
      if (id != null) linkedItems[id] = Map<String, dynamic>.from(row);
    }
    if (mounted) setState(() {});
  }

  bool get isOwnLook {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    return userId != null && userId == look['user_id'];
  }

  Future<void> _toggleReaction(String type) async {
    final id = look['id'];
    if (id is! num) return;
    try {
      await DailyLookService.setReaction(id.toInt(), type);
      await _loadReactionSummary();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('반응 저장 실패: $e')),
      );
    }
  }

  Future<void> _editLook() async {
    final rawDate = look['wear_date']?.toString();
    final parsedDate = DateTime.tryParse(rawDate ?? '') ?? DateTime.now();

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DailyLookEditorPage(
          selectedDate: parsedDate,
          existingLook: look,
        ),
      ),
    );

    if (changed != true) return;
    final id = look['id'];
    if (id is! num) return;

    look = await DailyLookService.fetchLookById(id.toInt());
    await _loadAll();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수정되었습니다.')),
      );
    }
  }

  Widget _buildLinkedItemCard(String label, Map<String, dynamic>? item) {
    return SizedBox(
      width: 160,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: item == null
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClothesDetailPage(
                        item: item,
                        isReadOnly: true,
                      ),
                    ),
                  );
                },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: item?['image_url'] != null
                    ? Image.network(item!['image_url'], fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.checkroom),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  item == null ? '선택된 아이템 없음' : (item['brand'] ?? 'No Brand').toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
                child: Text(
                  item == null ? '' : '${item['color'] ?? ''} · ${item['category'] ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hashtags = ((look['hashtags'] as List?) ?? [])
        .map((e) => e.toString())
        .join(' ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('데일리 코디'),
        actions: [
          if (isOwnLook)
            IconButton(
              onPressed: _editLook,
              icon: const Icon(Icons.edit),
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    onTap: () {
                      final userId = look['user_id']?.toString();
                      if (userId == null || userId.isEmpty) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserClosetPage(
                            userId: userId,
                            userName: (look['profile_username'] ?? '사용자').toString(),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      '@${(look['profile_username'] ?? '사용자').toString()} · 계정 보기',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (look['image_url'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        look['image_url'],
                        height: 280,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    (look['content'] ?? '').toString(),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hashtags,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _toggleReaction('like'),
                          icon: Icon(
                            myReaction == 'like' ? Icons.thumb_up : Icons.thumb_up_outlined,
                          ),
                          label: Text('좋아요 $likes'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _toggleReaction('dislike'),
                          icon: Icon(
                            myReaction == 'dislike'
                                ? Icons.thumb_down
                                : Icons.thumb_down_outlined,
                          ),
                          label: Text('싫어요 $dislikes'),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text(
                    '연결된 착용 아이템',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 250,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: itemConfig.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final cfg = itemConfig[index];
                        final raw = look[cfg['key']];
                        final itemId = raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '');
                        final item = itemId == null ? null : linkedItems[itemId];
                        return _buildLinkedItemCard(cfg['label']!, item);
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
