import 'package:flutter/material.dart';

class ClothesListItem extends StatelessWidget {
  final Map item;
  final VoidCallback onDelete;
  final VoidCallback onUpdate;

  const ClothesListItem({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onUpdate,
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
    return Card(
      child: ListTile(
        onLongPress: () => _showDeleteDialog(context),
        leading: item['image_url'] != null
            ? SizedBox(
                width: 60,
                height: 60,
                child: Image.network(item['image_url'], fit: BoxFit.cover),
              )
            : const Icon(Icons.checkroom),
        title: Text(item['category'] ?? ''),
        subtitle: Text('${item['brand'] ?? "기타"} · ${item['color']}'),
      ),
    );
  }
}