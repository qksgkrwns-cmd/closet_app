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
  static const Map<String, List<String>> categoryHierarchy = {
    '상의': ['상의', '반팔티', '긴팔티', '셔츠', '후드', '니트'],
    '하의': ['하의', '청바지', '면바지', '트레이닝', '치마'],
    '아우터': ['아우터', '자켓', '코트', '점퍼'],
    '신발': ['신발', '스니커즈', '로퍼', '구두'],
    '모자': ['모자', '야구모', '비니'],
    '잡동사니': ['잡동사니', '가방', '시계', '목도리', '장갑'],
  };

  File? selectedImage;
  String selectedCategory = '상의';
  String selectedSubcategory = '상의';
  String selectedColor = '블랙';
  String selectedBrand = '기타';
  List<String> selectedSeasons = [];
  DateTime? purchaseDate;
  final priceController = TextEditingController();
  final sizeController = TextEditingController();
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
    sizeController.dispose();
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
      final analyzedCategory = result['category'] ?? '상의';
      setState(() {
        selectedCategory = analyzedCategory;
        selectedSubcategory = analyzedCategory;
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
      // 대분류와 소분류를 합쳐서 저장 (예: "상의/반팔티")
      final categoryToSave = selectedSubcategory == selectedCategory
          ? selectedCategory
          : '$selectedCategory/$selectedSubcategory';
      await SupabaseService.saveClothes(
        category: categoryToSave,
        brand: selectedBrand,
        color: selectedColor,
        seasons: selectedSeasons,
        size: sizeController.text,
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
                decoration: const InputDecoration(labelText: '카테고리 (대분류)'),
                value: selectedCategory,
                items: categoryHierarchy.keys
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedCategory = value;
                      selectedSubcategory = categoryHierarchy[value]![0];
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: '카테고리 (세부)'),
                value: selectedSubcategory,
                items: (categoryHierarchy[selectedCategory] ?? [])
                    .map((sub) => DropdownMenuItem(value: sub, child: Text(sub)))
                    .toList(),
                onChanged: (value) => setState(() => selectedSubcategory = value!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: brandController,
                decoration: const InputDecoration(labelText: '브랜드'),
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
                controller: sizeController,
                decoration: const InputDecoration(labelText: '사이즈 (선택, 예: M / 270)'),
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