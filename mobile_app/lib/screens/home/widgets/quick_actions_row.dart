import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_colors.dart';
import '../../../services/auth_service.dart';
import 'home_card.dart';

/// Vertical stack of the three secondary navigation cards:
/// Dressing Room, Should I Buy This?, and Smart Packing.
class QuickActionsColumn extends StatelessWidget {
  final VoidCallback onDressingRoomTap;
  final VoidCallback onShoppingTap;
  final VoidCallback onSmartPackingTap;

  const QuickActionsColumn({
    super.key,
    required this.onDressingRoomTap,
    required this.onShoppingTap,
    required this.onSmartPackingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HomeCard(
          shadowColor: const Color(0xFF673AB7),
          onTap: onDressingRoomTap,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF673AB7).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.checkroom,
                  color: const Color(0xFF673AB7),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Dressing Room",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      "Mix & match pieces from your wardrobe",
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: Colors.black.withOpacity(0.25),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        HomeCard(
          shadowColor: const Color(0xFF009688),
          onTap: onShoppingTap,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF009688).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.doc_text_search,
                  color: Color(0xFF009688),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Should I Buy This?",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      "Scan any item to see if it fits your style",
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: Colors.black.withOpacity(0.25),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SmartPackingCard(onTap: onSmartPackingTap),
      ],
    );
  }
}

class _SmartPackingCard extends StatelessWidget {
  final VoidCallback onTap;
  const _SmartPackingCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: uid != null
          ? FirebaseFirestore.instance
                .collection('trips')
                .where('user_id', isEqualTo: uid)
                .snapshots()
          : const Stream.empty(),
      builder: (context, snapshot) {
        return HomeCard(
          shadowColor: kBlueAccent,
          onTap: onTap,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kBlueAccent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.luggage_rounded,
                  color: kBlueAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Smart Packing",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      "Build the perfect wardrobe for any trip",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: Colors.black.withOpacity(0.25),
              ),
            ],
          ),
        );
      },
    );
  }
}


