import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_app/services/laundry_service.dart';
import 'package:mobile_app/services/wardrobe_state_service.dart';
import '../widgets/global_wardrobe_selector.dart';

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

    _wardrobeSubscription?.cancel(); // Cancel any existing subscription

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

            // React dynamically if items have a status indicating they are dirty
            final dbDirtyItems = items.where((item) {
              final category =
                  item['basic_info']?['category'] ??
                  ''; // Some apps use category to infer
              final status = item['status']?.toString().toLowerCase();
              final isDirty =
                  item['is_dirty'] == true || item['isDirty'] == true;
              return status == 'dirty' || status == 'laundry' || isDirty;
            }).toList();

            // Auto-add dirty items to basket if not already there
            for (var dirty in dbDirtyItems) {
              bool exists = _basketItems.any(
                (bItem) => bItem['id'] == dirty['id'],
              );
              if (!exists) {
                _basketItems.add(dirty);
              }
            }

            // Automatically remove from basket if the item was marked clean remotely
            _basketItems.removeWhere((basketItem) {
              final serverItem = items.firstWhere(
                (i) => i['id'] == basketItem['id'],
                orElse: () => <String, dynamic>{},
              );
              if (serverItem.isEmpty) return true; // deleted

              final status = serverItem['status']?.toString().toLowerCase();
              final isDirty =
                  serverItem['is_dirty'] == true ||
                  serverItem['isDirty'] == true;

              // If we rely strictly on server states for removal, we only remove if explicitly marked clean
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

  Widget _buildImageWidget(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) => Container(
            color: Colors.grey[100],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image),
          ),
        );
      } else if (imageUrl.startsWith('data:image')) {
        final base64String = imageUrl.split(',').last;
        try {
          return Image.memory(base64Decode(base64String), fit: BoxFit.contain);
        } catch (e) {
          return Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image),
          );
        }
      } else {
        try {
          return Image.memory(base64Decode(imageUrl), fit: BoxFit.contain);
        } catch (e) {
          return Container(
            color: Colors.grey[200],
            child: const Icon(Icons.image),
          );
        }
      }
    }
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.checkroom),
    );
  }

  void _showAutoSplitBottomSheet(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) {
    final suggestions = _laundryService.suggestOptimalSplits(items);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: CustomScrollView(
            shrinkWrap: true,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.amber),
                          SizedBox(width: 8),
                          Text(
                            'Optimal Splits',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
              if (suggestions.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        'Add more items to see optimal combinations.',
                      ),
                    ),
                  ),
                ),
              if (suggestions.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final load = suggestions[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              load.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              load.reason,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 70, // compact horizontal list
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: load.items.length,
                                itemBuilder: (context, idx) {
                                  final item = load.items[idx];
                                  return Container(
                                    width: 60,
                                    margin: const EdgeInsets.only(right: 8.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: _buildImageWidget(
                                        item['imageUrl']?.toString(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: suggestions.length),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
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
        body: const Center(
          child: CircularProgressIndicator(color: Colors.blueGrey),
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

    if (_basketItems.isEmpty) {
      statusColor = Colors.blueGrey;
      statusIcon = Icons.local_laundry_service;
      statusTitle = 'Ready to Wash';
    } else {
      switch (result.status) {
        case LaundryStatus.Safe:
          statusColor = Colors.green;
          statusIcon = Icons.check_circle_outline;
          statusTitle = 'Safe to Wash';
          break;
        case LaundryStatus.Warning:
          statusColor = Colors.amber.shade700;
          statusIcon = Icons.warning_amber_rounded;
          statusTitle = 'Warning';
          break;
        case LaundryStatus.Critical:
          statusColor = Colors.red.shade600;
          statusIcon = Icons.dangerous_outlined;
          statusTitle = 'Critical Issue';
          break;
      }
    }

    // Determine which items are already in the basket
    final Set<String> basketItemIds = _basketItems
        .map((e) => e['id'] as String)
        .toSet();

    // Filter Documents for the grid
    final filteredDocs = _allWardrobeItems.where((doc) {
      if (basketItemIds.contains(doc['id'])) {
        return false; // Hide items already in the basket
      }
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
            // 1. The Main Title (Scrolls away)
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
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [GlobalWardrobeSelector(isActionItem: true)],
            ),

            // 2. Sticky Status Header
            SliverPersistentHeader(
              pinned: true,
              delegate: _StatusHeaderDelegate(
                height: 80.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 64.0, // Compact banner
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          statusTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_basketItems.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.thermostat,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Max ${result.recommendedTemp}°C',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
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

            // 2. Explanations (Alerts)
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
                        ...result.alerts.map(
                          (alert) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Icon(
                                      Icons.info_outline,
                                      color: statusColor,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      alert,
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                      softWrap: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (result.status == LaundryStatus.Warning ||
                            result.status == LaundryStatus.Critical)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: OutlinedButton.icon(
                                onPressed: () => _showAutoSplitBottomSheet(
                                  context,
                                  _basketItems,
                                ),
                                icon: const Icon(Icons.auto_awesome, size: 18),
                                label: const Text(
                                  'Auto-Split Load',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: statusColor,
                                  side: BorderSide(
                                    color: statusColor,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
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

            // 3. Virtual Basket & Filters
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 4.0,
                    ),
                    child: Text(
                      'Virtual Basket',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    height: 120,
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: _basketItems.isEmpty
                        ? Center(
                            child: Text(
                              'Tap items below to add to the wash',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.all(8.0),
                            itemCount: _basketItems.length,
                            itemBuilder: (context, index) {
                              final item = _basketItems[index];
                              return GestureDetector(
                                onTap: () => _removeFromBasket(item),
                                child: Container(
                                  width: 94,
                                  margin: const EdgeInsets.only(right: 10.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        _buildImageWidget(
                                          item['imageUrl']?.toString(),
                                        ),
                                        Container(
                                          color: Colors.black.withOpacity(0.35),
                                        ),
                                        const Center(
                                          child: Icon(
                                            Icons.remove_circle_outline,
                                            color: Colors.white,
                                            size: 28,
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
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 4.0),
                    child: Text(
                      'My Wardrobe',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  _buildFiltersWidget(),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // 4. Wardrobe Grid
            filteredDocs.isEmpty
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40.0),
                        child: Text(
                          'No available items match the criteria.',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 4.0,
                            mainAxisSpacing: 6.0,
                            childAspectRatio: 0.75,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = filteredDocs[index];
                        return GestureDetector(
                          onTap: () => _addToBasket(item),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: _buildImageWidget(
                                      item['imageUrl']?.toString(),
                                    ),
                                  ),
                                  Positioned(
                                    right: 6,
                                    bottom: 6,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent.withOpacity(
                                          0.95,
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.2,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(6),
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
    // 1. Extract Categories
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

    // Keep selected category valid
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = 'All';
    }

    // 2. Extract Subcategories based on selected category
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

    // Keep selected subcategory valid
    if (!subCategories.contains(_selectedSubCategory)) {
      _selectedSubCategory = 'All';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Essential for space optimization
      children: [
        const SizedBox(height: 12),
        _buildChoiceChipRow(categoryList, _selectedCategory, (val) {
          setState(() {
            _selectedCategory = val;
            _selectedSubCategory = 'All'; // Reset sub on category change
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
      height: 40, // Space optimized height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = selectedItem == item;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                item,
                style: TextStyle(
                  color: isSelected
                      ? (isSecondary ? Colors.white : Colors.white)
                      : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: isSecondary ? 12 : 13,
                ),
              ),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: isSecondary
                  ? Colors.blueGrey.shade700
                  : Colors.black,
              backgroundColor: isSecondary
                  ? Colors.grey.shade100
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? Colors.transparent
                      : (isSecondary
                            ? Colors.grey.shade300
                            : Colors.grey.shade300),
                  width: 1.0,
                ),
              ),
              onSelected: (bool selected) {
                if (selected) {
                  onSelected(item);
                }
              },
            ),
          );
        },
      ),
    );
  }
}

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
