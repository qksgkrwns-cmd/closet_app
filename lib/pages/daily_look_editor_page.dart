import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/daily_look_service.dart';
import '../services/supabase_service.dart';
import '../widgets/app_network_image.dart';
import 'daily_look_item_picker_page.dart';

class DailyLookEditorPage extends StatefulWidget {
  final DateTime selectedDate;
  final Map<String, dynamic>? existingLook;

  const DailyLookEditorPage({
    super.key,
    required this.selectedDate,
    this.existingLook,
  });

  @override
  State<DailyLookEditorPage> createState() => _DailyLookEditorPageState();
}

class _DailyLookEditorPageState extends State<DailyLookEditorPage> {
  final contentController = TextEditingController();
  final hashtagsController = TextEditingController();

  bool isPublic = true;
  File? selectedImage;
  String? existingImageUrl;
  bool isSaving = false;
  bool _submitted = false;

  final Map<String, int?> selectedItemIds = {
    'top_item_id': null,
    'bottom_item_id': null,
    'outer_item_id': null,
    'shoes_item_id': null,
    'hat_item_id': null,
    'bag_item_id': null,
    'accessory_item_id': null,
  };

  final List<Map<String, String>> itemConfig = const [
    {'label': '상의', 'key': 'top_item_id'},
    {'label': '하의', 'key': 'bottom_item_id'},
    {'label': '아우터', 'key': 'outer_item_id'},
    {'label': '신발', 'key': 'shoes_item_id'},
    {'label': '모자', 'key': 'hat_item_id'},
    {'label': '가방', 'key': 'bag_item_id'},
    {'label': '액세서리', 'key': 'accessory_item_id'},
  ];

  final Map<String, Map<String, dynamic>> selectedItems = {};

  @override
  void initState() {
    super.initState();
    _loadInitialValues();
  }

  @override
  void dispose() {
    contentController.dispose();
    hashtagsController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialValues() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultPublic = prefs.getBool('daily_look_default_public') ?? true;

    final look = widget.existingLook;
    if (look != null) {
      contentController.text = (look['content'] ?? '').toString();
      hashtagsController.text = ((look['hashtags'] as List?) ?? [])
          .map((e) => e.toString())
          .join(' ');
      isPublic = look['is_public'] ?? defaultPublic;
      existingImageUrl = look['image_url']?.toString();

      for (final entry in selectedItemIds.entries) {
        final raw = look[entry.key];
        if (raw is num) {
          selectedItemIds[entry.key] = raw.toInt();
        } else if (raw != null) {
          selectedItemIds[entry.key] = int.tryParse(raw.toString());
        }
      }
    } else {
      isPublic = defaultPublic;
    }

    await _loadSelectedItems();
    if (mounted) setState(() {});
  }

  Future<void> _loadSelectedItems() async {
    final ids = selectedItemIds.values.whereType<int>().toList();
    if (ids.isEmpty) return;
    final rows = await SupabaseService.fetchClothesByIds(ids);
    final byId = <int, Map<String, dynamic>>{};
    for (final row in rows) {
      final rawId = row['id'];
      final id = rawId is num ? rawId.toInt() : int.tryParse(rawId.toString());
      if (id != null) byId[id] = Map<String, dynamic>.from(row);
    }

    for (final entry in selectedItemIds.entries) {
      final id = entry.value;
      if (id != null && byId.containsKey(id)) {
        selectedItems[entry.key] = byId[id]!;
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => selectedImage = File(file.path));
  }

  List<String> _parseHashtags(String raw) {
    final parts = raw
        .split(RegExp(r'[\s,]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) => e.startsWith('#') ? e : '#$e')
        .toList();
    return parts;
  }

  Future<void> _save() async {
    final content = contentController.text.trim();
    setState(() => _submitted = true);
    final hasImage = selectedImage != null || (existingImageUrl?.trim().isNotEmpty == true);
    if (!hasImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('데일리룩 이미지를 등록해주세요.')),
      );
      return;
    }

    setState(() => isSaving = true);
    try {
      await DailyLookService.saveDailyLook(
        id: widget.existingLook?['id'] is num ? (widget.existingLook!['id'] as num).toInt() : null,
        wearDate: widget.selectedDate,
        content: content,
        hashtags: _parseHashtags(hashtagsController.text),
        isPublic: isPublic,
        imageFile: selectedImage,
        oldImageUrl: existingImageUrl,
        topItemId: selectedItemIds['top_item_id'],
        bottomItemId: selectedItemIds['bottom_item_id'],
        outerItemId: selectedItemIds['outer_item_id'],
        shoesItemId: selectedItemIds['shoes_item_id'],
        hatItemId: selectedItemIds['hat_item_id'],
        bagItemId: selectedItemIds['bag_item_id'],
        accessoryItemId: selectedItemIds['accessory_item_id'],
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('daily_look_default_public', isPublic);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('데일리룩이 저장되었습니다.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _pickClosetItem(String label, String key) async {
    final selected = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => DailyLookItemPickerPage(
          categoryLabel: label,
          slotKey: key,
          selectedItemId: selectedItemIds[key],
        ),
      ),
    );

    if (selected == null) return;
    final rawId = selected['id'];
    final id = rawId is num ? rawId.toInt() : int.tryParse(rawId.toString());
    if (id == null) return;

    setState(() {
      selectedItemIds[key] = id;
      selectedItems[key] = Map<String, dynamic>.from(selected);
    });
  }

  Widget _buildSelectedItemCard(String label, String key) {
    final item = selectedItems[key];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _pickClosetItem(label, key),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: AppNetworkImage(
                  imageUrl: item?['image_url']?.toString(),
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.checkroom,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: item == null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('선택된 아이템 없음', style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            (item['brand'] ?? 'No Brand').toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${item['color'] ?? ''} · ${item['category'] ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
              ),
              Column(
                children: [
                  IconButton(
                    onPressed: () => _pickClosetItem(label, key),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  if (item != null)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          selectedItemIds[key] = null;
                          selectedItems.remove(key);
                        });
                      },
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = selectedImage != null || (existingImageUrl?.trim().isNotEmpty == true);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingLook == null ? '오늘의 코디 작성' : '데일리 코디 수정'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          children: [
            if (selectedImage != null)
              Image.file(selectedImage!, height: 220, fit: BoxFit.cover)
            else if (existingImageUrl != null)
              SizedBox(
                height: 220,
                child: AppNetworkImage(
                  imageUrl: existingImageUrl,
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.image_not_supported,
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('화면 사진 업로드'),
            ),
            if (_submitted && !hasImage)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '데일리룩 이미지를 등록해주세요.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              minLines: 3,
              maxLines: 6,
              onChanged: (_) {
                if (_submitted) setState(() {});
              },
              decoration: const InputDecoration(
                labelText: '내용 입력 (선택)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hashtagsController,
              decoration: const InputDecoration(
                labelText: '해시태그 (공백/콤마 구분)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: isPublic,
              onChanged: (value) => setState(() => isPublic = value),
              title: const Text('공개 여부'),
              subtitle: const Text('현재 설정은 다음 작성 시 기본값으로 유지됩니다.'),
            ),
            const Divider(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '착용 아이템 연결 (기존 옷장에서 선택)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            ...itemConfig.map(
              (cfg) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildSelectedItemCard(cfg['label']!, cfg['key']!),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton(
          onPressed: isSaving ? null : _save,
          child: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('작성 완료'),
        ),
      ),
    );
  }
}
