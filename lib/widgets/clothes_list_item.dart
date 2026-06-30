import 'package:flutter/material.dart';
import 'color_selector.dart';

class ClothesListItem extends StatelessWidget {
  final Map item;
  final VoidCallback onDelete;
  final VoidCallback onUpdate;
  final VoidCallback onTap;

  const ClothesListItem({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onUpdate,
    required this.onTap,
  });

  void _showDeleteDialog(BuildContext context) async {
    final result = await showDialog<bool>(
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
    if (result == true) onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final wearCount = (item['wear_count'] is num)
        ? (item['wear_count'] as num).toInt()
        : int.tryParse(item['wear_count']?.toString() ?? '0') ?? 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        onLongPress: () => _showDeleteDialog(context),
        leading: item['image_url'] != null
            ? Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(item['image_url'], fit: BoxFit.cover),
              )
            : Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: const Icon(Icons.checkroom),
              ),
        title: Text(
          item['category'] ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${item['brand'] ?? "기타"} · ${normalizeColorLabel(item['color']?.toString())} · 착용 ${wearCount}회',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}