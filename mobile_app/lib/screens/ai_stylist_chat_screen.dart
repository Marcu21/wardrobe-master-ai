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

class ChatMessage {
  final String role; // 'user' or 'ai'
  final String text;
  final bool isOutfit;
  final List<Map<String, dynamic>>? outfitItems; // Loaded clothing items
  String? savedOutfitId; // Track if this specific message's outfit was saved
  bool isLoggingWear; // Track loading state for this message

  final int? overallScore;
  final Map<String, dynamic>? scores;

  String? feedbackStatus; // 'liked', 'disliked', null
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
    setState(() {
      if (isLike) {
        _likeScale = 1.35;
      } else {
        _dislikeScale = 1.35;
      }
    });
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) {
      setState(() {
        if (isLike) {
          _likeScale = 1.0;
        } else {
          _dislikeScale = 1.0;
        }
      });
    }
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          top: false,
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Why didn't you like this?",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.style_outlined),
                  title: const Text("Style mismatch"),
                  onTap: () => _onDislikeSelected(ctx, "Style mismatch"),
                ),
                ListTile(
                  leading: const Icon(Icons.wb_sunny_outlined),
                  title: const Text("Weather mismatch"),
                  onTap: () => _onDislikeSelected(ctx, "Weather mismatch"),
                ),
                ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: const Text("Context mismatch"),
                  onTap: () => _onDislikeSelected(ctx, "Context mismatch"),
                ),
              ],
            ),
          ),
        );
      },
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

  Widget _buildAnimatedButton({
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
    final bgColor = isSelected
        ? activeColor.withOpacity(0.12)
        : isDisabled
        ? Colors.grey.shade100
        : Colors.grey.shade100;
    final iconColor = isSelected
        ? activeColor
        : isDisabled
        ? Colors.grey.shade300
        : Colors.grey.shade500;
    final borderColor = isSelected ? activeColor : Colors.transparent;

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
          curve: Curves.easeInOut,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                icon,
                key: ValueKey(isSelected),
                color: iconColor,
                size: 18,
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
        _buildAnimatedButton(
          isLike: true,
          scale: _likeScale,
          onTap: _handleLike,
        ),
        const SizedBox(width: 6),
        _buildAnimatedButton(
          isLike: false,
          scale: _dislikeScale,
          onTap: _handleDislikeTap,
        ),
      ],
    );
  }
}

class AiStylistChatScreen extends StatefulWidget {
  const AiStylistChatScreen({super.key});

  @override
  State<AiStylistChatScreen> createState() => _AiStylistChatScreenState();
}

