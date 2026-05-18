import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/wardrobe_state_service.dart';
import '../widgets/smart_clothing_image.dart';
import 'package:mobile_app/theme/app_colors.dart';

const _kBlob1 = Color(0x3840C4FF);
const _kBlob2 = Color(0x1E1565C0);

class ItemSelectionScreen extends StatefulWidget {
  final List<String> initialSelectedIds;

  const ItemSelectionScreen({super.key, required this.initialSelectedIds});

  @override
  State<ItemSelectionScreen> createState() => _ItemSelectionScreenState();
}

class _ItemSelectionScreenState extends State<ItemSelectionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _wardrobeSubscription;

  List<Map<String, dynamic>> _allWardrobeItems = [];
  Set<String> _selectedIds = {};

  String _selectedCategory = 'All';
  String _selectedSubCategory = 'All';

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.initialSelectedIds);
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
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load wardrobe. ${error.toString()}';
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

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
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
      height: 40,
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
                  color: isSelected ? Colors.white : Colors.black87,
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
                  color: isSelected ? Colors.transparent : Colors.grey.shade300,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: kBgColor)),
          Positioned(
            top: -80,
            right: -60,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kBlob1,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -60,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kBlob2,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 4,
                    left: 4,
                    right: 4,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          CupertinoIcons.back,
                          color: Colors.black87,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'Select Items',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, _selectedIds.toList()),
                        child: Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blueGrey),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    final filteredDocs = _allWardrobeItems.where((doc) {
      final cat = doc['basic_info']?['category'] as String?;
      final sub = doc['basic_info']?['sub_category'] as String?;
      final matchCategory =
          (_selectedCategory == 'All') || (cat == _selectedCategory);
      final matchSubCategory =
          (_selectedSubCategory == 'All') || (sub == _selectedSubCategory);
      return matchCategory && matchSubCategory;
    }).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_buildFiltersWidget(), const SizedBox(height: 16)],
          ),
        ),
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
                    final id = item['id'];
                    final isSelected = _selectedIds.contains(id);
                    final primaryColor = Theme.of(context).colorScheme.primary;

                    return GestureDetector(
                      onTap: () => _toggleSelection(id),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? primaryColor
                                : Colors.transparent,
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: SmartClothingImage(
                                  imageUrl: item['imageUrl']?.toString(),
                                ),
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: primaryColor,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: filteredDocs.length),
                ),
              ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}
