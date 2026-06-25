import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_service.dart';
import '../services/supabase_service.dart';
import '../widgets/color_selector.dart';

class AddClothesPage extends StatefulWidget {
  const AddClothesPage({super.key});

  @override
  State<AddClothesPage> createState() => _AddClothesPageState();
}

class _AddClothesPageState extends State<AddClothesPage> {
  File? selectedImage;
  String selectedCategory = '상의';
  String selectedColor = '블랙';
  String selectedBrand = '기타';
  List<String> selectedSeasons = [];
  DateTime? purchaseDate;
  final priceController = TextEditingController();
  final commentController = TextEditingController();
  bool enableAIAnalysis = true;
  final brandController = TextEditingController();

  @override
  void initState() {
    super.initState();
    brandController.text = selectedBrand;
  }

  @override
  void dispose() {
    brandController.dispose();
    priceController.dispose();
    commentController.dispose();
    super.dispose();
  }

  Future<void> pickPurchaseDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: purchaseDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );

    if (picked != null) {
      setState(() => purchaseDate = picked);
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        selectedImage = File(file.path);
      });
      await analyzeImage();
    }
  }

  Future<void> analyzeImage() async {
    if (selectedImage == null) return;
    try {
      debugPrint('[AI] analyzeImage started (enabled: $enableAIAnalysis)');
      final result = await GeminiService.analyzeClothesImage(
        selectedImage!,
        enableAnalysis: enableAIAnalysis,
      );
      if (result == null) {
        debugPrint('[AI] No analysis result (disabled or API key missing/failure).');
        return;
      }

      debugPrint('[AI] Raw result: $result');
      setState(() {
        selectedCategory = result['category'] ?? '상의';
        selectedBrand = result['brand'] ?? '기타';
        brandController.text = selectedBrand;
        selectedColor = normalizeColorLabel(result['color']?.toString());
        selectedSeasons = List<String>.from(result['seasons'] ?? []);
      });
      debugPrint(
        '[AI] Applied -> category: $selectedCategory, brand: $selectedBrand, color: $selectedColor, seasons: $selectedSeasons',
      );
    } catch (e) {
      debugPrint('[AI] analyzeImage error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI 분석 실패')),
        );
      }
    }
  }

  Future<void> saveClothes() async {
    try {
      await SupabaseService.saveClothes(
        category: selectedCategory,
        brand: selectedBrand,
        color: selectedColor,
        seasons: selectedSeasons,
        purchaseDate: purchaseDate,
        purchasePrice: int.tryParse(priceController.text.trim()),
        comment: commentController.text,
        imageFile: selectedImage,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('[AI] saveClothes error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('옷 등록')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: ListTile(
                  title: const Text('AI 자동 분석'),
                  trailing: Switch(
                    value: enableAIAnalysis,
                    onChanged: (value) => setState(() => enableAIAnalysis = value),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: pickImage, child: const Text('사진 선택')),
              const SizedBox(height: 20),
              if (selectedImage != null) Image.file(selectedImage!, height: 200),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: const [
                  DropdownMenuItem(value: '상의', child: Text('상의')),
                  DropdownMenuItem(value: '하의', child: Text('하의')),
                  DropdownMenuItem(value: '아우터', child: Text('아우터')),
                  DropdownMenuItem(value: '신발', child: Text('신발')),
                  DropdownMenuItem(value: '모자', child: Text('모자')),
                ],
                onChanged: (value) => setState(() => selectedCategory = value!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: brandController,
                onChanged: (value) => selectedBrand = value,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('구입 시기 (선택)'),
                subtitle: Text(
                  purchaseDate == null
                      ? '미입력'
                      : '${purchaseDate!.year}-${purchaseDate!.month.toString().padLeft(2, '0')}-${purchaseDate!.day.toString().padLeft(2, '0')}',
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    if (purchaseDate != null)
                      IconButton(
                        onPressed: () => setState(() => purchaseDate = null),
                        icon: const Icon(Icons.clear),
                      ),
                    IconButton(
                      onPressed: pickPurchaseDate,
                      icon: const Icon(Icons.calendar_today),
                    ),
                  ],
                ),
              ),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '구입 가격 (선택)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: commentController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: '메모 (선택)'),
              ),
              const SizedBox(height: 20),
              ColorSelector(
                selectedColor: selectedColor,
                onColorSelected: (color) => setState(() => selectedColor = color),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                children: ['봄', '여름', '가을', '겨울']
                    .map((season) => FilterChip(
                          label: Text(season),
                          selected: selectedSeasons.contains(season),
                          onSelected: (selected) => setState(() {
                            if (selected) selectedSeasons.add(season);
                            else selectedSeasons.remove(season);
                          }),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: saveClothes, child: const Text('저장')),
            ],
          ),
        ),
      ),
    );
  }
}