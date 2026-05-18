import 'package:flutter/material.dart';

class GalleryFilterChips extends StatelessWidget {
  final List<String> items;
  final String selectedItem;
  final void Function(String) onSelected;
  final bool isSecondary;

  const GalleryFilterChips({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onSelected,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
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
