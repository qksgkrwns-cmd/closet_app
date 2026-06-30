import 'package:flutter/material.dart';

import '../services/daily_look_service.dart';
import '../services/supabase_service.dart';
import '../widgets/app_network_image.dart';
import '../widgets/empty_state_view.dart';
import 'clothes_detail_page.dart';
import 'daily_look_detail_page.dart';
import 'user_closet_page.dart';

class DailyLookFeedPage extends StatefulWidget {
  const DailyLookFeedPage({super.key});

  @override
  State<DailyLookFeedPage> createState() => _DailyLookFeedPageState();
}

class _DailyLookFeedPageState extends State<DailyLookFeedPage> {
  late Future<List<dynamic>> feedFuture;
  final Map<String, int> _pageByUser = {};

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  void _loadFeed() {
    setState(() {
      feedFuture = DailyLookService.fetchPublicFeed(sortBy: 'latest');
    });
  }

  Future<Map<String, dynamic>> _loadSocial(int lookId) async {
    final summary = await DailyLookService.getReactionSummary(lookId);
    final bookmarked = await DailyLookService.isBookmarked(lookId);
    return {
      ...summary,
      'bookmarked': bookmarked,
    };
  }

  String _formatDate(dynamic raw) {
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    if (parsed == null) return '';
    return '${parsed.year}.${parsed.month}.${parsed.day}';
  }

  List<String> _hashtags(dynamic raw) {
    final list = (raw as List?) ?? const [];
    return list.map((e) => e.toString()).where((e) => e.isNotEmpty).take(3).toList();
  }

  List<Map<String, String>> _itemConfig() => const [
        {'label': '상의', 'key': 'top_item_id'},
        {'label': '하의', 'key': 'bottom_item_id'},
      {'label': '아우터', 'key': 'outer_item_id'},
        {'label': '신발', 'key': 'shoes_item_id'},
        {'label': '모자', 'key': 'hat_item_id'},
        {'label': '가방', 'key': 'bag_item_id'},
        {'label': '잡동사니', 'key': 'accessory_item_id'},
      ];

  List<int> _linkedItemIds(Map<String, dynamic> look) {
    final ids = <int>[];
    for (final cfg in _itemConfig()) {
      final raw = look[cfg['key']];
      if (raw is num) {
        ids.add(raw.toInt());
      } else if (raw != null) {
        final parsed = int.tryParse(raw.toString());
        if (parsed != null) ids.add(parsed);
      }
    }
    return ids;
  }

