import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_app/services/firebase_service.dart';
import 'package:mobile_app/screens/add_clothing_screen.dart';
import 'package:mobile_app/screens/clothing_detail_screen.dart';
import 'package:mobile_app/services/wardrobe_state_service.dart';
import '../widgets/global_wardrobe_selector.dart';
import 'package:mobile_app/widgets/smart_clothing_image.dart';

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
    setState(() {
      _updateStream();
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const GlobalWardrobeSelector(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddClothingScreen()),
          );
        },
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _clothingStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data?.docs ?? [];

          if (allDocs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.checkroom_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Wardrobe is empty',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // 1. Extract Categories (Dynamic)
          final Set<String> categories = {'All'};
          for (var doc in allDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final cat = data['basic_info']?['category'] as String?;
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
            for (var doc in allDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final cat = data['basic_info']?['category'] as String?;
              if (cat == _selectedCategory) {
                final sub = data['basic_info']?['sub_category'] as String?;
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

          // 3. Filter Documents
          final filteredDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final cat = data['basic_info']?['category'] as String?;
            final sub = data['basic_info']?['sub_category'] as String?;

            bool matchCategory =
                (_selectedCategory == 'All') || (cat == _selectedCategory);
            bool matchSubCategory =
                (_selectedSubCategory == 'All') ||
                (sub == _selectedSubCategory);

            return matchCategory && matchSubCategory;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Categories
              _buildFilterRow(categoryList, _selectedCategory, (val) {
                setState(() {
                  _selectedCategory = val;
                  _selectedSubCategory = 'All'; // Reset sub on category change
                });
              }),

              // Row 2: Subcategories
              // Only sort of useful if we have enough items, but let's always show it for consistency
              if (_selectedCategory != 'All')
                _buildFilterRow(subCategoryList, _selectedSubCategory, (val) {
                  setState(() {
                    _selectedSubCategory = val;
                  });
                }, isSecondary: true),

              Expanded(child: _buildGalleryGrid(filteredDocs)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterRow(
    List<String> items,
    String selectedItem,
    Function(String) onSelected, {
    bool isSecondary = false,
  }) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      ? (isSecondary ? Colors.black : Colors.white)
                      : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: isSecondary ? 13 : 14,
                ),
              ),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: isSecondary ? Colors.grey[200] : Colors.black,
              backgroundColor: isSecondary ? Colors.transparent : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? (isSecondary ? Colors.black : Colors.black)
                      : (isSecondary
                            ? Colors.grey.shade300
                            : Colors.grey.shade300),
                  width: isSecondary && isSelected ? 1.5 : 1.0,
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

  Widget _buildGalleryGrid(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return const Center(child: Text("No items found."));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.70, // Taller cards to fit brand/sub
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        data['id'] = docs[index].id;
        return _buildClothingCard(context, data);
      },
    );
  }

  Widget _buildClothingCard(BuildContext context, Map<String, dynamic> data) {
    final imageUrl = data['imageUrl'] as String?;
    final brand = data['sustainability_info']?['brand'] ?? 'Unknown Brand';
    final subCategory = data['basic_info']?['sub_category'] ?? '';

    Widget imageWidget = SmartClothingImage(imageUrl: imageUrl);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClothingDetailScreen(itemData: data),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30), // 30px rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                child: imageWidget,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brand,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (subCategory.isNotEmpty)
                    Text(
                      subCategory,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
