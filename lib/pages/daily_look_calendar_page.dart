import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/supabase_service.dart';
import '../widgets/app_network_image.dart';
import '../widgets/empty_state_view.dart';

import '../services/daily_look_service.dart';
import 'daily_look_detail_page.dart';
import 'daily_look_editor_page.dart';

class DailyLookCalendarPage extends StatefulWidget {
  const DailyLookCalendarPage({super.key});

  @override
  State<DailyLookCalendarPage> createState() => _DailyLookCalendarPageState();
}

class _DailyLookCalendarPageState extends State<DailyLookCalendarPage> {
  DateTime selectedDate = DateTime.now();
  DateTime focusedDate = DateTime.now();
  CalendarFormat calendarFormat = CalendarFormat.twoWeeks;
  Future<List<dynamic>>? looksFuture;
  Map<String, Map<String, dynamic>> lookByDate = {};
  final Map<String, ValueNotifier<Map<String, dynamic>?>> selectedLinkedItemByLook = {};
  final Map<int, int> itemLikesCount = {};
  final Map<int, ValueNotifier<bool>> visibilityUpdatingByLookId = {};
  final Map<int, ValueNotifier<bool>> visibilityValueByLookId = {};

  void _resetLookUiStates() {
    for (final notifier in selectedLinkedItemByLook.values) {
      notifier.dispose();
    }
    selectedLinkedItemByLook.clear();
    for (final notifier in visibilityUpdatingByLookId.values) {
      notifier.dispose();
    }
    visibilityUpdatingByLookId.clear();
    for (final notifier in visibilityValueByLookId.values) {
      notifier.dispose();
    }
    visibilityValueByLookId.clear();
  }

  ValueNotifier<Map<String, dynamic>?> _selectedItemNotifier(String lookKey) {
    return selectedLinkedItemByLook.putIfAbsent(
      lookKey,
      () => ValueNotifier<Map<String, dynamic>?>(null),
    );
  }

  ValueNotifier<bool> _visibilityNotifier(Map<String, dynamic> look) {
    final rawId = look['id'];
    final lookId = rawId is num ? rawId.toInt() : int.tryParse(rawId?.toString() ?? '');
    if (lookId == null) {
      return ValueNotifier<bool>(look['is_public'] == true);
    }
    return visibilityValueByLookId.putIfAbsent(
      lookId,
      () => ValueNotifier<bool>(look['is_public'] == true),
    );
  }

  ValueNotifier<bool> _visibilityUpdatingNotifier(int lookId) {
    return visibilityUpdatingByLookId.putIfAbsent(
      lookId,
      () => ValueNotifier<bool>(false),
    );
  }

  void _loadLooks() {
    setState(() {
      _resetLookUiStates();
      looksFuture = DailyLookService.fetchMyLooksByDate(selectedDate);
    });
  }

  Future<void> _loadMonthLooks(DateTime base) async {
    final first = DateTime(base.year, base.month, 1);
    final last = DateTime(base.year, base.month + 1, 0);
    final rows = await DailyLookService.fetchMyLooksInRange(first, last);

    final mapped = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final map = Map<String, dynamic>.from(row);
      final wearDate = (map['wear_date'] ?? '').toString();
      if (wearDate.isEmpty) continue;
      final existing = mapped[wearDate];
      if (existing == null) {
        mapped[wearDate] = map;
        continue;
      }
      final existingHasImage = (existing['image_url'] ?? '').toString().trim().isNotEmpty;
      final currentHasImage = (map['image_url'] ?? '').toString().trim().isNotEmpty;
      if (!existingHasImage && currentHasImage) {
        mapped[wearDate] = map;
      }
    }

    if (!mounted) return;
    setState(() {
      lookByDate = mapped;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month}.${date.day}';
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isBlank(dynamic value) {
    return value == null || value.toString().trim().isEmpty;
  }

  String _formatPurchaseDate(dynamic raw) {
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    if (parsed == null) return '';
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }

  String _formatPurchasePrice(dynamic raw) {
    final price = raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '');
    if (price == null) return '';
    return '${price}원';
  }

