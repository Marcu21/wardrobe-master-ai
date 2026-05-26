import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/navigation/app_routes.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'widgets/my_trips_empty_state.dart';
import 'widgets/trip_card.dart';

const _kBlob1 = Color(0x3840C4FF);
const _kBlob2 = Color(0x1E1565C0);

class MyTripsScreen extends StatelessWidget {
  const MyTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Please login to view trips.")),
      );
    }

    return Scaffold(
      backgroundColor: kBgColor,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_my_trips_plan',
        onPressed: () =>
            Navigator.pushNamed(context, AppRoutes.tripSetup),
        icon: const Icon(Icons.add),
        label: const Text("Plan New Trip"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: kBgColor)),
          Positioned(
            top: -80,
            right: -60,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kBlob1,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -60,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  width: 190,
                  height: 190,
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
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 4,
                    left: 4,
                    right: 4,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          CupertinoIcons.back,
                          color: Colors.black87,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'My Trips',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('trips')
                        .where('user_id', isEqualTo: currentUser.uid)
                        .orderBy('created_at', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text("Error: ${snapshot.error}"),
                        );
                      }
                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const MyTripsEmptyState();
                      }

                      final docs = snapshot.data!.docs;

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data =
                              doc.data() as Map<String, dynamic>;
                          return TripCard(
                            key: ValueKey(doc.id),
                            data: data,
                            docId: doc.id,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
