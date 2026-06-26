import 'package:flutter/material.dart';

import '../services/daily_look_service.dart';
import 'daily_look_detail_page.dart';

class DailyLookFeedPage extends StatefulWidget {
  const DailyLookFeedPage({super.key});

  @override
  State<DailyLookFeedPage> createState() => _DailyLookFeedPageState();
}

class _DailyLookFeedPageState extends State<DailyLookFeedPage> {
  late Future<List<dynamic>> feedFuture;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  void _loadFeed() {
    setState(() {
      feedFuture = DailyLookService.fetchPublicFeed();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('피드')),
      body: FutureBuilder<List<dynamic>>(
        future: feedFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final feed = snapshot.data ?? [];
          if (feed.isEmpty) {
            return const Center(child: Text('표시할 공개 피드가 없습니다.'));
          }

          return RefreshIndicator(
            onRefresh: () async => _loadFeed(),
            child: ListView.builder(
              itemCount: feed.length,
              itemBuilder: (context, index) {
                final look = Map<String, dynamic>.from(feed[index]);
                final lookIdRaw = look['id'];
                final lookId = lookIdRaw is num ? lookIdRaw.toInt() : int.tryParse(lookIdRaw.toString());
                if (lookId == null) return const SizedBox.shrink();

                final content = (look['content'] ?? '').toString();
                final username = (look['profile_username'] ?? '사용자').toString();
                final hashtags = _hashtags(look['hashtags']);
                final dateText = _formatDate(look['wear_date'] ?? look['created_at']);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  clipBehavior: Clip.antiAlias,
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
                        ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade300,
                            child: const Icon(Icons.person, color: Colors.black54),
                          ),
                          title: Text('@$username', style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(dateText),
                        ),
                        if (look['image_url'] != null)
                          Image.network(
                            look['image_url'],
                            height: 240,
                            fit: BoxFit.cover,
                          ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(content, maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 6),
                              if (hashtags.isNotEmpty)
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: hashtags
                                      .map((tag) => Chip(
                                            label: Text(tag),
                                            visualDensity: VisualDensity.compact,
                                          ))
                                      .toList(),
                                ),
                              const SizedBox(height: 8),
                              FutureBuilder<Map<String, dynamic>>(
                                future: _loadSocial(lookId),
                                builder: (context, socialSnap) {
                                  final likes = socialSnap.data?['likes'] ?? 0;
                                  final dislikes = socialSnap.data?['dislikes'] ?? 0;
                                  final myReaction = socialSnap.data?['myReaction']?.toString();
                                  final bookmarked = socialSnap.data?['bookmarked'] == true;

                                  return Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: () async {
                                          await DailyLookService.setReaction(lookId, 'like');
                                          if (!mounted) return;
                                          setState(() {});
                                        },
                                        icon: Icon(
                                          myReaction == 'like'
                                              ? Icons.thumb_up
                                              : Icons.thumb_up_outlined,
                                        ),
                                        label: Text('$likes'),
                                      ),
                                      TextButton.icon(
                                        onPressed: () async {
                                          await DailyLookService.setReaction(lookId, 'dislike');
                                          if (!mounted) return;
                                          setState(() {});
                                        },
                                        icon: Icon(
                                          myReaction == 'dislike'
                                              ? Icons.thumb_down
                                              : Icons.thumb_down_outlined,
                                        ),
                                        label: Text('$dislikes'),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        onPressed: () async {
                                          await DailyLookService.toggleBookmark(lookId);
                                          if (!mounted) return;
                                          setState(() {});
                                        },
                                        icon: Icon(
                                          bookmarked ? Icons.bookmark : Icons.bookmark_border,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
