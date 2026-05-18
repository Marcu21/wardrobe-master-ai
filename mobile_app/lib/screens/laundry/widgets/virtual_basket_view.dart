import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/widgets/smart_clothing_image.dart';

class VirtualBasketView extends StatelessWidget {
  final List<Map<String, dynamic>> basketItems;
  final Color statusColor;
  final void Function(Map<String, dynamic>) onRemove;

  const VirtualBasketView({
    super.key,
    required this.basketItems,
    required this.statusColor,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
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
              if (basketItems.isNotEmpty)
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
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 128,
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.80),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: basketItems.isEmpty
                  ? Colors.black.withOpacity(0.07)
                  : statusColor.withOpacity(0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: basketItems.isEmpty
                    ? Colors.black.withOpacity(0.04)
                    : statusColor.withOpacity(0.14),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: basketItems.isEmpty
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
                  itemCount: basketItems.length,
                  itemBuilder: (context, index) {
                    final item = basketItems[index];
                    return GestureDetector(
                      onTap: () => onRemove(item),
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
                                imageUrl: item['imageUrl']?.toString(),
                              ),
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
                              Positioned(
                                bottom: 8,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.5),
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
      ],
    );
  }
}
