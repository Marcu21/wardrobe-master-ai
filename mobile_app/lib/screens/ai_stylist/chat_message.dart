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
