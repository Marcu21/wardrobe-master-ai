import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'package:mobile_app/navigation/app_routes.dart';
import 'package:mobile_app/services/outfit_repository.dart';
import 'package:mobile_app/widgets/glassmorphism_card.dart';
import 'package:mobile_app/widgets/save_outfit_dialog.dart';
import 'package:mobile_app/widgets/smart_clothing_image.dart';
import '../chat_message.dart';
import '../dialogs/vertical_preview_dialog.dart';
import 'feedback_buttons.dart';
import 'truncated_text.dart';

Color _getScoreColor(num score) {
  if (score >= 80) return kSuccess;
  if (score >= 60) return kWarning;
  return kError;
}

void _showScoreDetails(BuildContext context, Map<String, dynamic> scores) {
  final entries = scores.entries.toList();
  final overall =
      (entries.fold<num>(0, (s, e) => s + (e.value as num)) / entries.length)
          .round();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.96),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(color: Colors.white.withOpacity(0.9)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Hero row: arc + title
                    Row(
                      children: [
                        // Animated arc
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: overall / 100),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => SizedBox(
                            width: 56,
                            height: 56,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: v,
                                  strokeWidth: 5,
                                  backgroundColor:
                                      Colors.black.withOpacity(0.07),
                                  valueColor: AlwaysStoppedAnimation(
                                    _getScoreColor(overall),
                                  ),
                                  strokeCap: StrokeCap.round,
                                ),
                                Text(
                                  '$overall',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: _getScoreColor(overall),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Outfit score",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              overall >= 80
                                  ? "Great match for you"
                                  : overall >= 60
                                  ? "Decent combination"
                                  : "Could be improved",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black45,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Score rows with animated bars
                    ...entries.asMap().entries.map((e) {
                      final idx = e.key;
                      final key = e.value.key;
                      final num value = e.value.value as num;
                      String title = '';
                      IconData icon = CupertinoIcons.star;
                      if (key == 'style_match') {
                        title = 'Style';
                        icon = CupertinoIcons.pencil_outline;
                      } else if (key == 'weather_match') {
                        title = 'Weather';
                        icon = CupertinoIcons.cloud_sun;
                      } else if (key == 'context_match') {
                        title = 'Context';
                        icon = CupertinoIcons.location;
                      } else if (key == 'color_harmony') {
                        title = 'Colors';
                        icon = CupertinoIcons.paintbrush;
                      } else {
                        title = key
                            .split('_')
                            .map(
                              (w) => w.isNotEmpty
                                  ? '${w[0].toUpperCase()}${w.substring(1)}'
                                  : '',
                            )
                            .join(' ');
                      }

                      final scoreColor = _getScoreColor(value);
                      final pct = value.toInt();

                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 400 + idx * 100),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, child) => Opacity(
                          opacity: v,
                          child: Transform.translate(
                            offset: Offset(0, 12 * (1 - v)),
                            child: child,
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  icon,
                                  size: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: value / 100),
                                  duration: Duration(
                                    milliseconds: 700 + idx * 120,
                                  ),
                                  curve: Curves.easeOutCubic,
                                  builder: (_, v, __) => ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: v,
                                      backgroundColor:
                                          Colors.black.withOpacity(0.06),
                                      valueColor: AlwaysStoppedAnimation(
                                        scoreColor,
                                      ),
                                      minHeight: 5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '$pct%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: scoreColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _ScoreBadge extends StatelessWidget {
  final int score;
  final bool hasDetails;
  final Color Function(num) getColor;

  const _ScoreBadge({
    required this.score,
    required this.hasDetails,
    required this.getColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = getColor(score);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.07), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            '$score%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              letterSpacing: -0.2,
            ),
          ),
          if (hasDetails) ...[
            const SizedBox(width: 3),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 9,
              color: Colors.black38,
            ),
          ],
        ],
      ),
    );
  }
}

class OutfitMessageCard extends StatefulWidget {
  final ChatMessage message;
  final List<Map<String, dynamic>> items;
  final OutfitRepository outfitRepository;
  final void Function(VoidCallback) setParentState;

  const OutfitMessageCard({
    super.key,
    required this.message,
    required this.items,
    required this.outfitRepository,
    required this.setParentState,
  });

  @override
  State<OutfitMessageCard> createState() => _OutfitMessageCardState();
}

