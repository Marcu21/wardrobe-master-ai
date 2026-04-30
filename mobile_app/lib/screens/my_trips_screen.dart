import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'package:intl/intl.dart';
import 'trip_view_screen.dart';
import 'packing_setup_screen.dart';

class MyTripsScreen extends StatelessWidget {
  const MyTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseService().currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Please login to view trips.")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("My Trips", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      // Unique heroTag prevents this FAB from Hero-animating into any other screen's FAB
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_my_trips_plan',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PackingSetupScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Plan New Trip"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('trips')
            .where('user_id', isEqualTo: currentUser.uid)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(context);
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

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
                  periodString = "${DateFormat('MMM d, yyyy').format(start)} - ${DateFormat('MMM d, yyyy').format(end)}";
                } else if (start.month != end.month) {
                  periodString = "${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d, yyyy').format(end)}";
                } else {
                  periodString = "${DateFormat('MMM d').format(start)} - ${DateFormat('d, yyyy').format(end)}";
                }
              } else if (createdAt != null) {
                periodString = DateFormat('MMM d, yyyy').format(createdAt.toDate());
              }

              int calculatedDays = 3;
              if (startDate != null && endDate != null) {
                calculatedDays = endDate.toDate().difference(startDate.toDate()).inDays + 1;
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
                          tripId: doc.id,
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
                        padding: const EdgeInsets.only(left: 20, top: 16, bottom: 16, right: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                              child: const Icon(Icons.flight_takeoff, color: Colors.blueAccent),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 32.0),
                                    child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey),
                                      const SizedBox(width: 3),
                                      Text(destination, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      vibe,
                                      style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        periodString,
                                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                                      ),
                                      Text(
                                        "${itemIds.length} items • ${outfits.length} outfits",
                                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Color(0xFF757575)),
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
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          tooltip: "Delete Trip",
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Delete Trip"),
                                content: const Text("Are you sure you want to delete this trip? This action cannot be undone."),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text("Cancel"),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text("Delete"),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              try {
                                await FirebaseService().deleteTrip(doc.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Trip deleted successfully.")),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Failed to delete trip: $e")),
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
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration circle
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.flight_takeoff,
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              "Ready for your\nnext adventure?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Let AI build the perfect capsule wardrobe for any destination, any vibe.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.55,
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PackingSetupScreen()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text(
                  "Start Planning",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFF1565C0).withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
