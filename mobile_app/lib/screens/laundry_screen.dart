import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_app/services/laundry_service.dart';
import 'package:mobile_app/services/wardrobe_state_service.dart';
import '../widgets/global_wardrobe_selector.dart';
import 'package:mobile_app/widgets/smart_clothing_image.dart';

class LaundryScreen extends StatefulWidget {
  const LaundryScreen({super.key});

  @override
  State<LaundryScreen> createState() => _LaundryScreenState();
}

class _LaundryScreenState extends State<LaundryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LaundryService _laundryService = LaundryService();

  List<Map<String, dynamic>> _allWardrobeItems = [];
  final List<Map<String, dynamic>> _basketItems = [];

  String _selectedCategory = 'All';
  String _selectedSubCategory = 'All';

  bool _isLoading = true;
  String? _errorMessage;

  StreamSubscription<QuerySnapshot>? _wardrobeSubscription;

  @override
  void initState() {
    super.initState();
    wardrobeStateService.addListener(_onWardrobeChanged);
    _listenToWardrobe();
  }

  void _onWardrobeChanged() {
    _listenToWardrobe();
  }

  void _listenToWardrobe() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'User not logged in.';
          _isLoading = false;
        });
      }
      return;
    }

    _wardrobeSubscription?.cancel();

    var query = _firestore
        .collection('clothing')
        .where('userId', isEqualTo: currentUser.uid);

    final activeId = wardrobeStateService.activeWardrobeId;
    if (activeId != null) {
      query = query.where('wardrobe_id', isEqualTo: activeId);
    }

    _wardrobeSubscription = query.snapshots().listen(
      (snapshot) {
        final items = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        if (mounted) {
          setState(() {
            _allWardrobeItems = items;

            final dbDirtyItems = items.where((item) {
              final status = item['status']?.toString().toLowerCase();
              final isDirty =
                  item['is_dirty'] == true || item['isDirty'] == true;
              return status == 'dirty' || status == 'laundry' || isDirty;
            }).toList();

            for (var dirty in dbDirtyItems) {
              bool exists = _basketItems.any(
                (bItem) => bItem['id'] == dirty['id'],
              );
              if (!exists) {
                _basketItems.add(dirty);
              }
            }

            _basketItems.removeWhere((basketItem) {
              final serverItem = items.firstWhere(
                (i) => i['id'] == basketItem['id'],
                orElse: () => <String, dynamic>{},
              );
              if (serverItem.isEmpty) return true;

              final status = serverItem['status']?.toString().toLowerCase();
              if (status == 'clean' ||
                  serverItem['is_dirty'] == false ||
                  serverItem['isDirty'] == false) {
                return true;
              }
              return false;
            });

            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Failed to load wardrobe realtime. ${error.toString()}';
            _isLoading = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    wardrobeStateService.removeListener(_onWardrobeChanged);
    _wardrobeSubscription?.cancel();
    super.dispose();
  }

  void _addToBasket(Map<String, dynamic> item) {
    setState(() {
      _basketItems.add(item);
    });
  }

  void _removeFromBasket(Map<String, dynamic> item) {
    setState(() {
      _basketItems.removeWhere((element) => element['id'] == item['id']);
    });
  }

  void _showAutoSplitBottomSheet(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) {
    final suggestions = _laundryService.suggestOptimalSplits(items);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.35,
          maxChildSize: 1.0,
          expand: false,
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
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
                    child: CustomScrollView(
                      controller: scrollController,
                      shrinkWrap: true,
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Container(
                                    width: 36,
                                    height: 4,
                                    margin: const EdgeInsets.only(bottom: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF2FF),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.auto_awesome,
                                        color: Color(0xFF4F46E5),
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Optimal Splits',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black87,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () => Navigator.pop(context),
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
                                  ],
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                        if (suggestions.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  'Add more items to see optimal combinations.',
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.4),
                                    fontStyle: FontStyle.italic,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        if (suggestions.isNotEmpty)
                          SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final load = suggestions[index];
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  14,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.07),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          18,
                                          18,
                                          18,
                                          0,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              load.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                                color: Colors.black87,
                                                letterSpacing: -0.3,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              load.reason,
                                              style: TextStyle(
                                                color: Colors.black.withOpacity(
                                                  0.42,
                                                ),
                                                fontSize: 13,
                                                fontStyle: FontStyle.italic,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Container(
                                        height: 1,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                        ),
                                        color: Colors.black.withOpacity(0.06),
                                      ),
                                      const SizedBox(height: 14),
                                      SizedBox(
                                        height: 88,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          physics:
                                              const BouncingScrollPhysics(),
                                          padding: const EdgeInsets.fromLTRB(
                                            18,
                                            0,
                                            18,
                                            0,
                                          ),
                                          itemCount: load.items.length,
                                          itemBuilder: (context, idx) {
                                            final item = load.items[idx];
                                            return Container(
                                              width: 76,
                                              margin: const EdgeInsets.only(
                                                right: 10,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[50],
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: Colors.black
                                                      .withOpacity(0.06),
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: SmartClothingImage(
                                                  imageUrl: item['imageUrl']
                                                      ?.toString(),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                ),
                              );
                            }, childCount: suggestions.length),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 32)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Smart Laundry',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Center(
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
                      color: Colors.blueGrey.withOpacity(0.07),
                      border: Border.all(
                        color: Colors.blueGrey.withOpacity(0.15),
                        width: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: CircularProgressIndicator(
                      color: Colors.blueGrey.withOpacity(0.25),
                      strokeWidth: 1.5,
                    ),
                  ),
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      color: Colors.blueGrey,
                      strokeWidth: 2.5,
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.sparkles,
                    color: Colors.blueGrey,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Loading wardrobe…',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Getting your items ready',
                style: TextStyle(
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

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Smart Laundry',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    final result = _laundryService.analyzeBasket(_basketItems);

    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    String statusSubtitle;

    if (_basketItems.isEmpty) {
      statusColor = Colors.blueGrey;
      statusIcon = CupertinoIcons.sparkles;
      statusTitle = 'Ready to Wash';
      statusSubtitle = 'Add items from your wardrobe below';
    } else {
      switch (result.status) {
        case LaundryStatus.Safe:
          statusColor = const Color(0xFF16A34A);
          statusIcon = CupertinoIcons.checkmark_circle;
          statusTitle = 'Safe to Wash';
          statusSubtitle =
              '${_basketItems.length} item${_basketItems.length == 1 ? '' : 's'} in basket';
          break;
        case LaundryStatus.Warning:
          statusColor = const Color(0xFFD97706);
          statusIcon = CupertinoIcons.exclamationmark_triangle;
          statusTitle = 'Warning';
          statusSubtitle =
              '${_basketItems.length} item${_basketItems.length == 1 ? '' : 's'} — check alerts below';
          break;
        case LaundryStatus.Critical:
          statusColor = const Color(0xFFDC2626);
          statusIcon = CupertinoIcons.xmark_circle;
          statusTitle = 'Critical Issue';
          statusSubtitle =
              '${_basketItems.length} item${_basketItems.length == 1 ? '' : 's'} — cannot wash together';
          break;
      }
    }

    final Set<String> basketItemIds = _basketItems
        .map((e) => e['id'] as String)
        .toSet();

    final filteredDocs = _allWardrobeItems.where((doc) {
      if (basketItemIds.contains(doc['id'])) return false;
      final cat = doc['basic_info']?['category'] as String?;
      final sub = doc['basic_info']?['sub_category'] as String?;
      bool matchCategory =
          (_selectedCategory == 'All') || (cat == _selectedCategory);
      bool matchSubCategory =
          (_selectedSubCategory == 'All') || (sub == _selectedSubCategory);
      return matchCategory && matchSubCategory;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Title (scrolls away)
            const SliverAppBar(
              pinned: false,
              floating: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: Colors.black),
              title: Text(
                'Smart Laundry',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              actions: [GlobalWardrobeSelector(isActionItem: true)],
            ),

            // 2. Sticky Status Banner
            SliverPersistentHeader(
              pinned: true,
              delegate: _StatusHeaderDelegate(
                height: 88.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.38),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              statusTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              statusSubtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.72),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_basketItems.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.30),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                CupertinoIcons.thermometer,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Max ${result.recommendedTemp}°C',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Alerts
            if (_basketItems.isNotEmpty && result.alerts.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...result.alerts.asMap().entries.map(
                          (entry) => _AnimatedAlert(
                            key: ValueKey(entry.value),
                            alert: entry.value,
                            color: statusColor,
                            index: entry.key,
                          ),
                        ),
                        if (result.status == LaundryStatus.Warning ||
                            result.status == LaundryStatus.Critical)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: GestureDetector(
                                onTap: () => _showAutoSplitBottomSheet(
                                  context,
                                  _basketItems,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: statusColor.withOpacity(0.30),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: statusColor.withOpacity(0.12),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.auto_awesome,
                                        color: statusColor,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 7),
                                      Text(
                                        'Auto-Split Load',
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

            // 4. Virtual Basket & Filters
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Section header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VIRTUAL BASKET',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withOpacity(0.35),
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (_basketItems.isNotEmpty)
                          const Text(
                            'Tap to remove',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              letterSpacing: -0.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Basket container
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 128,
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.80),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: _basketItems.isEmpty
                            ? Colors.black.withOpacity(0.07)
                            : statusColor.withOpacity(0.25),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _basketItems.isEmpty
                              ? Colors.black.withOpacity(0.04)
                              : statusColor.withOpacity(0.14),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: _basketItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_laundry_service,
                                  size: 26,
                                  color: Colors.black.withOpacity(0.18),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap items below to add to the wash',
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.35),
                                    fontStyle: FontStyle.italic,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(10.0),
                            itemCount: _basketItems.length,
                            itemBuilder: (context, index) {
                              final item = _basketItems[index];
                              return GestureDetector(
                                onTap: () => _removeFromBasket(item),
                                child: Container(
                                  width: 94,
                                  margin: const EdgeInsets.only(right: 10.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        SmartClothingImage(
                                          imageUrl: item['imageUrl']
                                              ?.toString(),
                                        ),
                                        // Gradient overlay
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Colors.black.withOpacity(0.50),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Remove icon
                                        Positioned(
                                          bottom: 8,
                                          left: 0,
                                          right: 0,
                                          child: Center(
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.25,
                                                ),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withOpacity(0.5),
                                                ),
                                              ),
                                              child: const Icon(
                                                CupertinoIcons.minus,
                                                color: Colors.white,
                                                size: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // My Wardrobe header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MY WARDROBE',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withOpacity(0.35),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Select to add to basket',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildFiltersWidget(),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // 5. Wardrobe Grid
            filteredDocs.isEmpty
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 48.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                CupertinoIcons.tray,
                                size: 32,
                                color: Colors.black.withOpacity(0.25),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'No items match the filters',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black45,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                            childAspectRatio: 0.75,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = filteredDocs[index];
                        return _WardrobeGridItem(
                          item: item,
                          onTap: () => _addToBasket(item),
                        );
                      }, childCount: filteredDocs.length),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersWidget() {
    final Set<String> categories = {'All'};
    for (var doc in _allWardrobeItems) {
      final cat = doc['basic_info']?['category'] as String?;
      if (cat != null && cat.isNotEmpty) {
        categories.add(cat);
      }
    }
    final categoryList = categories.toList()..sort();
    categoryList.remove('All');
    categoryList.insert(0, 'All');

    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = 'All';
    }

    final Set<String> subCategories = {'All'};
    if (_selectedCategory != 'All') {
      for (var doc in _allWardrobeItems) {
        final cat = doc['basic_info']?['category'] as String?;
        if (cat == _selectedCategory) {
          final sub = doc['basic_info']?['sub_category'] as String?;
          if (sub != null && sub.isNotEmpty) {
            subCategories.add(sub);
          }
        }
      }
    }
    final subCategoryList = subCategories.toList()..sort();
    subCategoryList.remove('All');
    subCategoryList.insert(0, 'All');

    if (!subCategories.contains(_selectedSubCategory)) {
      _selectedSubCategory = 'All';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        _buildChoiceChipRow(categoryList, _selectedCategory, (val) {
          setState(() {
            _selectedCategory = val;
            _selectedSubCategory = 'All';
          });
        }),
        if (_selectedCategory != 'All')
          _buildChoiceChipRow(subCategoryList, _selectedSubCategory, (val) {
            setState(() {
              _selectedSubCategory = val;
            });
          }, isSecondary: true),
      ],
    );
  }

  Widget _buildChoiceChipRow(
    List<String> items,
    String selectedItem,
    Function(String) onSelected, {
    bool isSecondary = false,
  }) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = selectedItem == item;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isSecondary ? Colors.white : Colors.black87)
                      : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected
                        ? (isSecondary ? Colors.black87 : Colors.transparent)
                        : Colors.black.withOpacity(0.10),
                    width: isSelected && isSecondary ? 2.0 : 1.0,
                  ),
                  boxShadow: isSelected && !isSecondary
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.20),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    color: isSelected
                        ? (isSecondary ? Colors.black87 : Colors.white)
                        : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: isSecondary ? 12 : 13,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Wardrobe grid item with tap animation

class _WardrobeGridItem extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const _WardrobeGridItem({required this.item, required this.onTap});

  @override
  State<_WardrobeGridItem> createState() => _WardrobeGridItemState();
}

class _WardrobeGridItemState extends State<_WardrobeGridItem> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.94),
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: SmartClothingImage(
                    imageUrl: widget.item['imageUrl']?.toString(),
                  ),
                ),
                Positioned(
                  right: 7,
                  bottom: 7,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.add,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Animated alert widget

class _AnimatedAlert extends StatefulWidget {
  final String alert;
  final Color color;
  final int index;

  const _AnimatedAlert({
    super.key,
    required this.alert,
    required this.color,
    required this.index,
  });

  @override
  State<_AnimatedAlert> createState() => _AnimatedAlertState();
}

class _AnimatedAlertState extends State<_AnimatedAlert>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.color.withOpacity(0.20)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.info,
                    color: widget.color,
                    size: 13,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.alert,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 13,
                      height: 1.45,
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Sticky header delegate

class _StatusHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StatusHeaderDelegate({required this.child, this.height = 80.0});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.grey[50],
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StatusHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}
