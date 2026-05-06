import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/firebase_service.dart';
import 'outfit_detail_screen.dart';
import '../utils/outfit_sorting_utils.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late Stream<QuerySnapshot> _outfitsStream;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _outfitsStream = FirebaseFirestore.instance
        .collection('outfits')
        .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .where('wear_count', isGreaterThan: 0)
        .snapshots();
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  // 1. Helper to extracting DateTimes for sorting
  DateTime? _getWearDateTime(Map<String, dynamic> data, DateTime targetDate) {
    final List<dynamic> dates = data['wear_dates'] ?? [];
    try {
      final timestamp = dates.firstWhere((d) {
        if (d is Timestamp) {
          final dt = d.toDate();
          return dt.year == targetDate.year &&
              dt.month == targetDate.month &&
              dt.day == targetDate.day;
        }
        return false;
      }, orElse: () => null);

      if (timestamp != null && timestamp is Timestamp) {
        return timestamp.toDate();
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Style Calendar",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _outfitsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              debugPrint("Calendar Error: ${snapshot.error}");
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    "Database Index Error.\nCheck your debug console for a direct link to create the required Firestore index.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final Map<DateTime, List<Map<String, dynamic>>> groupedOutfits = {};

            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final List<dynamic> datesDynamic = data['wear_dates'] ?? [];

                for (var dateEntry in datesDynamic) {
                  if (dateEntry is Timestamp) {
                    final normalizedDate = _normalizeDate(dateEntry.toDate());
                    if (groupedOutfits[normalizedDate] == null) {
                      groupedOutfits[normalizedDate] = [];
                    }
                    // Inject ID for navigation
                    data['id'] = doc.id;
                    groupedOutfits[normalizedDate]!.add(data);
                  }
                }
              }
            }

            // Get outfits for the currently selected day
            List<Map<String, dynamic>> dayOutfits = _selectedDay != null
                ? groupedOutfits[_normalizeDate(_selectedDay!)] ?? []
                : [];

            // 2. Sort outfits chronologically
            if (_selectedDay != null && dayOutfits.isNotEmpty) {
              dayOutfits.sort((a, b) {
                final dtA = _getWearDateTime(a, _selectedDay!);
                final dtB = _getWearDateTime(b, _selectedDay!);
                if (dtA == null && dtB == null) return 0;
                if (dtA == null) return 1;
                if (dtB == null) return -1;
                return dtA.compareTo(dtB);
              });
            }

            return Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => _isSameDay(_selectedDay, day),
                  calendarFormat: CalendarFormat.month,

                  eventLoader: (day) {
                    return groupedOutfits[_normalizeDate(day)] ?? [];
                  },

                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isNotEmpty) {
                        return Positioned(
                          bottom: 8,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                  ),

                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },

                  calendarStyle: CalendarStyle(
                    selectedDecoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.grey[400],
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),

                Divider(height: 1, color: Colors.grey[300]),

                // 2. Horizontal Carousel Section
                Expanded(
                  child: Container(
                    color: Colors.grey[50],
                    width: double.infinity,
                    child: dayOutfits.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.checkroom_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "No outfits logged for this day",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.all(16),
                            itemCount: dayOutfits.length,
                            itemBuilder: (context, index) {
                              final data = dayOutfits[index];
                              return CalendarOutfitCard(
                                key: ValueKey(data['id']),
                                outfitData: data,
                                wearDateTarget: _selectedDay,
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class CalendarOutfitCard extends StatefulWidget {
  final Map<String, dynamic> outfitData;
  final DateTime? wearDateTarget;

  const CalendarOutfitCard({
    super.key,
    required this.outfitData,
    this.wearDateTarget,
  });

  @override
  State<CalendarOutfitCard> createState() => _CalendarOutfitCardState();
}

class _CalendarOutfitCardState extends State<CalendarOutfitCard> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    try {
      final List<dynamic> itemIdsDynamic = widget.outfitData['item_ids'] ?? [];
      final List<String> itemIds = itemIdsDynamic
          .map((e) => e.toString())
          .toList();

      if (itemIds.isNotEmpty) {
        final items = await _firebaseService.getItemsByIds(itemIds);
        if (mounted) {
          setState(() {
            _items = OutfitSortingUtils.sortOutfitItems(items);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching outfit items: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildThumbnail(Map<String, dynamic> item) {
    final String rawData = item['imageUrl'] ?? '';

    if (rawData.isEmpty) {
      return const SizedBox.shrink();
    }

    Widget imageWidget;
    try {
      if (rawData.startsWith('data:image')) {
        final String base64String = rawData.split(',').last;
        imageWidget = Image.memory(
          base64Decode(base64String),
          fit: BoxFit.contain, // Contain to show full item
          alignment: Alignment.center,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, color: Colors.grey),
        );
      } else if (rawData.startsWith('http')) {
        imageWidget = CachedNetworkImage(
          imageUrl: rawData,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          errorWidget: (context, url, error) =>
              const Icon(Icons.broken_image, color: Colors.grey),
        );
      } else {
        // Try raw base64 if no prefix
        try {
          imageWidget = Image.memory(
            base64Decode(rawData),
            fit: BoxFit.contain,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.checkroom, color: Colors.grey),
          );
        } catch (e) {
          imageWidget = const Icon(Icons.checkroom, color: Colors.grey);
        }
      }
    } catch (e) {
      imageWidget = const Icon(Icons.error, color: Colors.grey);
    }

    return SizedBox(width: double.infinity, child: imageWidget);
  }

  String _getWearTime() {
    if (widget.wearDateTarget == null) return '';
    final List<dynamic> dates = widget.outfitData['wear_dates'] ?? [];

    try {
      final timestamp = dates.firstWhere((d) {
        if (d is Timestamp) {
          final dt = d.toDate();
          return dt.year == widget.wearDateTarget!.year &&
              dt.month == widget.wearDateTarget!.month &&
              dt.day == widget.wearDateTarget!.day;
        }
        return false;
      }, orElse: () => null);

      if (timestamp != null && timestamp is Timestamp) {
        return DateFormat.jm().format(timestamp.toDate());
      }
    } catch (e) {
      // ignore
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.outfitData['name'] ?? 'Untitled';
    final String wearTime = _getWearTime();

    return Container(
      width: 150, // 3. Updated Width to 150 (Narrower)
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OutfitDetailScreen(
                outfitData: widget.outfitData,
                outfitId: widget.outfitData['id'] ?? '',
              ),
            ),
          );
        },
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Vertical Item Stack (Expanded)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Colors.grey.shade50],
                    ),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _items.isEmpty
                      ? Center(
                          child: Icon(
                            Icons.checkroom,
                            size: 40,
                            color: Colors.grey[300],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _items.map((item) {
                            // Dynamic Flex
                            int flex = 3;
                            final info = item['basic_info'] ?? {};
                            String cat = (info['category'] ?? '')
                                .toString()
                                .toLowerCase();
                            if (cat.contains('bottom') ||
                                cat.contains('pant')) {
                              flex = 4;
                            } else if (cat.contains('shoe') ||
                                cat.contains('footwear'))
                              flex = 2;

                            return Expanded(
                              flex: flex,
                              child: _buildThumbnail(item),
                            );
                          }).toList(),
                        ),
                ),
              ),

              // 2. Info Section (Compact Footer)
              Container(
                // 4. Compact Padding
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      // 5. Smaller Font Size
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 10,
                          color: Colors.grey[600],
                        ), // Smaller Icon
                        const SizedBox(width: 4),
                        Text(
                          wearTime.isNotEmpty ? wearTime : "Logged",
                          // 6. Smaller Font Size
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
