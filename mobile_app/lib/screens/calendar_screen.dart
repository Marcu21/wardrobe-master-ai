import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'outfit_detail_screen.dart';
import '../widgets/smart_outfit_card.dart';

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

  DateTime? _getWearDateTime(Map<String, dynamic> data, DateTime targetDate) {
    final List<dynamic> dates = data['wear_dates'] ?? [];
    try {
      final timestamp = dates.firstWhere(
        (d) {
          if (d is Timestamp) {
            final dt = d.toDate();
            return dt.year == targetDate.year &&
                dt.month == targetDate.month &&
                dt.day == targetDate.day;
          }
          return false;
        },
        orElse: () => null,
      );
      if (timestamp != null && timestamp is Timestamp) {
        return timestamp.toDate();
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  /// Returns the formatted wear time for [data] on [targetDate], or empty string.
  String _getWearTime(Map<String, dynamic> data, DateTime? targetDate) {
    if (targetDate == null) return '';
    final List<dynamic> dates = data['wear_dates'] ?? [];
    try {
      final timestamp = dates.firstWhere(
        (d) {
          if (d is Timestamp) {
            final dt = d.toDate();
            return dt.year == targetDate.year &&
                dt.month == targetDate.month &&
                dt.day == targetDate.day;
          }
          return false;
        },
        orElse: () => null,
      );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Style Calendar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _outfitsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              debugPrint('Calendar Error: ${snapshot.error}');
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Database Index Error.\nCheck your debug console for a direct link to create the required Firestore index.',
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
                    groupedOutfits[normalizedDate] ??= [];
                    data['id'] = doc.id;
                    groupedOutfits[normalizedDate]!.add(data);
                  }
                }
              }
            }

            List<Map<String, dynamic>> dayOutfits = _selectedDay != null
                ? groupedOutfits[_normalizeDate(_selectedDay!)] ?? []
                : [];

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

                // Horizontal carousel of outfits for the selected day
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
                                  'No outfits logged for this day',
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
                              final String name =
                                  data['name'] ?? 'Untitled';
                              final String wearTime =
                                  _getWearTime(data, _selectedDay);

                              return Container(
                                width: 150,
                                margin: const EdgeInsets.only(right: 16),
                                child: SmartOutfitCard(
                                  key: ValueKey(data['id']),
                                  outfitData: data,
                                  outfitId: data['id'] ?? '',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OutfitDetailScreen(
                                        outfitData: data,
                                        outfitId: data['id'] ?? '',
                                      ),
                                    ),
                                  ),
                                  footer: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border(
                                        top: BorderSide(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          name,
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
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              wearTime.isNotEmpty
                                                  ? wearTime
                                                  : 'Logged',
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
                                ),
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
