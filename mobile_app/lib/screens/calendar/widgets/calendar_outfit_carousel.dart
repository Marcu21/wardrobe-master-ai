import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/widgets/smart_outfit_card.dart';
import 'package:mobile_app/screens/outfit_detail/outfit_detail_screen.dart';

class CalendarOutfitCarousel extends StatelessWidget {
  final List<Map<String, dynamic>> dayOutfits;
  final DateTime? selectedDay;

  const CalendarOutfitCarousel({
    super.key,
    required this.dayOutfits,
    required this.selectedDay,
  });

  String _getWearTime(Map<String, dynamic> data, DateTime? targetDate) {
    if (targetDate == null) return '';
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
        return DateFormat.jm().format(timestamp.toDate());
      }
    } catch (e) {
      // ignore
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        width: double.infinity,
        child: dayOutfits.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.calendar_badge_minus,
                        size: 36,
                        color: Colors.black38,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No outfits logged',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Wear an outfit to log it here',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black38,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: dayOutfits.length,
                itemBuilder: (context, index) {
                  final data = dayOutfits[index];
                  final String name = data['name'] ?? 'Untitled';
                  final String wearTime = _getWearTime(data, selectedDay);

                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
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
                      footer: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(20),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              border: Border(
                                top: BorderSide(
                                  color: Colors.black.withOpacity(0.06),
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: Colors.black87,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      CupertinoIcons.clock,
                                      size: 10,
                                      color: Colors.black38,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      wearTime.isNotEmpty ? wearTime : 'Logged',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black45,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