  List<int> _linkedIds(Map<String, dynamic> look) {
    const keys = [
      'top_item_id',
      'bottom_item_id',
      'outer_item_id',
      'shoes_item_id',
      'hat_item_id',
      'bag_item_id',
      'accessory_item_id',
    ];
    final ids = <int>[];
    for (final key in keys) {
      final raw = look[key];
      if (raw is num) ids.add(raw.toInt());
      if (raw is String) {
        final parsed = int.tryParse(raw);
        if (parsed != null) ids.add(parsed);
      }
    }
    return ids;
  }

  String _lookKey(Map<String, dynamic> look) {
    final raw = look['id'];
    if (raw is num) return raw.toInt().toString();
    return (raw ?? '').toString();
  }

  Future<void> _togglePublic(Map<String, dynamic> look) async {
    final rawId = look['id'];
    final lookId = rawId is num ? rawId.toInt() : int.tryParse(rawId?.toString() ?? '');
    if (lookId == null) return;
    final visibility = _visibilityNotifier(look);
    final current = visibility.value;
    final next = !current;
    final wearDateKey = (look['wear_date'] ?? '').toString();
    final updating = _visibilityUpdatingNotifier(lookId);

    updating.value = true;
    visibility.value = next;
    look['is_public'] = next;
    if (wearDateKey.isNotEmpty && lookByDate.containsKey(wearDateKey)) {
      lookByDate[wearDateKey]!['is_public'] = next;
    }

    try {
      await DailyLookService.updateLookVisibility(id: lookId, isPublic: next);
      if (!mounted) return;
      updating.value = false;
    } catch (e) {
      if (!mounted) return;
      updating.value = false;
      visibility.value = current;
      look['is_public'] = current;
      if (wearDateKey.isNotEmpty && lookByDate.containsKey(wearDateKey)) {
        lookByDate[wearDateKey]!['is_public'] = current;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('공개 상태 변경 실패: $e')),
      );
    }
  }

  Future<void> _ensureItemLikesCount(int itemId) async {
    if (itemLikesCount.containsKey(itemId)) return;
    try {
      final count = await SupabaseService.getClothesLikesCount(itemId);
      if (!mounted) return;
      itemLikesCount[itemId] = count;
    } catch (_) {
      if (!mounted) return;
      itemLikesCount[itemId] = 0;
    }
  }

  Widget _buildLinkedItemsRow(Map<String, dynamic> look) {
    final ids = _linkedIds(look);
    final lookKey = _lookKey(look);
    final selectedNotifier = _selectedItemNotifier(lookKey);
    if (ids.isEmpty) {
      return const SizedBox(
        height: 70,
        child: Center(child: Text('연결된 아이템이 없습니다.')),
      );
    }

    return FutureBuilder<List<dynamic>>(
      future: SupabaseService.fetchClothesByIds(ids),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 70,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const SizedBox(
            height: 70,
            child: Center(child: Text('연결된 아이템이 없습니다.')),
          );
        }

        final byId = <int, Map<String, dynamic>>{};
        for (final row in items) {
          final item = Map<String, dynamic>.from(row);
          final rawId = item['id'];
          final itemId = rawId is num ? rawId.toInt() : int.tryParse(rawId?.toString() ?? '');
          if (itemId != null) {
            byId[itemId] = item;
          }
        }
        final orderedItems = ids
            .map((id) => byId[id])
            .whereType<Map<String, dynamic>>()
            .toList();
        if (orderedItems.isEmpty) {
          return const SizedBox(
            height: 70,
            child: Center(child: Text('연결된 아이템이 없습니다.')),
          );
        }

        return ValueListenableBuilder<Map<String, dynamic>?>(
          valueListenable: selectedNotifier,
          builder: (context, selectedItem, _) {
            final selectedIdRaw = selectedItem?['id'];
            final selectedId = selectedIdRaw is num
                ? selectedIdRaw.toInt()
                : int.tryParse(selectedIdRaw?.toString() ?? '');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 82,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: orderedItems.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = orderedItems[index];
                      final rawId = item['id'];
                      final itemId = rawId is num ? rawId.toInt() : int.tryParse(rawId?.toString() ?? '');
                      final isSelected = itemId != null && itemId == selectedId;

                      return GestureDetector(
                        onTap: () async {
                          if (itemId == null) return;
                          if (isSelected) {
                            selectedNotifier.value = null;
                            return;
                          }
                          selectedNotifier.value = item;
                          await _ensureItemLikesCount(itemId);
                          if (selectedNotifier.value != null &&
                              (selectedNotifier.value!['id']?.toString() == item['id']?.toString())) {
                            selectedNotifier.value = Map<String, dynamic>.from(item);
                          }
                        },
                        child: Container(
                          width: 82,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? Colors.orange : Colors.grey.shade300,
                              width: isSelected ? 1.8 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: AppNetworkImage(
                            imageUrl: item['image_url']?.toString(),
                            fit: BoxFit.cover,
                            fallbackIcon: Icons.checkroom,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (selectedItem != null) ...[
                  const SizedBox(height: 10),
                  Builder(
                    builder: (context) {
                      final seasonsRaw = selectedItem['seasons'];
                      final seasons = seasonsRaw is List
                          ? seasonsRaw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
                          : <String>[];
                      final rawId = selectedItem['id'];
                      final selectedItemId = rawId is num ? rawId.toInt() : int.tryParse(rawId?.toString() ?? '');
                      final likesCount = selectedItemId == null ? 0 : (itemLikesCount[selectedItemId] ?? 0);

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                          color: Colors.white,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!_isBlank(selectedItem['brand']))
                              Text(
                                selectedItem['brand'].toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            if (!_isBlank(selectedItem['category']))
                              Text('카테고리: ${selectedItem['category']}',
                                  style: const TextStyle(color: Colors.black87)),
                            if (seasons.isNotEmpty)
                              Text('계절: ${seasons.join(', ')}',
                                  style: const TextStyle(color: Colors.black87)),
                            if (_formatPurchaseDate(selectedItem['purchase_date']).isNotEmpty)
                              Text('구입시기: ${_formatPurchaseDate(selectedItem['purchase_date'])}',
                                  style: const TextStyle(color: Colors.black87)),
                            if (_formatPurchasePrice(selectedItem['purchase_price']).isNotEmpty)
                              Text('구입가격: ${_formatPurchasePrice(selectedItem['purchase_price'])}',
                                  style: const TextStyle(color: Colors.black87)),
                            if (!_isBlank(selectedItem['size']))
                              Text('사이즈: ${selectedItem['size']}',
                                  style: const TextStyle(color: Colors.black87)),
                            if (!_isBlank(selectedItem['comment']))
                              Text('메모: ${selectedItem['comment']}',
                                  style: const TextStyle(color: Colors.black87)),
                            if (likesCount >= 1)
                              Text('좋아요 횟수: $likesCount',
                                  style: const TextStyle(color: Colors.black87)),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _resetLookUiStates();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadLooks();
    _loadMonthLooks(focusedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('데일리룩')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2020, 1, 1),
            lastDay: DateTime(2100, 12, 31),
            focusedDay: focusedDate,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
              CalendarFormat.twoWeeks: '2 weeks',
            },
            calendarFormat: calendarFormat,
            onFormatChanged: (format) {
              if (calendarFormat != format) {
                setState(() => calendarFormat = format);
              }
            },
            selectedDayPredicate: (day) => isSameDay(day, selectedDate),
            onDaySelected: (selected, focused) {
              selectedDate = selected;
              focusedDate = focused;
              _loadLooks();
              setState(() {});
            },
            onPageChanged: (focused) {
              focusedDate = focused;
              _resetLookUiStates();
              _loadMonthLooks(focused);
            },
            calendarBuilders: CalendarBuilders(
              todayBuilder: (context, day, focusedDay) {
                final look = lookByDate[_dateKey(day)];
                if (look == null) {
                  return Container(
                    alignment: Alignment.center,
                    child: Text('${day.day}'),
                  );
                }
                final imageUrl = look['image_url']?.toString();
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(imageUrl, fit: BoxFit.contain),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange.shade700, width: 1.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                );
              },
              defaultBuilder: (context, day, focusedDay) {
                final look = lookByDate[_dateKey(day)];
                if (look == null) return null;
                final imageUrl = look['image_url']?.toString();
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(imageUrl, fit: BoxFit.contain),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                );
              },
              selectedBuilder: (context, day, focusedDay) {
                final look = lookByDate[_dateKey(day)];
                if (look == null) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black87, width: 1.4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text('${day.day}'),
                  );
                }
                final imageUrl = look['image_url']?.toString();
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(imageUrl, fit: BoxFit.contain),
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black87, width: 1.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_formatDate(selectedDate)} 착장',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: looksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final looks = snapshot.data ?? [];
                if (looks.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.calendar_month,
                    title: '작성된 데일리룩이 없습니다.',
                    subtitle: '오른쪽 아래 + 버튼으로 오늘의 룩을 등록해보세요.',
                  );
                }

                return ListView.builder(
                  key: const PageStorageKey<String>('daily-look-calendar-list'),
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: looks.length,
                  itemBuilder: (context, index) {
                    final look = looks[index] as Map<String, dynamic>;
                    final hashtags = (look['hashtags'] as List?)?.join(' ') ?? '';
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final changed = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DailyLookDetailPage(
                                      look: look,
                                      showAccountLink: false,
                                    ),
                                  ),
                                );
                                if (changed == true) {
                                  _loadLooks();
                                  _loadMonthLooks(focusedDate);
                                }
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  height: 180,
                                  child: AppNetworkImage(
                                    imageUrl: look['image_url']?.toString(),
                                    fit: BoxFit.contain,
                                    fallbackIcon: Icons.image_not_supported,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              (look['content'] ?? '').toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hashtags,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 8),
                            _buildLinkedItemsRow(look),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.center,
                              child: Builder(
                                builder: (context) {
                                  final rawId = look['id'];
                                  final lookId = rawId is num
                                      ? rawId.toInt()
                                      : int.tryParse(rawId?.toString() ?? '');
                                  if (lookId == null) {
                                    return ActionChip(
                                      onPressed: null,
                                      label: Text((look['is_public'] ?? true) ? '공개' : '비공개'),
                                    );
                                  }
                                  final publicNotifier = _visibilityNotifier(look);
                                  final updatingNotifier = _visibilityUpdatingNotifier(lookId);
                                  return ValueListenableBuilder<bool>(
                                    valueListenable: updatingNotifier,
                                    builder: (context, isUpdating, _) {
                                      return ValueListenableBuilder<bool>(
                                        valueListenable: publicNotifier,
                                        builder: (context, isPublic, __) {
                                          return ActionChip(
                                            onPressed: isUpdating ? null : () => _togglePublic(look),
                                            label: isUpdating
                                                ? const SizedBox(
                                                    width: 14,
                                                    height: 14,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  )
                                                : Text(isPublic ? '공개' : '비공개'),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final existing = await DailyLookService.fetchMyLooksByDate(selectedDate);
          final existingLook = existing.isNotEmpty ? Map<String, dynamic>.from(existing.first) : null;

          if (!context.mounted) return;

          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => DailyLookEditorPage(
                selectedDate: selectedDate,
                existingLook: existingLook,
              ),
            ),
          );
          if (created == true) {
            _loadLooks();
            _loadMonthLooks(focusedDate);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
