import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import '../services/weather_service.dart';
import '../widgets/save_outfit_dialog.dart';

class ChatMessage {
  final String role; // 'user' or 'ai'
  final String text;
  final bool isOutfit;
  final List<Map<String, dynamic>>? outfitItems; // Loaded clothing items

  ChatMessage({
    required this.role,
    required this.text,
    this.isOutfit = false,
    this.outfitItems,
  });
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
      currentWeatherStr = 'Currently ${weather.temperature}°C and ${weather.condition} in ${weather.cityName}';
      
      // Build simple timeline string
      final buffer = StringBuffer();
      for (var item in weather.forecast) {
        buffer.write('${item.timeLabel}: ${item.temperature}°C (${item.condition}), ');
      }
      hourlyForecastStr = buffer.toString();
    }

    try {
      // 2. Call AI Backend
      final response = await _apiService.generateOutfit(
        userPrompt: text,
        currentWeather: currentWeatherStr,
        hourlyForecast: hourlyForecastStr,
      );

      final explanation = response['explanation'] as String;
      final selectedIds = List<String>.from(response['selected_item_ids'] ?? []);

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
             _messages.add(ChatMessage(
              role: 'ai', 
              text: explanation, 
              isOutfit: true,
              outfitItems: outfitItems,
            ));
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
          _messages.add(ChatMessage(
            role: 'ai', 
            text: "Sorry, I'm having trouble connecting to my fashion brain right now. Please try again later. ($e)"
          ));
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
              const Icon(Icons.checkroom_rounded, size: 64, color: Colors.blueGrey),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        alignment: Alignment.centerLeft,
        child: Container(
          width: 300, // Slightly wider for the grid
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Explanation Text
              if (message.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    message.text,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
                
              // Scrollable Horizontal List of Items or Grid
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(0)), // Flattened top
                ),
                child: items.isEmpty 
                  ? const Center(child: Text("No items found"))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: Builder(
                                    builder: (context) {
                                      final String imageUrl = item['imageUrl'] ?? '';
                                      if (imageUrl.startsWith('data:image')) {
                                        try {
                                          final String base64String = imageUrl.split(',').last;
                                          return Image.memory(
                                            base64Decode(base64String),
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
                                          );
                                        } catch (e) {
                                          return const Icon(Icons.error, color: Colors.grey);
                                        }
                                      } else if (imageUrl.startsWith('http')) {
                                        return Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
                                        );
                                      } else {
                                        return const Icon(Icons.checkroom, color: Colors.grey, size: 40);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  item['basic_info']?['sub_category'] ?? 'Item',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          List<String> ids = items.map((e) => e['id'].toString()).toList();
                          if (ids.isNotEmpty) {
                            SaveOutfitDialog.show(context, itemIds: ids, isAiGenerated: true);
                          } else {
                             ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("No items to save.")),
                             );
                          }
                        },
                        icon: const Icon(Icons.favorite_border, size: 18),
                        label: const Text("Save"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                           // TODO: Implement Log Wear
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Outfit logged as worn! (Coming Soon)")),
                          );
                        },
                        icon: const Icon(Icons.checkroom, size: 18),
                        label: const Text("Wear"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                        ),
                      ),
                    ),
                  ],
                ),
              )
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
            bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
          ),
          boxShadow: isUser ? [] : [
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
      backgroundColor: const Color(0xFFFAFAFA), // Colors.grey[50] replacement
      appBar: AppBar(
        title: const Text(
          "AI Stylist", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
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
                           style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
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
              child: Row(
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
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                      icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white), // Icons.send replacement
                      onPressed: () => _sendMessage(_controller.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