  Widget _buildLinkedItemsStrip(Map<String, dynamic> look) {
    final ids = _linkedItemIds(look);
    if (ids.isEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<dynamic>>(
      future: SupabaseService.fetchClothesByIds(ids),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 112,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final rows = snapshot.data ?? [];
        if (rows.isEmpty) return const SizedBox.shrink();

        final byId = <int, Map<String, dynamic>>{};
        for (final row in rows) {
          final item = Map<String, dynamic>.from(row);
          final rawId = item['id'];
          final itemId = rawId is num ? rawId.toInt() : int.tryParse(rawId?.toString() ?? '');
          if (itemId != null) byId[itemId] = item;
        }

        final orderedItems = ids.map((id) => byId[id]).whereType<Map<String, dynamic>>().toList();
        if (orderedItems.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            physics: const BouncingScrollPhysics(),
            itemCount: orderedItems.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = orderedItems[index];
              return InkWell(
                onTap: () {
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
                child: SizedBox(
                  width: 82,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: AppNetworkImage(
                          imageUrl: item['image_url']?.toString(),
                          fit: BoxFit.cover,
                          fallbackIcon: Icons.checkroom,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (item['category'] ?? '').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSocialBar(int lookId) {
    return Container(
      color: Colors.grey.shade900,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _loadSocial(lookId),
        builder: (context, socialSnap) {
          final likes = socialSnap.data?['likes'] ?? 0;
          final bookmarked = socialSnap.data?['bookmarked'] == true;
          final bookmarkCount = socialSnap.data?['bookmarkCount'] ?? 0;
          final myReaction = socialSnap.data?['myReaction']?.toString();

          return Row(
            children: [
              Expanded(
                child: Text(
                  //'좋아요 $likes · 북마크 $bookmarkCount · 합계 $totalEngagement',
                  '좋아요 $likes · 북마크 $bookmarkCount',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: () async {
                  await DailyLookService.setReaction(lookId, 'like');
                  if (!mounted) return;
                  setState(() {});
                },
                icon: Icon(
                  myReaction == 'like' ? Icons.thumb_up : Icons.thumb_up_outlined,
                  size: 18,
                ),
                constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                onPressed: () async {
                  await DailyLookService.setReaction(lookId, 'dislike');
                  if (!mounted) return;
                  setState(() {});
                },
                icon: Icon(
                  myReaction == 'dislike' ? Icons.thumb_down : Icons.thumb_down_outlined,
                  size: 18,
                ),
                constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                onPressed: () async {
                  await DailyLookService.toggleBookmark(lookId);
                  if (!mounted) return;
                  setState(() {});
                },
                icon: Icon(
                  bookmarked ? Icons.bookmark : Icons.bookmark_border,
                  size: 18,
                ),
                constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                padding: EdgeInsets.zero,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPostPage(Map<String, dynamic> look) {
    final lookIdRaw = look['id'];
    final lookId = lookIdRaw is num ? lookIdRaw.toInt() : int.tryParse(lookIdRaw.toString());
    if (lookId == null) return const SizedBox.shrink();

    final content = (look['content'] ?? '').toString();
    final hashtags = _hashtags(look['hashtags']);
    final dateText = _formatDate(look['wear_date'] ?? look['created_at']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DailyLookDetailPage(look: look),
                  ),
                );
                _loadFeed();
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Text(
                      dateText,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ),
                  if (look['image_url'] != null)
                    Container(
                      height: 220,
                      color: Colors.black.withValues(alpha: 0.08),
                      child: AppNetworkImage(
                        imageUrl: look['image_url']?.toString(),
                        fit: BoxFit.contain,
                        fallbackIcon: Icons.image_not_supported,
                      ),
                    ),
                  _buildLinkedItemsStrip(look),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(content, maxLines: 3, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        if (hashtags.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: hashtags
                                .map(
                                  (tag) => Chip(
                                    label: Text(tag),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildSocialBar(lookId),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('비슷한 체형 코디'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: feedFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final feed = (snapshot.data ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          if (feed.isEmpty) {
            return const EmptyStateView(
              icon: Icons.dynamic_feed,
              title: '표시할 공개 데일리룩이 없습니다.',
              subtitle: '프로필 성별/체형 정보를 확인하고 다시 시도해주세요.',
            );
          }

          final grouped = <String, List<Map<String, dynamic>>>{};
          for (final look in feed) {
            final userId = (look['user_id'] ?? '').toString();
            if (userId.isEmpty) continue;
            grouped.putIfAbsent(userId, () => []);
            grouped[userId]!.add(look);
          }
          for (final entry in grouped.entries) {
            entry.value.sort((a, b) {
              final aCreated = DateTime.tryParse((a['created_at'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bCreated = DateTime.tryParse((b['created_at'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bCreated.compareTo(aCreated);
            });
          }
          final entries = grouped.entries.toList()
            ..sort((a, b) {
              final aLatest = a.value.isEmpty
                  ? DateTime.fromMillisecondsSinceEpoch(0)
                  : DateTime.tryParse((a.value.first['created_at'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bLatest = b.value.isEmpty
                  ? DateTime.fromMillisecondsSinceEpoch(0)
                  : DateTime.tryParse((b.value.first['created_at'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bLatest.compareTo(aLatest);
            });

          return RefreshIndicator(
            onRefresh: () async => _loadFeed(),
            child: ListView.builder(
              key: const PageStorageKey<String>('daily-look-feed-list'),
              itemCount: entries.length,
              padding: const EdgeInsets.only(bottom: 96),
              itemBuilder: (context, index) {
                final userId = entries[index].key;
                final looks = entries[index].value;
                if (looks.isEmpty) return const SizedBox.shrink();

                final first = looks.first;
                final uploaderName =
                    (first['uploader_name'] ?? first['profile_username'] ?? '사용자').toString();
                final currentPage = _pageByUser[userId] ?? 0;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        dense: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserClosetPage(
                                userId: userId,
                                userName: uploaderName,
                              ),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade300,
                          child: const Icon(Icons.person, color: Colors.black54),
                        ),
                        title: Text(
                          uploaderName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text('게시물 ${currentPage + 1}/${looks.length} · 좌우로 넘겨보기'),
                      ),
                      SizedBox(
                        height: 410,
                        child: PageView.builder(
                          itemCount: looks.length,
                          onPageChanged: (page) {
                            setState(() {
                              _pageByUser[userId] = page;
                            });
                          },
                          itemBuilder: (context, pageIndex) {
                            return _buildPostPage(looks[pageIndex]);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