class _OutfitMessageCardState extends State<OutfitMessageCard> {
  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final items = widget.items;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: GlassmorphismCard(
          sigma: 16,
          colorOpacity: 0.82,
          borderRadius: BorderRadius.circular(24),
          borderColor: kGlassBorder,
          width: double.infinity,
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(0.10),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 0),
                child: Row(
                  children: [
                    // Icon + title
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: kPrimaryLight,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: kPrimary,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Today's look",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    // Score + feedback
                    if (message.overallScore != null)
                      GestureDetector(
                        onTap: message.scores != null
                            ? () => _showScoreDetails(context, message.scores!)
                            : null,
                        child: _ScoreBadge(
                          score: message.overallScore!,
                          hasDetails: message.scores != null,
                          getColor: _getScoreColor,
                        ),
                      ),
                    const SizedBox(width: 8),
                    FeedbackButtons(
                      message: message,
                      items: items,
                      outfitRepository: widget.outfitRepository,
                      setParentState: widget.setParentState,
                      parentContext: context,
                    ),
                  ],
                ),
              ),

              // Explanation — truncated with Read more
              if (message.text.isNotEmpty) TruncatedText(text: message.text),

              // Items scroll
              GestureDetector(
                onTap: () => showVerticalPreviewDialog(context, items),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  height: 190,
                  decoration: BoxDecoration(
                    color: kTextDark.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.black.withOpacity(0.06),
                    ),
                  ),
                  child: items.isEmpty
                      ? const Center(
                          child: Text(
                            "No items found",
                            style: TextStyle(
                              color: Colors.black38,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(10),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final info =
                                item['metadata']?['basic_info'] ??
                                item['basic_info'] ??
                                {};
                            final subCat = (info['sub_category'] ?? '')
                                .toString();
                            return Column(
                              children: [
                                Expanded(
                                  child: Container(
                                    width: 110,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              Colors.black.withOpacity(0.07),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: _buildChatImageThumbnail(item),
                                    ),
                                  ),
                                ),
                                if (subCat.isNotEmpty) ...[
                                  const SizedBox(height: 5),
                                  Text(
                                    subCat,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.black45,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                ),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  children: [
                    // Wear — full width primary
                    _buildActionBtn(
                      icon: CupertinoIcons.checkmark_circle,
                      label: "Wear today",
                      isPrimary: true,
                      isLoading: message.isLoggingWear,
                      onTap: message.isLoggingWear
                          ? null
                          : () {
                              final ids = items
                                  .map((e) => e['id'].toString())
                                  .toList();
                              if (ids.isNotEmpty) {
                                SaveOutfitDialog.show(
                                  context,
                                  itemIds: ids,
                                  isAiGenerated: true,
                                  isWearAction: true,
                                  existingOutfitId: message.savedOutfitId,
                                ).then((outfitId) {
                                  if (outfitId != null && mounted) {
                                    widget.setParentState(
                                      () =>
                                          message.savedOutfitId = outfitId,
                                    );
                                  }
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 8),
                    // Remix + Save — half width secondary
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionBtn(
                            icon: CupertinoIcons.shuffle,
                            label: "Remix",
                            isPrimary: false,
                            onTap: () {
                              final ids = items
                                  .map((e) => e['id'].toString())
                                  .toList();
                              Navigator.pushNamed(
                                context,
                                AppRoutes.dressingRoom,
                                arguments: VirtualDressingRoomArgs(
                                  initialItemIds: ids,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionBtn(
                            icon: CupertinoIcons.heart,
                            label: "Save",
                            isPrimary: false,
                            onTap: () {
                              final ids = items
                                  .map((e) => e['id'].toString())
                                  .toList();
                              if (ids.isNotEmpty) {
                                SaveOutfitDialog.show(
                                  context,
                                  itemIds: ids,
                                  isAiGenerated: true,
                                ).then((outfitId) {
                                  if (outfitId != null && mounted) {
                                    widget.setParentState(
                                      () =>
                                          message.savedOutfitId = outfitId,
                                    );
                                  }
                                });
                              }
                            },
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
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required bool isPrimary,
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: isPrimary ? 14 : 11),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [kCtaStart, kCtaEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isPrimary ? null : Colors.white.withOpacity(0.80),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPrimary
                ? Colors.transparent
                : Colors.black.withOpacity(0.08),
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.30),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: isPrimary ? Colors.white : kPrimary,
                ),
              )
            else
              Icon(
                icon,
                size: isPrimary ? 16 : 14,
                color: isPrimary ? Colors.white : Colors.black87,
              ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: isPrimary ? 15 : 13,
                fontWeight: FontWeight.w600,
                color: isPrimary ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatImageThumbnail(Map<String, dynamic> item) {
    final imageBase64 = item['image_base64'] as String?;
    final imageUrl = item['imageUrl'] as String?;
    final resolvedUrl = (imageBase64 != null && imageBase64.isNotEmpty)
        ? imageBase64
        : imageUrl;
    return SmartClothingImage(imageUrl: resolvedUrl, fit: BoxFit.contain);
  }
}
