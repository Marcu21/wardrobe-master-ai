import 'package:flutter/material.dart';
import 'package:mobile_app/widgets/smart_clothing_image.dart';

class ClothingCarouselRow extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final int flex;
  final void Function(int) onIndexChanged;
  final Alignment alignment;
  final double viewportFraction;
  final String categoryLabel;
  final IconData categoryIcon;

  const ClothingCarouselRow({
    super.key,
    required this.items,
    required this.flex,
    required this.onIndexChanged,
    required this.categoryLabel,
    required this.categoryIcon,
    this.alignment = Alignment.center,
    this.viewportFraction = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: ClothingCarouselRowInternal(
        items: items,
        onIndexChanged: onIndexChanged,
        alignment: alignment,
        viewportFraction: viewportFraction,
        categoryLabel: categoryLabel,
        categoryIcon: categoryIcon,
      ),
    );
  }
}

class ClothingCarouselRowInternal extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final void Function(int) onIndexChanged;
  final Alignment alignment;
  final double viewportFraction;
  final String categoryLabel;
  final IconData categoryIcon;

  const ClothingCarouselRowInternal({
    super.key,
    required this.items,
    required this.onIndexChanged,
    required this.categoryLabel,
    required this.categoryIcon,
    this.alignment = Alignment.center,
    this.viewportFraction = 0.6,
  });

  @override
  State<ClothingCarouselRowInternal> createState() =>
      _ClothingCarouselRowInternalState();
}

class _ClothingCarouselRowInternalState
    extends State<ClothingCarouselRowInternal> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: widget.viewportFraction);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.04),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12, width: 1),
              ),
              child: Icon(
                widget.categoryIcon,
                size: 22,
                color: Colors.black26,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.categoryLabel,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black26,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    }

    return PageView.builder(
      controller: _controller,
      itemCount: widget.items.length,
      onPageChanged: widget.onIndexChanged,
      physics: const BouncingScrollPhysics(),
      padEnds: true,
      itemBuilder: (context, index) {
        return Container(
          alignment: widget.alignment,
          width: double.infinity,
          child: SmartClothingImage(
            imageUrl: widget.items[index]['imageUrl']?.toString(),
          ),
        );
      },
    );
  }
}
