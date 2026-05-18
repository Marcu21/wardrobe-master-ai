import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobile_app/services/laundry_service.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'package:mobile_app/widgets/smart_clothing_image.dart';

void showLaundryAutoSplitModal(
  BuildContext context,
  List<Map<String, dynamic>> items,
  LaundryService laundryService,
) {
  final suggestions = laundryService.suggestOptimalSplits(items);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.35,
        maxChildSize: 1.0,
        expand: false,
        builder: (context, scrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.96),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.9)),
                ),
                child: SafeArea(
                  top: false,
                  child: CustomScrollView(
                    controller: scrollController,
                    shrinkWrap: true,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  width: 36,
                                  height: 4,
                                  margin: const EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF2FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.auto_awesome,
                                      color: kPrimary,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Optimal Splits',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black87,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.06),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.black54,
                                        size: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                      if (suggestions.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                'Add more items to see optimal combinations.',
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.4),
                                  fontStyle: FontStyle.italic,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      if (suggestions.isNotEmpty)
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final load = suggestions[index];
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  14,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.07),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          18,
                                          18,
                                          18,
                                          0,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              load.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                                color: Colors.black87,
                                                letterSpacing: -0.3,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              load.reason,
                                              style: TextStyle(
                                                color: Colors.black.withOpacity(
                                                  0.42,
                                                ),
                                                fontSize: 13,
                                                fontStyle: FontStyle.italic,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Container(
                                        height: 1,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                        ),
                                        color: Colors.black.withOpacity(0.06),
                                      ),
                                      const SizedBox(height: 14),
                                      SizedBox(
                                        height: 88,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          physics:
                                              const BouncingScrollPhysics(),
                                          padding:
                                              const EdgeInsets.fromLTRB(
                                                18,
                                                0,
                                                18,
                                                0,
                                              ),
                                          itemCount: load.items.length,
                                          itemBuilder: (context, idx) {
                                            final item = load.items[idx];
                                            return Container(
                                              width: 76,
                                              margin: const EdgeInsets.only(
                                                right: 10,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[50],
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: Colors.black
                                                      .withOpacity(0.06),
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: SmartClothingImage(
                                                  imageUrl: item['imageUrl']
                                                      ?.toString(),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                ),
                              );
                            },
                            childCount: suggestions.length,
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