class _AiStylistChatScreenState extends State<AiStylistChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isTyping = false;

  final ApiService _apiService = ApiService();
  final FirebaseService _firebaseService = FirebaseService();
  final WeatherService _weatherService = WeatherService();

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

  Future<void> _handleDislike(
    ChatMessage message,
    List<Map<String, dynamic>> items,
    String reason,
    BuildContext sheetContext,
  ) async {
    Navigator.pop(sheetContext);
    List<String> ids = items.map((e) => e['id'].toString()).toList();
    if (ids.isNotEmpty &&
        message.userPrompt != null &&
        message.weatherContext != null) {
      try {
        await _firebaseService.saveOutfitFeedback(
          itemIds: ids,
          userPrompt: message.userPrompt!,
          weatherContext: message.weatherContext!,
          isLike: false,
          dislikeReason: reason,
        );
        if (mounted) {
          setState(() {
            message.feedbackStatus = 'disliked';
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save feedback: $e')),
          );
        }
      }
    }
  }

  Color _getScoreColor(num score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  void _showScoreDetails(BuildContext context, Map<String, dynamic> scores) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Score Details",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
                ...scores.entries.map((entry) {
                  final key = entry.key;
                  final num value = entry.value as num;

                  String title = "";
                  IconData iconData = Icons.star_outline;

                  if (key == 'style_match') {
                    title = "Style Match";
                    iconData = Icons.checkroom;
                  } else if (key == 'weather_match') {
                    title = "Weather Match";
                    iconData = Icons.wb_sunny_outlined;
                  } else if (key == 'context_match') {
                    title = "Context Match";
                    iconData = Icons.place_outlined;
                  } else if (key == 'color_harmony') {
                    title = "Color Harmony";
                    iconData = Icons.palette_outlined;
                  } else {
                    title = key
                        .split('_')
                        .map(
                          (word) => word.isNotEmpty
                              ? '${word[0].toUpperCase()}${word.substring(1)}'
                              : '',
                        )
                        .join(' ');
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Row(
                      children: [
                        Icon(iconData, size: 20, color: Colors.grey.shade700),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 110,
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: value / 100,
                              backgroundColor: Colors.grey.withOpacity(0.2),
                              color: _getScoreColor(value),
                              minHeight: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 45,
                          child: Text(
                            '${value.toInt()}%',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
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

    // 1. Get Context (Weather)
    String currentWeatherStr = "Unknown Weather";
    String hourlyForecastStr = "Unknown Forecast";

    final weather = _weatherService.cachedWeather;
    if (weather != null) {
      currentWeatherStr =
          'Currently ${weather.temperature}°C and ${weather.condition} in ${weather.cityName}';

      // Build simple timeline string
      final buffer = StringBuffer();
      for (var item in weather.forecast) {
        buffer.write(
          '${item.timeLabel}: ${item.temperature}°C (${item.condition}), ',
        );
      }
      hourlyForecastStr = buffer.toString();
    }

    try {
      // 2. Call AI Backend
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

      // 3. Fetch Outfit Details (Images)
      List<Map<String, dynamic>> outfitItems = [];
      if (selectedIds.isNotEmpty) {
        outfitItems = await _firebaseService.getItemsByIds(selectedIds);
      }

      if (mounted) {
        setState(() {
          _isTyping = false;

          // Add merged Explanation and Outfit Message
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
            // Fallback if no items found but we have an explanation
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
                  "Sorry, I'm having trouble connecting to my fashion brain right now. Please try again later. ($e)",
            ),
          );
        });
        _scrollToBottom();
      }
    }
  }

  Widget _buildEmptyState() {
    final suggestions = [
      "🏢 Office",
      "☕ Casual Coffee",
      "🏃 Workout",
      "🎉 Night Out",
      "📅 Date Night",
    ];

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.checkroom_rounded,
                size: 64,
                color: Colors.blueGrey,
              ),
              const SizedBox(height: 24),
              const Text(
                "What's your plan for today?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 8,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: suggestions.map((suggestion) {
                  return ActionChip(
                    label: Text(suggestion),
                    backgroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: Colors.black26,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    labelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    onPressed: () => _sendMessage(suggestion),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isUser = message.role == 'user';

    if (message.isOutfit) {
      final items = message.outfitItems ?? [];

      OutfitSortingUtils.sortOutfitItems(items);

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        alignment: Alignment.centerLeft,
        child: Container(
          width: 340, // Slightly wider for the grid and buttons
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score Header
              if (message.overallScore != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 4, top: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: message.overallScore! / 100,
                              backgroundColor: Colors.grey.shade200,
                              color: _getScoreColor(message.overallScore!),
                              strokeWidth: 4,
                            ),
                            Center(
                              child: Text(
                                '${message.overallScore}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Outfit Score",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      _FeedbackButtons(
                        message: message,
                        items: items,
                        firebaseService: _firebaseService,
                        setParentState: setState,
                        parentContext: context,
                      ),
                      if (message.scores != null)
                        IconButton(
                          icon: const Icon(
                            Icons.info_outline,
                            color: Colors.grey,
                          ),
                          onPressed: () =>
                              _showScoreDetails(context, message.scores!),
                        ),
                    ],
                  ),
                ),

              // Explanation Text
              if (message.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 12,
                    right: 12,
                    top: 8,
                    bottom: 12,
                  ),
                  child: Text(
                    message.text,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),

              // Scrollable Horizontal List of Items or Grid
              Container(
                height: 180,
                color: Colors.transparent,
                child: items.isEmpty
                    ? const Center(
                        child: Text(
                          "No items found",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : GestureDetector(
                        onTap: () => _showVerticalPreview(context, items),
                        behavior: HitTestBehavior.opaque,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _buildChatImageThumbnail(item),

                                if (index < items.length - 1)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      color: Colors.grey.shade400,
                                      size: 24,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final List<String> itemIds = items
                              .map((e) => e['id'].toString())
                              .toList();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VirtualDressingRoomScreen(
                                initialItemIds: itemIds,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.tune, size: 16),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text("Remix"),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          List<String> ids = items
                              .map((e) => e['id'].toString())
                              .toList();
                          if (ids.isNotEmpty) {
                            SaveOutfitDialog.show(
                              context,
                              itemIds: ids,
                              isAiGenerated: true,
                            ).then((outfitId) {
                              if (outfitId != null && mounted) {
                                setState(() {
                                  message.savedOutfitId = outfitId;
                                });
                              }
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("No items to save."),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.favorite_border, size: 16),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text("Save", maxLines: 1),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: message.isLoggingWear
                            ? null
                            : () {
                                List<String> ids = items
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
                                      setState(() {
                                        message.savedOutfitId = outfitId;
                                      });
                                    }
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("No items to wear."),
                                    ),
                                  );
                                }
                              },
                        icon: message.isLoggingWear
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.checkroom, size: 16),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text("Wear", maxLines: 1),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: isUser ? Colors.black : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser
                ? const Radius.circular(20)
                : const Radius.circular(4),
            bottomRight: isUser
                ? const Radius.circular(4)
                : const Radius.circular(20),
          ),
          boxShadow: isUser
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 16,
            height: 1.4,
            color: isUser ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          "AI Stylist",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        actions: const [GlobalWardrobeSelector(isActionItem: true)],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return Container(
                          margin: const EdgeInsets.only(left: 16, top: 8),
                          child: const Text(
                            "AI Stylist is thinking...",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        );
                      }
                      return _buildMessage(_messages[index]);
                    },
                  ),
          ),

          // Input Area
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _controller,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: "Type your plans...",
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                            ),
                            onSubmitted: _sendMessage,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.white,
                          ), // Icons.send replacement
                          onPressed: () => _sendMessage(_controller.text),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getItemFlex(Map<String, dynamic> item) {
    final info = item['metadata']?['basic_info'] ?? item['basic_info'] ?? {};
    String cat = '';
    String sub = '';

    if (item.containsKey('category')) {
      cat = item['category'].toString().toLowerCase();
    } else if (info is Map && info.containsKey('category')) {
      cat = info['category'].toString().toLowerCase();
    }

    if (item.containsKey('sub_category')) {
      sub = item['sub_category'].toString().toLowerCase();
    } else if (info is Map && info.containsKey('sub_category')) {
      sub = info['sub_category'].toString().toLowerCase();
    }

    if (cat.contains('head') ||
        sub.contains('hat') ||
        sub.contains('cap') ||
        sub.contains('beanie')) {
      return 1;
    }
    if (cat.contains('outerwear') ||
        sub.contains('jacket') ||
        sub.contains('coat') ||
        sub.contains('blazer')) {
      return 3;
    }
    if (cat.contains('midwear') ||
        sub.contains('sweater') ||
        sub.contains('hoodie') ||
        sub.contains('cardigan') ||
        sub.contains('sweatshirt')) {
      return 3;
    }
    if (cat.contains('bottom') ||
        cat.contains('pant') ||
        sub.contains('jean') ||
        sub.contains('skirt') ||
        sub.contains('short') ||
        sub.contains('legging')) {
      return 4;
    }
    if (cat.contains('shoe') ||
        cat.contains('footwear') ||
        sub.contains('sneaker') ||
        sub.contains('boot') ||
        sub.contains('sandal')) {
      return 2;
    }

    return 3; // Tops / Default
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
            horizontal: 56.0,
            vertical: 32.0,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.grey.shade50],
              ),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(
                        top: 24.0,
                        bottom: 12.0,
                        left: 24.0,
                        right: 40.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Colors.black87,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "OUTFIT PREVIEW",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: items.asMap().entries.expand((entry) {
                            final int index = entry.key;
                            final Map<String, dynamic> item = entry.value;

                            final widgets = <Widget>[
                              Expanded(
                                flex: _getItemFlex(item),
                                child: _buildFullOutfitPreviewImage(item),
                              ),
                            ];

                            if (index < items.length - 1) {
                              widgets.add(const SizedBox(height: 4));
                            }

                            return widgets;
                          }).toList(),
                        ),
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 12,
                      margin: const EdgeInsets.only(bottom: 24, top: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.05),
                        borderRadius: const BorderRadius.all(
                          Radius.elliptical(100, 12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.04),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      iconSize: 16,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close, color: Colors.black54),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ),
                ),
              ],
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

  Widget _buildChatImageThumbnail(
    Map<String, dynamic> item, {
    double height = 160,
  }) {
    final imageBase64 = item['image_base64'] as String?;
    final imageUrl = item['imageUrl'] as String?;
    final resolvedUrl = (imageBase64 != null && imageBase64.isNotEmpty)
        ? imageBase64
        : imageUrl;

    return Container(
      height: height,
      constraints: const BoxConstraints(minWidth: 80),
      child: SmartClothingImage(imageUrl: resolvedUrl, fit: BoxFit.contain),
    );
  }
}
