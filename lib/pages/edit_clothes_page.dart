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
  late String selectedCategory;
  late String selectedBrand;
  late String selectedColor;
  late List<String> selectedSeasons;

  final brandController = TextEditingController();
  File? selectedImage;

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.item['category'];
    selectedBrand = widget.item['brand'] ?? '기타';
    selectedColor = widget.item['color'];
    brandController.text = selectedBrand;
    selectedSeasons = List<String>.from(widget.item['seasons'] ?? []);
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
    }
  }

  Future<void> updateClothes() async {
    await SupabaseService.updateClothes(
      id: widget.item['id'],
      category: selectedCategory,
      brand: selectedBrand,
      color: selectedColor,
      seasons: selectedSeasons,
      newImageFile: selectedImage,
      oldImageUrl: widget.item['image_url'],
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('옷 수정')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: brandController,
                decoration: const InputDecoration(labelText: '브랜드'),
                onChanged: (value) => selectedBrand = value,
              ),
              const SizedBox(height: 16),
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
              ElevatedButton(onPressed: updateClothes, child: const Text('저장')),
            ],
          ),
        ),
      ),
    );
  }
}