import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarViewModel extends ChangeNotifier {
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  late final Stream<QuerySnapshot> outfitsStream;

  CalendarViewModel() {
    selectedDay = focusedDay;
    outfitsStream = FirebaseFirestore.instance
        .collection('outfits')
        .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .where('wear_count', isGreaterThan: 0)
        .snapshots();
  }

  void selectDay(DateTime selected, DateTime focused) {
    selectedDay = selected;
    focusedDay = focused;
    notifyListeners();
  }

  void changePage(DateTime focused) {
    focusedDay = focused;
    notifyListeners();
  }

  void prevMonth() {
    focusedDay = DateTime(focusedDay.year, focusedDay.month - 1);
    notifyListeners();
  }

  void nextMonth() {
    focusedDay = DateTime(focusedDay.year, focusedDay.month + 1);
    notifyListeners();
  }

  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime normalizeDate(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  DateTime? getWearDateTime(Map<String, dynamic> data, DateTime targetDate) {
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
    } catch (_) {
      // ignore
    }
    return null;
  }
}
