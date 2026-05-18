import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/firebase_service.dart';
import 'package:mobile_app/services/weather_service.dart';
import 'package:mobile_app/services/wardrobe_state_service.dart';
import 'package:mobile_app/widgets/global_wardrobe_selector.dart';
import 'package:mobile_app/widgets/glassmorphism_card.dart';
import 'package:mobile_app/utils/outfit_sorting_utils.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'chat_message.dart';
import 'widgets/typing_indicator.dart';
import 'widgets/outfit_message_card.dart';

// Per-screen blob colours (fuchsia palette)
const _kBlob1 = Color(0x38C026D3);
const _kBlob2 = Color(0x20A21CAF);

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
            Positioned.fill(child: ColoredBox(color: kBgColor)),
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
                              border: Border.all(color: kGlassBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: kPrimary.withOpacity(0.20),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: kPrimary,
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
                                        color: kPrimary.withOpacity(0.07),
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
                                        color: kPrimary,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 28),
                          GlassmorphismCard(
                            sigma: 12,
                            colorOpacity: 0.55,
                            borderRadius: BorderRadius.circular(18),
                            borderColor: Colors.white.withOpacity(0.85),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: kPrimaryLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.cloud_sun,
                                    size: 15,
                                    color: kPrimary,
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
      return OutfitMessageCard(
        message: message,
        items: items,
        firebaseService: _firebaseService,
        setParentState: setState,
      );
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
                          color: kPrimary.withOpacity(0.25),
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
                          ? kPrimaryMid.withOpacity(0.5)
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
      backgroundColor: kBgColor,
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
                            return const TypingIndicator();
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
}
