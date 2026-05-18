import 'package:flutter/material.dart';

class SelectionFilterChips extends StatelessWidget {
  final List<Map<String, dynamic>> allWardrobeItems;
  final String selectedCategory;
  final String selectedSubCategory;
  final void Function(String) onCategoryChanged;
  final void Function(String) onSubCategoryChanged;

  const SelectionFilterChips({
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
        _buildChoiceChipRow(categoryList, effectiveCategory, onCategoryChanged),
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
              selectedColor:
                  isSecondary ? Colors.blueGrey.shade700 : Colors.black,
              backgroundColor:
                  isSecondary ? Colors.grey.shade100 : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color:
                      isSelected ? Colors.transparent : Colors.grey.shade300,
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
