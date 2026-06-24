import 'package:flutter/material.dart';
import '../models/outfit.dart';

class OutfitCard extends StatelessWidget {
  final Outfit outfit;

  const OutfitCard({
    super.key,
    required this.outfit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: outfit.imageUrl != null
                ? Image.network(outfit.imageUrl!, fit: BoxFit.cover)
                : Container(color: Colors.grey[300], child: const Icon(Icons.image)),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(outfit.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.favorite, size: 14, color: Colors.red),
                    const SizedBox(width: 4),
                    Text('${outfit.likesCount}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}