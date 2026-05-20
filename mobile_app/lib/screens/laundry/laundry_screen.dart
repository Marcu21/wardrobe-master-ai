import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/services/laundry_service.dart';
import 'package:mobile_app/services/wardrobe_state_service.dart';
import 'package:mobile_app/widgets/global_wardrobe_selector.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'widgets/animated_alert.dart';
import 'widgets/laundry_splits_modal.dart';
import 'widgets/laundry_status_banner.dart';
import 'widgets/virtual_basket_view.dart';
import 'widgets/wardrobe_filter_chips.dart';
import 'widgets/wardrobe_grid_item.dart';

const _kBlob1 = Color(0x384F46E5);
const _kBlob2 = Color(0x206352D2);

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

  Widget _buildBlobBackground() {
    return Stack(
      children: [
        Positioned(
          top: -70,
          right: -50,
          child: IgnorePointer(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
              child: Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kBlob1,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 120,
          left: -50,
          child: IgnorePointer(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                width: 160,
                height: 160,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kBlob2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: kBgColor,
        extendBodyBehindAppBar: true,
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
        body: Stack(
          children: [
            _buildBlobBackground(),
            Center(
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
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: kBgColor,
        extendBodyBehindAppBar: true,
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
        body: Stack(
          children: [
            _buildBlobBackground(),
            Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
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
      backgroundColor: kBgColor,
      body: Stack(
        children: [
          _buildBlobBackground(),
          SafeArea(
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
                  delegate: StatusHeaderDelegate(
                    height: 88.0,
                    child: LaundryStatusBanner(
                      statusColor: statusColor,
                      statusIcon: statusIcon,
                      statusTitle: statusTitle,
                      statusSubtitle: statusSubtitle,
                      recommendedTemp: result.recommendedTemp,
                      hasItems: _basketItems.isNotEmpty,
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
                              (entry) => AnimatedAlert(
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
                                    onTap: () => showLaundryAutoSplitModal(
                                      context,
                                      _basketItems,
                                      _laundryService,
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
                                            color: statusColor.withOpacity(
                                              0.12,
                                            ),
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
                      VirtualBasketView(
                        basketItems: _basketItems,
                        statusColor: statusColor,
                        onRemove: _removeFromBasket,
                      ),
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
                      WardrobeFilterChips(
                        allWardrobeItems: _allWardrobeItems,
                        selectedCategory: _selectedCategory,
                        selectedSubCategory: _selectedSubCategory,
                        onCategoryChanged: (val) => setState(() {
                          _selectedCategory = val;
                          _selectedSubCategory = 'All';
                        }),
                        onSubCategoryChanged: (val) => setState(() {
                          _selectedSubCategory = val;
                        }),
                      ),
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
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = filteredDocs[index];
                              return WardrobeGridItem(
                                item: item,
                                onTap: () => _addToBasket(item),
                              );
                            },
                            childCount: filteredDocs.length,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
