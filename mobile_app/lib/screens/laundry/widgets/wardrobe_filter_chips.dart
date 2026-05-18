import 'package:flutter/material.dart';

class WardrobeFilterChips extends StatelessWidget {
  final List<Map<String, dynamic>> allWardrobeItems;
  final String selectedCategory;
  final String selectedSubCategory;
  final void Function(String) onCategoryChanged;
  final void Function(String) onSubCategoryChanged;

  const WardrobeFilterChips({
    super.key,
    required this.allWardrobeItems,
    required this.selectedCategory,
    required this.selectedSubCategory,
    required this.onCategoryChanged,
    required this.onSubCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final Set<String> categories = {'All'};
    for (var doc in allWardrobeItems) {
      final cat = doc['basic_info']?['category'] as String?;
      if (cat != null && cat.isNotEmpty) {
        categories.add(cat);
      }
    }
    final categoryList = categories.toList()..sort();
    categoryList.remove('All');
    categoryList.insert(0, 'All');

    final effectiveCategory =
        categories.contains(selectedCategory) ? selectedCategory : 'All';

    final Set<String> subCategories = {'All'};
    if (effectiveCategory != 'All') {
      for (var doc in allWardrobeItems) {
        final cat = doc['basic_info']?['category'] as String?;
        if (cat == effectiveCategory) {
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

    final effectiveSubCategory =
        subCategories.contains(selectedSubCategory) ? selectedSubCategory : 'All';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        _buildChoiceChipRow(
          categoryList,
          effectiveCategory,
          onCategoryChanged,
        ),
        if (effectiveCategory != 'All')
          _buildChoiceChipRow(
            subCategoryList,
            effectiveSubCategory,
            onSubCategoryChanged,
            isSecondary: true,
          ),
      ],
    );
  }

  Widget _buildChoiceChipRow(
    List<String> items,
    String selectedItem,
    void Function(String) onSelected, {
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
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
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
