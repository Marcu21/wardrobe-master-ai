import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/services/outfit_repository.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'package:mobile_app/widgets/custom_snackbar.dart';
import '../chat_message.dart';

class FeedbackButtons extends StatefulWidget {
  final ChatMessage message;
  final List<Map<String, dynamic>> items;
  final OutfitRepository outfitRepository;
  final void Function(VoidCallback) setParentState;
  final BuildContext parentContext;

  const FeedbackButtons({
    super.key,
    required this.message,
    required this.items,
    required this.outfitRepository,
    required this.setParentState,
    required this.parentContext,
  });

  @override
  State<FeedbackButtons> createState() => _FeedbackButtonsState();
}

class _FeedbackButtonsState extends State<FeedbackButtons> {
  double _likeScale = 1.0;
  double _dislikeScale = 1.0;

  void _animatePop(bool isLike) async {
    setState(() => isLike ? _likeScale = 1.35 : _dislikeScale = 1.35);
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted)
      setState(() => isLike ? _likeScale = 1.0 : _dislikeScale = 1.0);
  }

  void _handleLike() {
    if (widget.message.feedbackStatus != null) return;
    final ids = widget.items.map((e) => e['id'].toString()).toList();
    setState(() {
      widget.message.feedbackStatus = 'liked';
      _likeScale = 1.3;
    });
    widget.setParentState(() {});
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _likeScale = 1.0);
    });
    if (ids.isNotEmpty &&
        widget.message.userPrompt != null &&
        widget.message.weatherContext != null) {
      widget.outfitRepository
          .saveOutfitFeedback(
            itemIds: ids,
            userPrompt: widget.message.userPrompt!,
            weatherContext: widget.message.weatherContext!,
            isLike: true,
          )
          .catchError((e) {
            if (mounted) {
              CustomSnackBar.showError(
                widget.parentContext,
                'Failed to save feedback: $e',
              );
            }
          });
    }
  }

  void _handleDislikeTap() {
    if (widget.message.feedbackStatus != null) return;
    _animatePop(false);
    showModalBottomSheet(
      context: widget.parentContext,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.9),
                  width: 1,
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "What didn't you like?",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDislikeOption(
                        ctx,
                        CupertinoIcons.pencil_outline,
                        "Style mismatch",
                        "Style mismatch",
                      ),
                      _buildDislikeOption(
                        ctx,
                        CupertinoIcons.cloud_sun,
                        "Weather mismatch",
                        "Weather mismatch",
                      ),
                      _buildDislikeOption(
                        ctx,
                        CupertinoIcons.location,
                        "Context mismatch",
                        "Context mismatch",
                      ),
                      const SizedBox(height: 8),
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

  Widget _buildDislikeOption(
    BuildContext ctx,
    IconData icon,
    String label,
    String reason,
  ) {
    return GestureDetector(
      onTap: () => _onDislikeSelected(ctx, reason),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: kPrimaryLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kPrimaryMid.withOpacity(0.25), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: kPrimary),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Icon(CupertinoIcons.chevron_right, size: 14, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  void _onDislikeSelected(BuildContext ctx, String reason) {
    Navigator.pop(ctx);
    final ids = widget.items.map((e) => e['id'].toString()).toList();
    setState(() {
      widget.message.feedbackStatus = 'disliked';
      _dislikeScale = 1.3;
    });
    widget.setParentState(() {});
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _dislikeScale = 1.0);
    });
    if (ids.isNotEmpty &&
        widget.message.userPrompt != null &&
        widget.message.weatherContext != null) {
      widget.outfitRepository
          .saveOutfitFeedback(
            itemIds: ids,
            userPrompt: widget.message.userPrompt!,
            weatherContext: widget.message.weatherContext!,
            isLike: false,
            dislikeReason: reason,
          )
          .catchError((e) {
            if (mounted) {
              CustomSnackBar.showError(
                widget.parentContext,
                'Failed to save feedback: $e',
              );
            }
          });
    }
  }

  Widget _buildBtn({
    required bool isLike,
    required double scale,
    required VoidCallback onTap,
  }) {
    final status = widget.message.feedbackStatus;
    final isSelected = isLike ? status == 'liked' : status == 'disliked';
    final isDisabled = status != null && !isSelected;
    final activeColor = isLike
        ? kSuccess
        : kError;
    final icon = isLike
        ? (isSelected ? Icons.thumb_up_rounded : Icons.thumb_up_outlined)
        : (isSelected ? Icons.thumb_down_rounded : Icons.thumb_down_outlined);

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withOpacity(0.12)
                : Colors.white.withOpacity(0.70),
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? activeColor.withOpacity(0.4)
                  : Colors.black.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                icon,
                key: ValueKey(isSelected),
                color: isSelected
                    ? activeColor
                    : isDisabled
                    ? Colors.black.withOpacity(0.18)
                    : Colors.black.withOpacity(0.45),
                size: 17,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBtn(isLike: true, scale: _likeScale, onTap: _handleLike),
        const SizedBox(width: 6),
        _buildBtn(
          isLike: false,
          scale: _dislikeScale,
          onTap: _handleDislikeTap,
        ),
      ],
    );
  }
}
