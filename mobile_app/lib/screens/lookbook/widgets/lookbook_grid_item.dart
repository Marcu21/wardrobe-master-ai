import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/navigation/app_routes.dart';
import 'package:mobile_app/widgets/smart_outfit_card.dart';

String _formatDate(Timestamp? timestamp) {
  if (timestamp == null) return '';
  final dt = timestamp.toDate();
  return '${dt.day}/${dt.month}/${dt.year}';
}

class LookbookGridItem extends StatelessWidget {
  final Map<String, dynamic> outfitData;
  final String outfitId;

  const LookbookGridItem({
    super.key,
    required this.outfitData,
    required this.outfitId,
  });

  @override
  Widget build(BuildContext context) {
    final String name = outfitData['name'] ?? 'Untitled';
    final double rating = (outfitData['rating'] ?? 0.0).toDouble();
    final bool isAiGenerated = outfitData['is_ai_generated'] ?? false;
    final Timestamp? createdAt = outfitData['created_at'] as Timestamp?;

    return SmartOutfitCard(
      key: ValueKey(outfitId),
      outfitData: outfitData,
      outfitId: outfitId,
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.outfitDetail,
        arguments: OutfitDetailArgs(outfitData: outfitData, outfitId: outfitId),
      ),
      badge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isAiGenerated
              ? const Color(0xFF6D28D9).withOpacity(0.82)
              : const Color(0xFF2563EB).withOpacity(0.82),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: (isAiGenerated
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
              isAiGenerated ? Icons.auto_awesome : CupertinoIcons.person,
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
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              border: Border(
                top: BorderSide(color: Colors.black.withOpacity(0.06)),
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
  }
}
