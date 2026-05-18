import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'outfit_detail/outfit_detail_screen.dart';
import '../widgets/smart_outfit_card.dart';
import 'package:mobile_app/theme/app_colors.dart';

const _kBlob1 = Color(0x384F46E5);
const _kBlob2 = Color(0x206352D2);

class LookbookScreen extends StatelessWidget {
  const LookbookScreen({super.key});

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp.toDate();
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
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
        stream: FirebaseFirestore.instance
            .collection('outfits')
            .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
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
                        Icons.style_outlined,
                        color: Colors.black87,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Loading outfits…',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Getting your looks',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black45,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.xmark_circle,
                        color: Colors.redAccent,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black45,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, v, child) => Opacity(
                  opacity: v,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - v)),
                    child: child,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.style_outlined,
                        size: 44,
                        color: Colors.black38,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No saved outfits yet.',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Generate or create your first look',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black45,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverAppBar(
                pinned: false,
                floating: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                title: Text(
                  'My Outfits',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.35,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String name = data['name'] ?? 'Untitled';
              final double rating = (data['rating'] ?? 0.0).toDouble();
              final bool isAiGenerated = data['is_ai_generated'] ?? false;
              final Timestamp? createdAt = data['created_at'] as Timestamp?;

              return SmartOutfitCard(
                key: ValueKey(doc.id),
                outfitData: data,
                outfitId: doc.id,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        OutfitDetailScreen(outfitData: data, outfitId: doc.id),
                  ),
                ),
                badge: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isAiGenerated
                        ? const Color(0xFF6D28D9).withOpacity(0.82)
                        : const Color(0xFF2563EB).withOpacity(0.82),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isAiGenerated
                                    ? const Color(0xFF6D28D9)
                                    : const Color(0xFF2563EB))
                                .withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAiGenerated
                            ? Icons.auto_awesome
                            : CupertinoIcons.person,
                        size: 10,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAiGenerated ? 'AI' : 'You',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                footer: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
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
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _formatDate(createdAt),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black.withOpacity(0.35),
                                  fontWeight: FontWeight.w500,
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
              );
                    },
                    childCount: snapshot.data!.docs.length,
                  ),
                ),
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
