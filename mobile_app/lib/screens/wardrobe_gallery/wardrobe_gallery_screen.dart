import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/services/firebase_service.dart';
import 'package:mobile_app/screens/clothing_detail/clothing_detail_screen.dart';
import 'package:mobile_app/services/wardrobe_state_service.dart';
import 'package:mobile_app/widgets/global_wardrobe_selector.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'widgets/gallery_filter_chips.dart';
import 'widgets/wardrobe_card.dart';

const _kBlob1 = Color(0x384F46E5);
const _kBlob2 = Color(0x206352D2);

class WardrobeGalleryScreen extends StatefulWidget {
  const WardrobeGalleryScreen({super.key});

  @override
  State<WardrobeGalleryScreen> createState() => _WardrobeGalleryScreenState();
}

class _WardrobeGalleryScreenState extends State<WardrobeGalleryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _selectedCategory = 'All';
  String _selectedSubCategory = 'All';

  late Stream<QuerySnapshot> _clothingStream;

  @override
  void initState() {
    super.initState();
    wardrobeStateService.addListener(_onWardrobeChanged);
    _updateStream();
  }

  @override
  void dispose() {
    wardrobeStateService.removeListener(_onWardrobeChanged);
    super.dispose();
  }

  void _onWardrobeChanged() {
    setState(() => _updateStream());
  }

  void _updateStream() {
    final currentUserId = FirebaseService().currentUser?.uid;
    var query = _firestore
        .collection('clothing')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true);

    final activeId = wardrobeStateService.activeWardrobeId;
    if (activeId != null) {
      query = query.where('wardrobe_id', isEqualTo: activeId);
    }

    _clothingStream = query.snapshots();
  }

  Widget _buildGalleryGrid(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return SliverFillRemaining(
        child: Center(
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
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.70,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            data['id'] = docs[index].id;
            return WardrobeCard(
              key: ValueKey(docs[index].id),
              data: data,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClothingDetailScreen(itemData: data),
                ),
              ),
            );
          },
          childCount: docs.length,
        ),
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
          SafeArea(
            top: false,
            child: StreamBuilder<QuerySnapshot>(
              stream: _clothingStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.xmark_circle,
                              color: Colors.redAccent,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Something went wrong',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
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
                                color: Colors.black.withOpacity(0.05),
                                border: Border.all(
                                  color: Colors.black.withOpacity(0.08),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 46,
                              height: 46,
                              child: CircularProgressIndicator(
                                color: Colors.black.withOpacity(0.15),
                                strokeWidth: 1.5,
                              ),
                            ),
                            const SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                color: Colors.black87,
                                strokeWidth: 2.5,
                              ),
                            ),
                            const Icon(
                              Icons.checkroom_outlined,
                              color: Colors.black87,
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
                          'Getting your items',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black45,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final allDocs = snapshot.data?.docs ?? [];

                if (allDocs.isEmpty) {
                  return Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, child) => Opacity(
                        opacity: v,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - v)),
                          child: child,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.05),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.checkroom_outlined,
                              size: 44,
                              color: Colors.black38,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Wardrobe is empty',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tap + to add your first item',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black45,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Extract categories
                final Set<String> categories = {'All'};
                for (var doc in allDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final cat = data['basic_info']?['category'] as String?;
                  if (cat != null && cat.isNotEmpty) categories.add(cat);
                }
                final categoryList = categories.toList()..sort();
                categoryList.remove('All');
                categoryList.insert(0, 'All');
                if (!categories.contains(_selectedCategory)) {
                  _selectedCategory = 'All';
                }

                // Extract subcategories
                final Set<String> subCategories = {'All'};
                if (_selectedCategory != 'All') {
                  for (var doc in allDocs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final cat = data['basic_info']?['category'] as String?;
                    if (cat == _selectedCategory) {
                      final sub =
                          data['basic_info']?['sub_category'] as String?;
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

                // Filter
                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final cat = data['basic_info']?['category'] as String?;
                  final sub = data['basic_info']?['sub_category'] as String?;
                  return ((_selectedCategory == 'All') ||
                          (cat == _selectedCategory)) &&
                      ((_selectedSubCategory == 'All') ||
                          (sub == _selectedSubCategory));
                }).toList();

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    const SliverAppBar(
                      pinned: false,
                      floating: false,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      centerTitle: true,
                      title: GlobalWardrobeSelector(),
                    ),
                    SliverToBoxAdapter(
                      child: GalleryFilterChips(
                        items: categoryList,
                        selectedItem: _selectedCategory,
                        onSelected: (val) => setState(() {
                          _selectedCategory = val;
                          _selectedSubCategory = 'All';
                        }),
                      ),
                    ),
                    if (_selectedCategory != 'All')
                      SliverToBoxAdapter(
                        child: GalleryFilterChips(
                          items: subCategoryList,
                          selectedItem: _selectedSubCategory,
                          onSelected: (val) =>
                              setState(() => _selectedSubCategory = val),
                          isSecondary: true,
                        ),
                      ),
                    _buildGalleryGrid(filteredDocs),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
