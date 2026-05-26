import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

/// Greeting header: date chip, "Hello / Name" and tagline.
class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(
          builder: (context) {
            final now = DateTime.now();
            const months = [
              'JANUARY',
              'FEBRUARY',
              'MARCH',
              'APRIL',
              'MAY',
              'JUNE',
              'JULY',
              'AUGUST',
              'SEPTEMBER',
              'OCTOBER',
              'NOVEMBER',
              'DECEMBER',
            ];
            const weekdays = [
              'MONDAY',
              'TUESDAY',
              'WEDNESDAY',
              'THURSDAY',
              'FRIDAY',
              'SATURDAY',
              'SUNDAY',
            ];
            final dateStr =
                '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
            return Text(
              dateStr,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 3.0,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.35),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(AuthService().currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            String name = '';
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              if (data != null) name = data['name'] ?? '';
            } else if (AuthService().currentUser?.displayName != null) {
              name = AuthService().currentUser!.displayName!;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Hello,",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    color: Colors.black54,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  name.isNotEmpty ? name : "There",
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    height: 1.05,
                    letterSpacing: -1.0,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 6),
        const Text(
          "Discover today's aesthetic.",
          style: TextStyle(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: Colors.black45,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
