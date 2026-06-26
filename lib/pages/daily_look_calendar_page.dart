import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/supabase_service.dart';

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
  Future<List<dynamic>>? looksFuture;
  Map<String, Map<String, dynamic>> lookByDate = {};

  void _loadLooks() {
    setState(() {
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
      mapped.putIfAbsent(wearDate, () => map);
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

  List<int> _linkedIds(Map<String, dynamic> look) {
    const keys = [
      'top_item_id',
      'bottom_item_id',
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

  Widget _buildLinkedItemsRow(Map<String, dynamic> look) {
    final ids = _linkedIds(look);
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

        return SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                width: 82,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                clipBehavior: Clip.antiAlias,
                child: item['image_url'] != null
                    ? Image.network(item['image_url'], fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.checkroom),
                      ),
              );
            },
          ),
        );
      },
    );
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
      appBar: AppBar(title: const Text('데일리룩 캘린더')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2020, 1, 1),
            lastDay: DateTime(2100, 12, 31),
            focusedDay: focusedDate,
            selectedDayPredicate: (day) => isSameDay(day, selectedDate),
            onDaySelected: (selected, focused) {
              selectedDate = selected;
              focusedDate = focused;
              _loadLooks();
              setState(() {});
            },
            onPageChanged: (focused) {
              focusedDate = focused;
              _loadMonthLooks(focused);
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final look = lookByDate[_dateKey(day)];
                if (look == null) return null;
                final imageUrl = look['image_url']?.toString();
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(imageUrl, fit: BoxFit.cover),
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(imageUrl, fit: BoxFit.cover),
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
                  return const Center(child: Text('작성된 데일리룩이 없습니다.'));
                }

                return ListView.builder(
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
                                    builder: (_) => DailyLookDetailPage(look: look),
                                  ),
                                );
                                if (changed == true) {
                                  _loadLooks();
                                  _loadMonthLooks(focusedDate);
                                }
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: look['image_url'] != null
                                    ? Image.network(
                                        look['image_url'],
                                        width: double.infinity,
                                        height: 180,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        height: 180,
                                        color: Colors.grey.shade200,
                                        child: const Center(child: Icon(Icons.image_not_supported)),
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
                              alignment: Alignment.centerRight,
                              child: Chip(
                                label: Text((look['is_public'] ?? true) ? '공개' : '비공개'),
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
