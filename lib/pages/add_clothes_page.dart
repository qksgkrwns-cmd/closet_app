import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    '상의': ['반팔티', '긴팔티', '셔츠', '맨투맨', '후드', '니트', '블라우스'],
    '하의': ['청바지', '슬랙스', '면바지', '반바지', '치마', '트레이닝', '레깅스'],
    '아우터': ['자켓', '코트', '패딩', '가디건', '점퍼', '바람막이', '베스트'],
    '신발': ['스니커즈', '로퍼', '구두', '샌들', '부츠', '슬리퍼', '런닝화'],
    '모자': ['볼캡', '버킷햇', '비니', '베레모', '페도라', '썬캡', '니트모자'],
    '잡동사니': ['가방', '시계', '목도리', '장갑', '벨트', '양말', '선글라스'],
  };

  File? selectedImage;
  String? selectedCategory;
  String? selectedSubcategory;
  String? selectedColor;
  String selectedBrand = '';
  List<String> selectedSeasons = [];
  DateTime? purchaseDate;
  final priceController = TextEditingController();
  final sizeController = TextEditingController();
  final commentController = TextEditingController();
  bool enableAIAnalysis = true;
  bool _submitted = false;
  bool _isSaving = false;
  final brandController = TextEditingController();
  List<String> _recentBrands = [];
  List<String> _recentSizes = [];

  List<String> _subcategoriesFor(String? category) {
    if (category == null) return const [];
    return categoryHierarchy[category] ?? const [];
  }

  String? _normalizeCategoryLabel(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    switch (value) {
      case 'top':
      case '상의':
        return '상의';
      case 'bottom':
      case '하의':
        return '하의';
      case 'outerwear':
      case 'outer':
      case '아우터':
        return '아우터';
      case 'shoes':
      case 'shoe':
      case '신발':
        return '신발';
      case 'hat':
      case '모자':
        return '모자';
      case 'bag':
      case 'accessory':
      case '잡동사니':
        return '잡동사니';
      default:
        return categoryHierarchy.keys.contains(raw) ? raw : null;
    }
  }

  String _purchaseDateText() {
    if (purchaseDate == null) return '미입력';
    return '${purchaseDate!.year}-${purchaseDate!.month.toString().padLeft(2, '0')}-${purchaseDate!.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _loadRecentInputs();
  }

  Future<void> _loadRecentInputs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _recentBrands = prefs.getStringList('recent_brands') ?? [];
      _recentSizes = prefs.getStringList('recent_sizes') ?? [];
    });
  }

  Future<void> _rememberRecentInputs() async {
    final prefs = await SharedPreferences.getInstance();

    final brand = selectedBrand.trim();
    if (brand.isNotEmpty) {
      final nextBrands = [brand, ..._recentBrands.where((e) => e != brand)].take(5).toList();
      await prefs.setStringList('recent_brands', nextBrands);
    }

    final size = sizeController.text.trim();
    if (size.isNotEmpty) {
      final nextSizes = [size, ..._recentSizes.where((e) => e != size)].take(5).toList();
      await prefs.setStringList('recent_sizes', nextSizes);
    }
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
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: CalendarDatePicker(
              initialDate: purchaseDate ?? now,
              firstDate: DateTime(2000),
              lastDate: now,
              onDateChanged: (date) => Navigator.pop(context, date),
            ),
          ),
        );
      },
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
      final analyzedCategory = _normalizeCategoryLabel(result['category']?.toString()) ?? '상의';
      setState(() {
        selectedCategory = analyzedCategory;
        final subs = _subcategoriesFor(analyzedCategory);
        selectedSubcategory = subs.isNotEmpty ? subs.first : null;
        selectedBrand = (result['brand'] ?? '').toString();
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
    setState(() => _submitted = true);
    try {
      if (selectedCategory == null || selectedSubcategory == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('카테고리를 선택해주세요.')),
          );
        }
        return;
      }
      if (selectedColor == null || selectedColor!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('색상을 선택해주세요.')),
          );
        }
        return;
      }

      setState(() => _isSaving = true);
      // 대분류와 소분류를 합쳐서 저장 (예: "상의/반팔티")
      final categoryToSave = selectedSubcategory == selectedCategory
          ? selectedCategory!
          : '$selectedCategory/$selectedSubcategory';
      await SupabaseService.saveClothes(
        category: categoryToSave,
        brand: selectedBrand.trim(),
        color: selectedColor!,
        seasons: selectedSeasons,
        size: sizeController.text,
        purchaseDate: purchaseDate,
        purchasePrice: int.tryParse(priceController.text.trim()),
        comment: commentController.text,
        imageFile: selectedImage,
      );
      await _rememberRecentInputs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장되었습니다.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('[AI] saveClothes error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('옷 등록')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
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
                hint: const Text('선택하세요'),
                items: categoryHierarchy.keys
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    final subs = _subcategoriesFor(value);
                    setState(() {
                      selectedCategory = value;
                      selectedSubcategory = subs.isNotEmpty ? subs.first : null;
                    });
                  }
                },
              ),
              if (_submitted && selectedCategory == null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '카테고리를 선택해주세요.',
                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: '카테고리 (세부)'),
                value: _subcategoriesFor(selectedCategory).contains(selectedSubcategory)
                  ? selectedSubcategory
                  : (_subcategoriesFor(selectedCategory).isNotEmpty
                    ? _subcategoriesFor(selectedCategory).first
                    : null),
                hint: const Text('선택하세요'),
                items: _subcategoriesFor(selectedCategory)
                    .map((sub) => DropdownMenuItem(value: sub, child: Text(sub)))
                    .toList(),
                onChanged: selectedCategory == null
                    ? null
                    : (value) => setState(() => selectedSubcategory = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: brandController,
                decoration: const InputDecoration(labelText: '브랜드'),
                onChanged: (value) => selectedBrand = value,
              ),
              if (_recentBrands.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _recentBrands
                        .map(
                          (brand) => ActionChip(
                            label: Text(brand),
                            onPressed: () {
                              setState(() {
                                selectedBrand = brand;
                                brandController.text = brand;
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: pickPurchaseDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: '구입 시기',
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (purchaseDate != null)
                          IconButton(
                            tooltip: '구입 시기 초기화',
                            onPressed: () => setState(() => purchaseDate = null),
                            icon: const Icon(Icons.clear),
                          ),
                        IconButton(
                          tooltip: '날짜 선택',
                          onPressed: pickPurchaseDate,
                          icon: const Icon(Icons.calendar_today),
                        ),
                      ],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _purchaseDateText(),
                      style: TextStyle(
                        color: purchaseDate == null ? Colors.grey.shade400 : null,
                      ),
                    ),
                  ),
                ),
              ),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '구입 가격'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: sizeController,
                decoration: const InputDecoration(labelText: '사이즈 (예: M / 270)'),
              ),
              if (_recentSizes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _recentSizes
                        .map(
                          (size) => ActionChip(
                            label: Text(size),
                            onPressed: () {
                              setState(() {
                                sizeController.text = size;
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: commentController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: '메모'),
              ),
              const SizedBox(height: 20),
              ColorSelector(
                selectedColor: selectedColor,
                onColorSelected: (color) => setState(() => selectedColor = color),
              ),
              if (_submitted && (selectedColor == null || selectedColor!.isEmpty))
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '색상을 선택해주세요.',
                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '계절',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 10),
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
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isSaving ? null : saveClothes,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
        ),
      ),
    );
  }
}