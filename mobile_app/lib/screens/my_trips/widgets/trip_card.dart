import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/services/firebase_service.dart';
import 'package:mobile_app/screens/trip_view_screen.dart';

class TripCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const TripCard({super.key, required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Unnamed Trip';
    final destination = data['destination'] ?? '';
    final vibe = data['vibe'] ?? 'versatile';
    final itemIds = List<String>.from(data['item_ids'] ?? []);
    final outfits = data['outfits'] as List? ?? [];
    final createdAt = data['created_at'] as Timestamp?;
    final startDate = data['start_date'] as Timestamp?;
    final endDate = data['end_date'] as Timestamp?;

    String periodString = '';
    if (startDate != null && endDate != null) {
      final start = startDate.toDate();
      final end = endDate.toDate();
      if (start.year != end.year) {
        periodString =
            "${DateFormat('MMM d, yyyy').format(start)} - ${DateFormat('MMM d, yyyy').format(end)}";
      } else if (start.month != end.month) {
        periodString =
            "${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d, yyyy').format(end)}";
      } else {
        periodString =
            "${DateFormat('MMM d').format(start)} - ${DateFormat('d, yyyy').format(end)}";
      }
    } else if (createdAt != null) {
      periodString = DateFormat('MMM d, yyyy').format(createdAt.toDate());
    }

    int calculatedDays = 3;
    if (startDate != null && endDate != null) {
      calculatedDays =
          endDate.toDate().difference(startDate.toDate()).inDays + 1;
      if (calculatedDays < 1) calculatedDays = 1;
    } else if (outfits.isNotEmpty) {
      calculatedDays = outfits.length;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TripViewScreen(
                tripId: docId,
                destination: destination,
                days: calculatedDays,
                vibe: vibe,
                initialTripData: data,
              ),
            ),
          );
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                top: 16,
                bottom: 16,
                right: 16,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.flight_takeoff,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 32.0),
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              destination,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            vibe,
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              periodString,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              "${itemIds.length} items • ${outfits.length} outfits",
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                color: Color(0xFF757575),
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
            const Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Icon(Icons.chevron_right, color: Colors.grey),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                tooltip: "Delete Trip",
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Delete Trip"),
                      content: const Text(
                        "Are you sure you want to delete this trip? This action cannot be undone.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Delete"),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      await FirebaseService().deleteTrip(docId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Trip deleted successfully."),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Failed to delete trip: $e"),
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
