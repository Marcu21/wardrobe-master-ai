import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'calendar_view_model.dart';
import 'widgets/calendar_header.dart';
import 'widgets/calendar_outfit_carousel.dart';

const _kBlob1 = Color(0x380EA5E9);
const _kBlob2 = Color(0x200284C7);

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CalendarViewModel(),
      child: const _CalendarBody(),
    );
  }
}

class _CalendarBody extends StatelessWidget {
  const _CalendarBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CalendarViewModel>();
    return Scaffold(
      backgroundColor: kBgColor,
      body: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: kBgColor)),
          Positioned(
            top: -70,
            right: -50,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kBlob1,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -50,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kBlob2,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: StreamBuilder<QuerySnapshot>(
              stream: vm.outfitsStream,
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
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.05),
                                border: Border.all(
                                  color: Colors.black.withOpacity(0.08),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 46,
                              height: 46,
                              child: CircularProgressIndicator(
                                color: Colors.black.withOpacity(0.15),
                                strokeWidth: 1.5,
                              ),
                            ),
                            const SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                color: Colors.black87,
                                strokeWidth: 2.5,
                              ),
                            ),
                            const Icon(
                              CupertinoIcons.calendar,
                              color: Colors.black87,
                              size: 16,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Loading calendar…',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final Map<DateTime, List<Map<String, dynamic>>>
                    groupedOutfits = {};

                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final List<dynamic> datesDynamic =
                        data['wear_dates'] ?? [];

                    for (var dateEntry in datesDynamic) {
                      if (dateEntry is Timestamp) {
                        final normalizedDate =
                            vm.normalizeDate(dateEntry.toDate());
                        groupedOutfits[normalizedDate] ??= [];
                        data['id'] = doc.id;
                        groupedOutfits[normalizedDate]!.add(data);
                      }
                    }
                  }
                }

                List<Map<String, dynamic>> dayOutfits =
                    vm.selectedDay != null
                        ? groupedOutfits[vm.normalizeDate(vm.selectedDay!)] ??
                            []
                        : [];

                if (vm.selectedDay != null && dayOutfits.isNotEmpty) {
                  dayOutfits.sort((a, b) {
                    final dtA = vm.getWearDateTime(a, vm.selectedDay!);
                    final dtB = vm.getWearDateTime(b, vm.selectedDay!);
                    if (dtA == null && dtB == null) return 0;
                    if (dtA == null) return 1;
                    if (dtB == null) return -1;
                    return dtA.compareTo(dtB);
                  });
                }

                return Column(
                  children: [
                    CalendarHeader(
                      focusedDay: vm.focusedDay,
                      onPrevMonth: vm.prevMonth,
                      onNextMonth: vm.nextMonth,
                    ),
                    TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: vm.focusedDay,
                      selectedDayPredicate: (day) =>
                          vm.isSameDay(vm.selectedDay, day),
                      calendarFormat: CalendarFormat.month,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      eventLoader: (day) =>
                          groupedOutfits[vm.normalizeDate(day)] ?? [],
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          if (events.isNotEmpty &&
                              !vm.isSameDay(vm.selectedDay, date)) {
                            return Positioned(
                              bottom: 5,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      onDaySelected: vm.selectDay,
                      onPageChanged: vm.changePage,
                      rowHeight: 42,
                      daysOfWeekHeight: 26,
                      calendarStyle: CalendarStyle(
                        selectedDecoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black45,
                            width: 1,
                          ),
                        ),
                        todayTextStyle: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        defaultTextStyle: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        weekendTextStyle: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        outsideTextStyle: const TextStyle(
                          color: Colors.black12,
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                        ),
                        cellMargin: const EdgeInsets.all(3),
                      ),
                      headerVisible: false,
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          color: Colors.black38,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                        weekendStyle: TextStyle(
                          color: Colors.black26,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    CalendarOutfitCarousel(
                      dayOutfits: dayOutfits,
                      selectedDay: vm.selectedDay,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
