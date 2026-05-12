import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/firebase_service.dart';
import '../services/calendar_service.dart';
import 'virtual_dressing_room_screen.dart';
import '../utils/outfit_sorting_utils.dart';

// Design tokens
const _kBg = Color(0xFFF4F3F0);
const _kPurple = Color(0xFF4F46E5);
const _kPurpleLight = Color(0xFFEEEDF8);

class OutfitDetailScreen extends StatefulWidget {
  final Map<String, dynamic> outfitData;
  final String outfitId;

  const OutfitDetailScreen({
    super.key,
    required this.outfitData,
    required this.outfitId,
  });

  @override
  State<OutfitDetailScreen> createState() => _OutfitDetailScreenState();
}

class _OutfitDetailScreenState extends State<OutfitDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late TextEditingController _nameController;
  late double _currentRating;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  late int _wearCount;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.outfitData['name'] ?? 'Untitled',
    );
    _currentRating = (widget.outfitData['rating'] ?? 0.0).toDouble();
    _wearCount = (widget.outfitData['wear_count'] ?? 0) as int;
    _fetchItems();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _fetchItems() async {
    try {
      final List<dynamic> itemIdsDynamic = widget.outfitData['item_ids'] ?? [];
      final List<String> itemIds = itemIdsDynamic
          .map((e) => e.toString())
          .toList();
      if (itemIds.isNotEmpty) {
        final items = await _firebaseService.getItemsByIds(itemIds);
        if (mounted) {
          setState(() {
            _items = OutfitSortingUtils.sortOutfitItems(items);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching items: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (_) => Center(
        child: Material(
          type: MaterialType.transparency,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.9)),
                  boxShadow: [
                    BoxShadow(
                      color: _kPurple.withOpacity(0.12),
                      blurRadius: 40,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _kPurple.withOpacity(0.07),
                            border: Border.all(
                              color: _kPurple.withOpacity(0.15),
                              width: 1.5,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            color: _kPurple.withOpacity(0.25),
                            strokeWidth: 1.5,
                          ),
                        ),
                        const SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            color: _kPurple,
                            strokeWidth: 2.5,
                          ),
                        ),
                        const Icon(
                          Icons.auto_awesome,
                          color: _kPurple,
                          size: 14,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Saving changes…',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Just a moment',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withOpacity(0.45),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    try {
      await FirebaseFirestore.instance
          .collection('outfits')
          .doc(widget.outfitId)
          .update({
            'name': _nameController.text.trim(),
            'rating': _currentRating,
          });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Changes saved successfully!'),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving changes: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteOutfit() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (ctx) => Center(
        child: Material(
          type: MaterialType.transparency,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 40,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.trash,
                        color: Color(0xFFDC2626),
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Delete Outfit',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This action cannot be undone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withOpacity(0.5),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _DialogButton(
                            label: 'Cancel',
                            onTap: () => Navigator.pop(ctx, false),
                            isPrimary: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DialogButton(
                            label: 'Delete',
                            onTap: () => Navigator.pop(ctx, true),
                            isPrimary: true,
                            isDestructive: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('outfits')
            .doc(widget.outfitId)
            .delete();
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting outfit: $e'),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _logWear() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (_) => Center(
        child: Material(
          type: MaterialType.transparency,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.9)),
                ),
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
                            color: _kPurple.withOpacity(0.08),
                            border: Border.all(
                              color: _kPurple.withOpacity(0.15),
                              width: 1.5,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: CircularProgressIndicator(
                            color: _kPurple.withOpacity(0.3),
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            color: _kPurple,
                            strokeWidth: 2.5,
                          ),
                        ),
                        const Icon(
                          CupertinoIcons.calendar_badge_plus,
                          color: _kPurple,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Logging wear',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Updating your style history…',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      final outfitRef = db.collection('outfits').doc(widget.outfitId);
      batch.update(outfitRef, {
        'wear_count': FieldValue.increment(1),
        'wear_dates': FieldValue.arrayUnion([Timestamp.now()]),
      });

      final List<dynamic> itemIdsDynamic = widget.outfitData['item_ids'] ?? [];
      for (var id in itemIdsDynamic) {
        final itemRef = db.collection('clothing').doc(id.toString());
        batch.set(itemRef, {
          'wear_count': FieldValue.increment(1),
          'last_worn': Timestamp.now(),
        }, SetOptions(merge: true));
      }

      await batch.commit();

      final calendarService = CalendarService();
      await calendarService.addOutfitEvent(
        widget.outfitData['name'] ?? 'Untitled Outfit',
        DateTime.now(),
      );

      if (mounted) {
        Navigator.pop(context);
        setState(() => _wearCount++);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Outfit logged! Your style history has been updated.',
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging wear: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Widget _buildItemImage(Map<String, dynamic> item) {
    final String rawData = item['imageUrl'] ?? '';
    final info = item['basic_info'] ?? {};
    final String cat = (info['category'] ?? '').toString().toLowerCase();
    final String sub = (info['sub_category'] ?? '').toString().toLowerCase();
    final String subCat = info['sub_category']?.toString() ?? '';

    double imageHeight = 200.0;
    if (cat.contains('bottom') ||
        cat.contains('pant') ||
        sub.contains('jean') ||
        sub.contains('skirt') ||
        sub.contains('dress')) {
      imageHeight = 340.0;
    } else if (cat.contains('outerwear') || sub.contains('coat')) {
      imageHeight = 260.0;
    } else if (sub.contains('hoodie') ||
        sub.contains('sweatshirt') ||
        sub.contains('sweater') ||
        sub.contains('hanorac') ||
        sub.contains('pullover') ||
        sub.contains('jumper')) {
      imageHeight = 240.0;
    }

    if (rawData.isEmpty) return const SizedBox.shrink();

    Widget imageWidget;
    try {
      if (rawData.startsWith('data:image')) {
        final String base64String = rawData.split(',').last;
        imageWidget = Image.memory(
          base64Decode(base64String),
          fit: BoxFit.contain,
          width: double.infinity,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, color: Colors.grey),
        );
      } else if (rawData.startsWith('http')) {
        imageWidget = CachedNetworkImage(
          imageUrl: rawData,
          fit: BoxFit.contain,
          width: double.infinity,
          placeholder: (_, __) => Center(
            child: CircularProgressIndicator(
              color: _kPurple.withOpacity(0.5),
              strokeWidth: 2,
            ),
          ),
          errorWidget: (_, __, ___) =>
              const Icon(Icons.broken_image, color: Colors.grey),
        );
      } else {
        imageWidget = const Center(
          child: Icon(CupertinoIcons.checkmark_circle, color: Colors.grey),
        );
      }
    } catch (e) {
      imageWidget = const Center(child: Icon(Icons.error, color: Colors.grey));
    }

    return Container(
      height: imageHeight,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: imageWidget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAiGenerated = widget.outfitData['is_ai_generated'] ?? false;
    final Timestamp? createdAt = widget.outfitData['created_at'] as Timestamp?;
    final String dateStr = createdAt != null
        ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}'
        : 'Unknown date';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Outfit Details',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.grey[50]!.withOpacity(0.9),
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _ScaleButton(
              onTap: _deleteOutfit,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFDC2626).withOpacity(0.18),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  CupertinoIcons.trash,
                  color: Color(0xFFDC2626),
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Items
              if (_isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          color: _kPurple,
                          strokeWidth: 2,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading items…',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.45),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_items.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Text(
                      'No items found for this outfit.',
                      style: TextStyle(color: Colors.black.withOpacity(0.45)),
                    ),
                  ),
                )
              else
                ..._items.map(_buildItemImage),

              const SizedBox(height: 24),

              // Edit card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: _kPurpleLight,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(
                              CupertinoIcons.pencil,
                              size: 14,
                              color: _kPurple,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Edit Outfit',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 18),
                      color: Colors.black.withOpacity(0.05),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name field
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Outfit Name',
                              labelStyle: TextStyle(
                                color: Colors.black.withOpacity(0.45),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.03),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.black.withOpacity(0.08),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.black.withOpacity(0.08),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: _kPurple,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Rating
                          Text(
                            'Rating',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black.withOpacity(0.45),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: List.generate(5, (index) {
                              final filled = index < _currentRating;
                              return GestureDetector(
                                onTap: () => setState(
                                  () => _currentRating = index + 1.0,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      filled
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      key: ValueKey(filled),
                                      color: filled
                                          ? const Color(0xFFF59E0B)
                                          : Colors.black.withOpacity(0.2),
                                      size: 32,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),

                          const SizedBox(height: 20),
                          Container(
                            height: 1,
                            color: Colors.black.withOpacity(0.05),
                          ),
                          const SizedBox(height: 16),

                          // Metadata row
                          Row(
                            children: [
                              // AI / User badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isAiGenerated
                                      ? _kPurple.withOpacity(0.08)
                                      : Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isAiGenerated
                                        ? _kPurple.withOpacity(0.20)
                                        : Colors.black.withOpacity(0.08),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isAiGenerated
                                          ? Icons.auto_awesome
                                          : CupertinoIcons.person,
                                      size: 12,
                                      color: isAiGenerated
                                          ? _kPurple
                                          : Colors.black54,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      isAiGenerated ? 'AI' : 'Manual',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isAiGenerated
                                            ? _kPurple
                                            : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Wear count
                              Builder(
                                builder: (context) {
                                  if (_wearCount == 0)
                                    return const SizedBox.shrink();
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          CupertinoIcons.checkmark_circle,
                                          size: 12,
                                          color: Colors.black.withOpacity(0.45),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Worn $_wearCount×',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black.withOpacity(
                                              0.45,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              // Date
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      CupertinoIcons.calendar,
                                      size: 12,
                                      color: Colors.black.withOpacity(0.45),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      dateStr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black.withOpacity(0.45),
                                      ),
                                    ),
                                  ],
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

              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  // Log Wear
                  Expanded(
                    child: _ScaleButton(
                      onTap: _logWear,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              CupertinoIcons.calendar_badge_plus,
                              size: 17,
                              color: Colors.black87,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Log Wear',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Remix
                  Expanded(
                    child: _ScaleButton(
                      onTap: () {
                        final List<dynamic> itemIdsDynamic =
                            widget.outfitData['item_ids'] ?? [];
                        final List<String> itemIds = itemIdsDynamic
                            .map((e) => e.toString())
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              CupertinoIcons.shuffle,
                              size: 17,
                              color: Colors.black87,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Remix',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Save changes button
              _ScaleButton(
                onTap: _saveChanges,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B52F0), Color(0xFF3730C8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _kPurple.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        CupertinoIcons.checkmark_circle,
                        size: 17,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Scale button

class _ScaleButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  const _ScaleButton({required this.onTap, required this.child});

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// Dialog button

class _DialogButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isDestructive;

  const _DialogButton({
    required this.label,
    required this.onTap,
    required this.isPrimary,
    this.isDestructive = false,
  });

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final color = widget.isDestructive ? const Color(0xFFDC2626) : _kPurple;
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: widget.isPrimary ? color : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: widget.isPrimary ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
