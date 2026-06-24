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
  String selectedColor = '검정';
  String selectedBrand = '기타';
  List<String> selectedSeasons = [];
  final brandController = TextEditingController();

  @override
  void initState() {
    super.initState();
    brandController.text = selectedBrand;
  }

  @override
  void dispose() {
    brandController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      setState(() {
        selectedImage = File(file.path);
      });
      //await analyzeImage();
    }
  }

  Future<void> analyzeImage() async {
    if (selectedImage == null) return;

    try {
      final result = await GeminiService.analyzeClothesImage(selectedImage!);

      setState(() {
        selectedCategory = result['category'] ?? '상의';
        selectedBrand = result['brand'] ?? '기타';
        brandController.text = selectedBrand;
        selectedColor = result['color'] ?? '검정';
        selectedSeasons = List<String>.from(result['seasons'] ?? []);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'AI 분석 서버가 혼잡합니다. 잠시 후 다시 시도해주세요.',
            ),
          ),
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
        imageFile: selectedImage,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('옷 등록'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ElevatedButton(
                onPressed: pickImage,
                child: const Text('사진 선택'),
              ),
              const SizedBox(height: 20),
              if (selectedImage != null)
                Image.file(selectedImage!, height: 200),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: '카테고리'),
                items: const [
                  DropdownMenuItem(value: '상의', child: Text('상의')),
                  DropdownMenuItem(value: '하의', child: Text('하의')),
                  DropdownMenuItem(value: '아우터', child: Text('아우터')),
                  DropdownMenuItem(value: '신발', child: Text('신발')),
                  DropdownMenuItem(value: '모자', child: Text('모자')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: brandController,
                decoration: const InputDecoration(labelText: '브랜드'),
                onChanged: (value) {
                  selectedBrand = value;
                },
              ),
              const SizedBox(height: 20),
              ColorSelector(
                selectedColor: selectedColor,
                onColorSelected: (color) {
                  setState(() {
                    selectedColor = color;
                  });
                },
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '계절',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: ['봄', '여름', '가을', '겨울']
                    .map((season) {
                      return FilterChip(
                        label: Text(season),
                        selected: selectedSeasons.contains(season),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedSeasons.add(season);
                            } else {
                              selectedSeasons.remove(season);
                            }
                          });
                        },
                      );
                    })
                    .toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveClothes,
                child: const Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}