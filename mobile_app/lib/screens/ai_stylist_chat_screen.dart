import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import '../services/weather_service.dart';
import '../widgets/save_outfit_dialog.dart';
import '../services/wardrobe_state_service.dart';
import '../widgets/global_wardrobe_selector.dart';
import '../utils/outfit_sorting_utils.dart';
import 'virtual_dressing_room_screen.dart';
import '../widgets/smart_clothing_image.dart';

// Design tokens
const _kBgColor = Color(0xFFF4F3F0);
const _kPurple = Color(0xFF4F46E5);
const _kPurpleLight = Color(0xFFEEEDF8);
const _kPurpleMid = Color(0xFF8B85D4);
const _kGlass = Color(0xCCFFFFFF); // white 80%
const _kGlassBorder = Color(0xE5FFFFFF); // white 90%
const _kBlob1 = Color(0x38C026D3);
const _kBlob2 = Color(0x20A21CAF);

class ChatMessage {
  final String role;
  final String text;
  final bool isOutfit;
  final List<Map<String, dynamic>>? outfitItems;
  String? savedOutfitId;
  bool isLoggingWear;

  final int? overallScore;
  final Map<String, dynamic>? scores;

  String? feedbackStatus;
  String? userPrompt;
  String? weatherContext;

  ChatMessage({
    required this.role,
    required this.text,
    this.isOutfit = false,
    this.outfitItems,
    this.savedOutfitId,
    this.isLoggingWear = false,
    this.overallScore,
    this.scores,
    this.feedbackStatus,
    this.userPrompt,
    this.weatherContext,
  });
}

// Feedback buttons

class _FeedbackButtons extends StatefulWidget {
  final ChatMessage message;
  final List<Map<String, dynamic>> items;
  final FirebaseService firebaseService;
  final void Function(VoidCallback) setParentState;
  final BuildContext parentContext;

  const _FeedbackButtons({
    required this.message,
    required this.items,
    required this.firebaseService,
    required this.setParentState,
    required this.parentContext,
  });

  @override
  State<_FeedbackButtons> createState() => _FeedbackButtonsState();
}

