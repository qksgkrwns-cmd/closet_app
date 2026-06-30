import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';
import '../widgets/color_selector.dart';

class EditClothesPage extends StatefulWidget {
  final Map item;

  const EditClothesPage({
    super.key,
    required this.item,
  });

  @override
  State<EditClothesPage> createState() => _EditClothesPageState();
}

class _EditClothesPageState extends State<EditClothesPage> {
  static const Map<String, List<String>> categoryHierarchy = {
    '상의': ['반팔티', '긴팔티', '셔츠', '맨투맨', '후드', '니트', '블라우스'],
    '하의': ['청바지', '슬랙스', '면바지', '반바지', '치마', '트레이닝', '레깅스'],
    '아우터': ['자켓', '코트', '패딩', '가디건', '점퍼', '바람막이', '베스트'],
    '신발': ['스니커즈', '로퍼', '구두', '샌들', '부츠', '슬리퍼', '런닝화'],
    '모자': ['볼캡', '버킷햇', '비니', '베레모', '페도라', '썬캡', '니트모자'],
    '잡동사니': ['가방', '시계', '목도리', '장갑', '벨트', '양말', '선글라스'],
  };

  late String selectedCategory;
  late String selectedSubcategory;
  late String selectedBrand;
  late String selectedColor;
  late List<String> selectedSeasons;
  DateTime? purchaseDate;

  final brandController = TextEditingController();
  final priceController = TextEditingController();
  final sizeController = TextEditingController();
  final commentController = TextEditingController();
  File? selectedImage;
  bool _isSaving = false;

  String _purchaseDateText() {
    if (purchaseDate == null) return '미입력';
    return '${purchaseDate!.year}-${purchaseDate!.month.toString().padLeft(2, '0')}-${purchaseDate!.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    final fullCategory = widget.item['category'] ?? '상의';
    
    // "상의/반팔티" 형태면 대분류와 소분류 분리
    if (fullCategory.contains('/')) {
      final parts = fullCategory.split('/');
      selectedCategory = parts[0];
      selectedSubcategory = parts[1];
    } else {
      // 기존 데이터 ("상의" 형태) 호환성 유지
      selectedCategory = fullCategory;
      selectedSubcategory = categoryHierarchy[fullCategory]?.first ?? fullCategory;
    }
    
    selectedBrand = widget.item['brand'] ?? '기타';
    selectedColor = normalizeColorLabel(widget.item['color']?.toString());
    brandController.text = selectedBrand;
    selectedSeasons = List<String>.from(widget.item['seasons'] ?? []);
    final rawPurchaseDate = widget.item['purchase_date'];
    if (rawPurchaseDate is String && rawPurchaseDate.isNotEmpty) {
      purchaseDate = DateTime.tryParse(rawPurchaseDate);
    }
    priceController.text = (widget.item['purchase_price'] ?? '').toString();
    sizeController.text = (widget.item['size'] ?? '').toString();
    commentController.text = (widget.item['comment'] ?? '').toString();
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
    }
  }

  Future<void> updateClothes() async {
    setState(() => _isSaving = true);
    // 대분류와 소분류를 합쳐서 저장 (예: "상의/반팔티")
    final categoryToSave = selectedSubcategory == selectedCategory
        ? selectedCategory
        : '$selectedCategory/$selectedSubcategory';

    try {
      await SupabaseService.updateClothes(
        id: widget.item['id'],
        category: categoryToSave,
        brand: selectedBrand,
        color: selectedColor,
        seasons: selectedSeasons,
        size: sizeController.text,
        purchaseDate: purchaseDate,
        purchasePrice: int.tryParse(priceController.text.trim()),
        comment: commentController.text,
        newImageFile: selectedImage,
        oldImageUrl: widget.item['image_url'],
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수정되었습니다.')),
        );
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('옷 수정')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          child: Column(
            children: [
              if (selectedImage != null)
                Image.file(selectedImage!, height: 200)
              else if (widget.item['image_url'] != null)
                Image.network(widget.item['image_url'], height: 200),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: pickImage, child: const Text('사진 변경')),
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
                      selectedSubcategory = categoryHierarchy[value]!.first;
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
              const SizedBox(height: 16),
              TextFormField(
                controller: brandController,
                decoration: const InputDecoration(labelText: '브랜드'),
                onChanged: (value) => selectedBrand = value,
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: commentController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: '메모'),
              ),
              const SizedBox(height: 16),
              ColorSelector(
                selectedColor: selectedColor,
                onColorSelected: (color) => setState(() => selectedColor = color),
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
            onPressed: _isSaving ? null : updateClothes,
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