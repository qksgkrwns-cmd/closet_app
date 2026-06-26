import 'package:flutter/material.dart';
import 'edit_clothes_page.dart';
import '../services/supabase_service.dart';
import '../widgets/color_selector.dart';

class ClothesDetailPage extends StatefulWidget {
  final Map item;
  final bool isReadOnly;

  const ClothesDetailPage({
    super.key,
    required this.item,
    this.isReadOnly = false,
  });

  @override
  State<ClothesDetailPage> createState() => _ClothesDetailPageState();
}

class _ClothesDetailPageState extends State<ClothesDetailPage> {
  late Map<String, dynamic> item;
  bool isUpdatingWearCount = false;
  bool isLiked = false;
  bool isBookmarked = false;
  int likesCount = 0;
  bool isLoadingSocial = false;

  @override
  void initState() {
    super.initState();
    item = Map<String, dynamic>.from(widget.item);
    if (widget.isReadOnly) {
      _loadSocialState();
    } else {
      _loadBookmarkStateForOwnerView();
    }
  }

  Future<void> _loadBookmarkStateForOwnerView() async {
    final id = item['id'];
    final parsedId = id is int ? id : int.tryParse(id?.toString() ?? '');
    if (parsedId == null) return;
    try {
      final bookmarked = await SupabaseService.isClothesBookmarked(parsedId);
      if (!mounted) return;
      setState(() => isBookmarked = bookmarked);
    } catch (_) {}
  }

  Future<void> _loadSocialState() async {
    final id = item['id'];
    if (id is! int) return;

    setState(() => isLoadingSocial = true);
    try {
      final count = await SupabaseService.getClothesLikesCount(id);
      final liked = await SupabaseService.isClothesLiked(id);
      final bookmarked = await SupabaseService.isClothesBookmarked(id);
      if (!mounted) return;
      setState(() {
        likesCount = count;
        isLiked = liked;
        isBookmarked = bookmarked;
      });
    } finally {
      if (mounted) setState(() => isLoadingSocial = false);
    }
  }

  Future<void> toggleLike() async {
    final id = item['id'];
    final parsedId = id is int ? id : int.tryParse(id?.toString() ?? '');
    if (parsedId == null) return;
    try {
      if (isLiked) {
        await SupabaseService.unlikeClothes(parsedId);
        setState(() {
          isLiked = false;
          likesCount = likesCount > 0 ? likesCount - 1 : 0;
        });
      } else {
        await SupabaseService.likeClothes(parsedId);
        setState(() {
          isLiked = true;
          likesCount += 1;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('좋아요 처리 실패: $e')),
      );
    }
  }

  Future<void> toggleBookmark() async {
    final id = item['id'];
    final parsedId = id is int ? id : int.tryParse(id?.toString() ?? '');
    if (parsedId == null) return;
    try {
      if (isBookmarked) {
        await SupabaseService.unbookmarkClothes(parsedId);
        setState(() => isBookmarked = false);
      } else {
        await SupabaseService.bookmarkClothes(parsedId);
        setState(() => isBookmarked = true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('북마크 처리 실패: $e')),
      );
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '미입력';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }

  String _formatPrice(dynamic raw) {
    if (raw == null) return '미입력';
    final price = raw is num ? raw.toInt() : int.tryParse(raw.toString());
    if (price == null) return '미입력';
    return '${price.toString()}원';
  }

  Future<void> incrementWearCount() async {
    final id = item['id'];
    final parsedId = id is int ? id : int.tryParse(id?.toString() ?? '');
    if (parsedId == null) return;

    final current = (item['wear_count'] is num)
        ? (item['wear_count'] as num).toInt()
        : int.tryParse(item['wear_count']?.toString() ?? '0') ?? 0;

    setState(() => isUpdatingWearCount = true);
    try {
      final next = await SupabaseService.incrementWearCount(
        id: parsedId,
        currentWearCount: current,
      );

      if (!mounted) return;
      if (next != null) {
        setState(() => item['wear_count'] = next);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('착용횟수 업데이트 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => isUpdatingWearCount = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('옷 정보'),
        actions: widget.isReadOnly
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: '수정',
                  onPressed: () async {
                    final updated = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditClothesPage(item: item),
                      ),
                    );

                    if (context.mounted && updated == true) {
                      Navigator.pop(context, true);
                    }
                  },
                ),
              ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        item['image_url'],
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: toggleBookmark,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            isBookmarked ? Icons.favorite : Icons.favorite_border,
                            color: isBookmarked ? Colors.red : Colors.grey.shade600,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!widget.isReadOnly)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '누적 착용횟수 : ${((item['wear_count'] is num) ? (item['wear_count'] as num).toInt() : int.tryParse(item['wear_count']?.toString() ?? '0') ?? 0)}회',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: isUpdatingWearCount ? null : incrementWearCount,
                      icon: isUpdatingWearCount
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add),
                      label: const Text('착용 +1'),
                    ),
                  ],
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.favorite, color: Colors.red),
                            const SizedBox(width: 6),
                            Text('좋아요 $likesCount'),
                            if (isLoadingSocial) ...[
                              const SizedBox(width: 10),
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: toggleLike,
                                icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border),
                                label: Text(isLiked ? '좋아요 취소' : '좋아요'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: toggleBookmark,
                                icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                                label: Text(isBookmarked ? '북마크됨' : '북마크'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('카테고리 : ${item['category']}'),
                      const SizedBox(height: 8),
                      Text('브랜드 : ${item['brand'] ?? '기타'}'),
                      const SizedBox(height: 8),
                      Text('색상 : ${normalizeColorLabel(item['color']?.toString())}'),
                      const SizedBox(height: 8),
                      Text('계절 : ${(item['seasons'] ?? []).join(", ")}'),
                      const SizedBox(height: 8),
                      Text('구입 시기 : ${_formatDate(item['purchase_date']?.toString())}'),
                      const SizedBox(height: 8),
                      Text('구입 가격 : ${_formatPrice(item['purchase_price'])}'),
                      const SizedBox(height: 8),
                      Text('사이즈 : ${(item['size']?.toString().trim().isEmpty ?? true) ? '미입력' : item['size']}'),
                      const SizedBox(height: 8),
                      Text('메모 : ${(item['comment']?.toString().trim().isEmpty ?? true) ? '미입력' : item['comment']}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}