class _FeedbackButtonsState extends State<_FeedbackButtons> {
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
      widget.firebaseService
          .saveOutfitFeedback(
            itemIds: ids,
            userPrompt: widget.message.userPrompt!,
            weatherContext: widget.message.weatherContext!,
            isLike: true,
          )
          .catchError((e) {
            if (mounted) {
              ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                SnackBar(content: Text('Failed to save feedback: $e')),
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
          color: _kPurpleLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kPurpleMid.withOpacity(0.25), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _kPurple),
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
      widget.firebaseService
          .saveOutfitFeedback(
            itemIds: ids,
            userPrompt: widget.message.userPrompt!,
            weatherContext: widget.message.weatherContext!,
            isLike: false,
            dislikeReason: reason,
          )
          .catchError((e) {
            if (mounted) {
              ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                SnackBar(content: Text('Failed to save feedback: $e')),
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
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);
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

// Blob painter for animated background

class _BlobPainter extends CustomPainter {
  final double t; // animation value 0..1
  _BlobPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()..color = _kBlob1;
    final p2 = Paint()..color = _kBlob2;

    // Principal indigo blob
    canvas.drawCircle(
      Offset(size.width * 0.90 + 10 * (0.5 - t), -size.height * 0.02 + 8 * t),
      size.width * 0.38,
      p1,
    );
    // Secondary violet blob
    canvas.drawCircle(
      Offset(size.width * 0.04 - 6 * t, size.height * 0.10 + 10 * (0.5 - t)),
      size.width * 0.22,
      p2,
    );
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t;
}

// Animated blob background

class _AnimatedBlobBg extends StatefulWidget {
  final Widget child;
  const _AnimatedBlobBg({required this.child});

  @override
  State<_AnimatedBlobBg> createState() => _AnimatedBlobBgState();
}

class _AnimatedBlobBgState extends State<_AnimatedBlobBg>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: _kBgColor)),
            // Blobs — CustomPaint needs a child to inherit constraints
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: CustomPaint(
                  painter: _BlobPainter(_ctrl.value),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}

// Typing indicator

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // AI badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.95),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, size: 11, color: _kPurple),
                const SizedBox(width: 4),
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        final delay = i / 3.0;
                        final val = ((_ctrl.value - delay) % 1.0);
                        final opacity = (val < 0.4)
                            ? Curves.easeOut.transform(val / 0.4)
                            : (val < 0.8)
                            ? 1.0 - Curves.easeIn.transform((val - 0.4) / 0.4)
                            : 0.3;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.5),
                          child: Opacity(
                            opacity: opacity.clamp(0.3, 1.0),
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: _kPurple,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Score badge

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
    final fillLight = color.withOpacity(0.10);
    final fillMid = color.withOpacity(0.18);

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

// Truncated text with Read more

class _TruncatedText extends StatefulWidget {
  final String text;
  const _TruncatedText({required this.text});

  @override
  State<_TruncatedText> createState() => _TruncatedTextState();
}

class _TruncatedTextState extends State<_TruncatedText> {
  bool _expanded = false;
  static const int _maxLines = 3;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.text,
            maxLines: _expanded ? null : _maxLines,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _expanded ? 'Show less' : 'Read more',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kPurple,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Main screen

class AiStylistChatScreen extends StatefulWidget {
  const AiStylistChatScreen({super.key});

  @override
  State<AiStylistChatScreen> createState() => _AiStylistChatScreenState();
}

class _AiStylistChatScreenState extends State<AiStylistChatScreen>
    with SingleTickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _emptyScrollController = ScrollController();
  bool _isTyping = false;

  late AnimationController _inputFocusCtrl;
  bool _inputFocused = false;

  final ApiService _apiService = ApiService();
  final FirebaseService _firebaseService = FirebaseService();
  final WeatherService _weatherService = WeatherService();

  @override
  void initState() {
    super.initState();
    _inputFocusCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _inputFocusCtrl.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _emptyScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Color _getScoreColor(num score) {
    if (score >= 80) return const Color(0xFF22C55E);
    if (score >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
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
                                    backgroundColor: Colors.black.withOpacity(
                                      0.07,
                                    ),
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
                                        backgroundColor: Colors.black
                                            .withOpacity(0.06),
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

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(role: 'user', text: text));
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    String currentWeatherStr = "Unknown Weather";
    String hourlyForecastStr = "Unknown Forecast";
    final weather = _weatherService.cachedWeather;
    if (weather != null) {
      currentWeatherStr =
          'Currently ${weather.temperature}°C and ${weather.condition} in ${weather.cityName}';
      final buffer = StringBuffer();
      for (var item in weather.forecast) {
        buffer.write(
          '${item.timeLabel}: ${item.temperature}°C (${item.condition}), ',
        );
      }
      hourlyForecastStr = buffer.toString();
    }

    try {
      final response = await _apiService.generateOutfit(
        userPrompt: text,
        currentWeather: currentWeatherStr,
        hourlyForecast: hourlyForecastStr,
        wardrobeId: wardrobeStateService.activeWardrobeId,
      );

      final explanation = response['explanation'] as String;
      final selectedIds = List<String>.from(
        response['selected_item_ids'] ?? [],
      );
      final overallScore = response['overall_score'] as int?;
      final scores = response['scores'] as Map<String, dynamic>?;

      List<Map<String, dynamic>> outfitItems = [];
      if (selectedIds.isNotEmpty) {
        outfitItems = await _firebaseService.getItemsByIds(selectedIds);
      }

      if (mounted) {
        setState(() {
          _isTyping = false;
          if (outfitItems.isNotEmpty) {
            _messages.add(
              ChatMessage(
                role: 'ai',
                text: explanation,
                isOutfit: true,
                outfitItems: outfitItems,
                overallScore: overallScore,
                scores: scores,
                userPrompt: text,
                weatherContext:
                    '$currentWeatherStr | Forecast: $hourlyForecastStr',
              ),
            );
          } else {
            _messages.add(ChatMessage(role: 'ai', text: explanation));
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            ChatMessage(
              role: 'ai',
              text:
                  "Sorry, I'm having trouble connecting to my fashion brain right now. Please try again later.",
            ),
          );
        });
        _scrollToBottom();
      }
    }
  }

  // Empty state

  Widget _buildEmptyState() {
    final suggestions = [
      "Office",
      "Workout",
      "Casual Coffee",
      "Night Out",
      "Date Night",
      "City Walk",
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final topPad = MediaQuery.of(context).padding.top + kToolbarHeight + 16;

        return Stack(
          children: [
            Positioned.fill(
              child: _AnimatedBlobBg(child: const SizedBox.expand()),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Transform.translate(
                offset: Offset(0, 28 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              ),
              child: CustomScrollView(
                controller: _emptyScrollController,
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(24, topPad, 24, 32),
                    sliver: SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hero icon
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.80),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: _kGlassBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: _kPurple.withOpacity(0.20),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: _kPurple,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Your personal\nstylist is ready.",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              height: 1.15,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Tell me where you're going and I'll\nbuild an outfit from your wardrobe.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              height: 1.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            "TRY ASKING",
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 3.0,
                              fontWeight: FontWeight.w600,
                              color: Colors.black.withOpacity(0.35),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: suggestions.map((s) {
                              return GestureDetector(
                                onTap: () => _sendMessage(s),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.75),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.90),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _kPurple.withOpacity(0.07),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        s,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      const Icon(
                                        CupertinoIcons.arrow_right,
                                        size: 11,
                                        color: _kPurple,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 28),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: _kPurpleLight,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.cloud_sun,
                                        size: 15,
                                        color: _kPurple,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        "I consider the weather, your style & the occasion.",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Message bubble

  Widget _buildMessage(ChatMessage message) {
    final isUser = message.role == 'user';

    if (message.isOutfit) {
      final items = message.outfitItems ?? [];
      OutfitSortingUtils.sortOutfitItems(items);
      return _buildOutfitCard(message, items);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Transform.translate(
        offset: Offset(isUser ? 12 * (1 - v) : -12 * (1 - v), 0),
        child: Opacity(opacity: v, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser
                ? const Radius.circular(20)
                : const Radius.circular(5),
            bottomRight: isUser
                ? const Radius.circular(5)
                : const Radius.circular(20),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: isUser ? 0 : 8,
              sigmaY: isUser ? 0 : 8,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: const BoxConstraints(maxWidth: 270),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [Color(0xFF5B52F0), Color(0xFF3730C8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser ? null : Colors.white.withOpacity(0.82),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(5),
                  bottomRight: isUser
                      ? const Radius.circular(5)
                      : const Radius.circular(20),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: Colors.white.withOpacity(0.9),
                        width: 1,
                      ),
                boxShadow: isUser
                    ? [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: isUser ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Outfit card

  Widget _buildOutfitCard(
    ChatMessage message,
    List<Map<String, dynamic>> items,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.82),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _kGlassBorder, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: _kPurple.withOpacity(0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
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
                            color: _kPurpleLight,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: _kPurple,
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
                                ? () => _showScoreDetails(
                                    context,
                                    message.scores!,
                                  )
                                : null,
                            child: _ScoreBadge(
                              score: message.overallScore!,
                              hasDetails: message.scores != null,
                              getColor: _getScoreColor,
                            ),
                          ),
                        const SizedBox(width: 8),
                        _FeedbackButtons(
                          message: message,
                          items: items,
                          firebaseService: _firebaseService,
                          setParentState: setState,
                          parentContext: context,
                        ),
                      ],
                    ),
                  ),

                  // Explanation — truncated with Read more
                  if (message.text.isNotEmpty)
                    _TruncatedText(text: message.text),

                  // Items scroll
                  GestureDetector(
                    onTap: () => _showVerticalPreview(context, items),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                      height: 190,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A).withOpacity(0.04),
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
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.07,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
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
                                        setState(
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VirtualDressingRoomScreen(
                                        initialItemIds: ids,
                                      ),
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
                                        setState(
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
                  colors: [Color(0xFF5B52F0), Color(0xFF3730C8)],
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
                    color: _kPurple.withOpacity(0.30),
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
                  color: isPrimary ? Colors.white : _kPurple,
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

  // Input bar

  Widget _buildInputBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.85), width: 1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _inputFocused
                        ? Colors.white.withOpacity(0.9)
                        : Colors.white.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: _inputFocused
                          ? _kPurpleMid.withOpacity(0.5)
                          : Colors.white.withOpacity(0.85),
                      width: 1,
                    ),
                  ),
                  child: Focus(
                    onFocusChange: (focused) =>
                        setState(() => _inputFocused = focused),
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: "Tell me about your plans...",
                        hintStyle: TextStyle(
                          color: Colors.black.withOpacity(0.35),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _sendMessage(_controller.text),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.20),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.arrow_up,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Full build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _kBgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "AI Stylist",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: Colors.transparent),
          ),
        ),
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [GlobalWardrobeSelector(isActionItem: true)],
      ),
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -70,
            right: -50,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kBlob1,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: -40,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kBlob2,
                  ),
                ),
              ),
            ),
          ),

          Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(
                          top:
                              MediaQuery.of(context).padding.top +
                              kToolbarHeight +
                              16,
                          bottom: 16,
                        ),
                        itemCount: _messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            return const _TypingIndicator();
                          }
                          return _buildMessage(_messages[index]);
                        },
                      ),
              ),
              SafeArea(top: false, child: _buildInputBar()),
            ],
          ),
        ],
      ),
    );
  }

  // Helpers
  int _getItemFlex(Map<String, dynamic> item) {
    final info = item['metadata']?['basic_info'] ?? item['basic_info'] ?? {};
    String cat = '';
    String sub = '';
    if (item.containsKey('category'))
      cat = item['category'].toString().toLowerCase();
    else if (info is Map && info.containsKey('category'))
      cat = info['category'].toString().toLowerCase();
    if (item.containsKey('sub_category'))
      sub = item['sub_category'].toString().toLowerCase();
    else if (info is Map && info.containsKey('sub_category'))
      sub = info['sub_category'].toString().toLowerCase();

    if (cat.contains('head') ||
        sub.contains('hat') ||
        sub.contains('cap') ||
        sub.contains('beanie'))
      return 1;
    if (cat.contains('outerwear') ||
        sub.contains('jacket') ||
        sub.contains('coat') ||
        sub.contains('blazer'))
      return 3;
    if (cat.contains('midwear') ||
        sub.contains('sweater') ||
        sub.contains('hoodie') ||
        sub.contains('cardigan') ||
        sub.contains('sweatshirt'))
      return 3;
    if (cat.contains('bottom') ||
        cat.contains('pant') ||
        sub.contains('jean') ||
        sub.contains('skirt') ||
        sub.contains('short') ||
        sub.contains('legging'))
      return 4;
    if (cat.contains('shoe') ||
        cat.contains('footwear') ||
        sub.contains('sneaker') ||
        sub.contains('boot') ||
        sub.contains('sandal'))
      return 2;
    return 3;
  }

  void _showVerticalPreview(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 48,
            vertical: 32,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: _kGlassBorder),
                ),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 40, 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _kPurpleLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: _kPurple,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                "Outfit preview",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: items.asMap().entries.expand((entry) {
                                final widgets = <Widget>[
                                  Expanded(
                                    flex: _getItemFlex(entry.value),
                                    child: _buildFullOutfitPreviewImage(
                                      entry.value,
                                    ),
                                  ),
                                ];
                                if (entry.key < items.length - 1) {
                                  widgets.add(const SizedBox(height: 4));
                                }
                                return widgets;
                              }).toList(),
                            ),
                          ),
                        ),
                        Container(
                          width: 80,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20, top: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(dialogContext),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.06),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.black54,
                            size: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFullOutfitPreviewImage(Map<String, dynamic> item) {
    final imageBase64 = item['image_base64'] as String?;
    final imageUrl = item['imageUrl'] as String?;
    final resolvedUrl = (imageBase64 != null && imageBase64.isNotEmpty)
        ? imageBase64
        : imageUrl;
    return SmartClothingImage(
      imageUrl: resolvedUrl,
      fit: BoxFit.contain,
      width: double.infinity,
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
