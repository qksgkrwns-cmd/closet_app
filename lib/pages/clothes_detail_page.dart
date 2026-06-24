import 'package:flutter/material.dart';
import '../pages/clothes_detail_page.dart';

class ClothesDetailPage extends StatelessWidget {
  final Map item;

  const ClothesDetailPage({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('옷 정보')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item['image_url'],
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
                      Text('색상 : ${item['color']}'),
                      const SizedBox(height: 8),
                      Text('계절 : ${(item['seasons'] ?? []).join(", ")}'),
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