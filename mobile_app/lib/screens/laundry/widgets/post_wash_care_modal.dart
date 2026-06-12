import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/services/laundry_service.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'package:mobile_app/widgets/smart_clothing_image.dart';

void showPostWashCareModal(
  BuildContext context,
  List<Map<String, dynamic>> items,
  LaundryService laundryService,
) {
  final careItems = laundryService.getPostWashCareInstructions(items);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.70,
        minChildSize: 0.35,
        maxChildSize: 1.0,
        expand: false,
        builder: (context, scrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.96),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(color: Colors.white.withOpacity(0.9)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Expanded(
                        child: CustomScrollView(
                          controller: scrollController,
                          shrinkWrap: true,
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(24, 12, 24, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: Container(
                                        width: 36,
                                        height: 4,
                                        margin:
                                            const EdgeInsets.only(bottom: 20),
                                        decoration: BoxDecoration(
                                          color:
                                              Colors.black.withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFECFDF5),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: const Color(0xFF16A34A)
                                                  .withOpacity(0.18),
                                            ),
                                          ),
                                          child: const Icon(
                                            CupertinoIcons.wind,
                                            color: Color(0xFF16A34A),
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                'After Your Wash',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.black87,
                                                  letterSpacing: -0.5,
                                                  height: 1.1,
                                                ),
                                              ),
                                              Text(
                                                'Drying & ironing tips for your items',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black
                                                      .withOpacity(0.4),
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => Navigator.pop(context),
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: Colors.black
                                                  .withOpacity(0.06),
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
                            if (careItems.isEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Center(
                                    child: Text(
                                      'No special drying or ironing care needed.',
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
                            if (careItems.isNotEmpty)
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final ci = careItems[index];
                                    return Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 0, 16, 14),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(22),
                                          border: Border.all(
                                            color: Colors.black
                                                .withOpacity(0.07),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.05),
                                              blurRadius: 14,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.horizontal(
                                                left: Radius.circular(22),
                                              ),
                                              child: SizedBox(
                                                width: 80,
                                                height: 96,
                                                child: SmartClothingImage(
                                                  imageUrl: ci.imageUrl,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        14, 16, 14, 16),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      ci.label,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 14,
                                                        color: Colors.black87,
                                                        letterSpacing: -0.3,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Container(
                                                      height: 1,
                                                      color: Colors.black
                                                          .withOpacity(0.06),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    if (ci.dryingTip != null)
                                                      _TipChip(
                                                        icon: Icons.water_drop,
                                                        label: ci.dryingTip!,
                                                        isWarning: ci.dryingTip!
                                                            .startsWith(
                                                                'Do not'),
                                                        color: const Color(
                                                            0xFF0284C7),
                                                      ),
                                                    if (ci.ironingWarning != null) ...[
                                                      const SizedBox(height: 5),
                                                      _TipChip(
                                                        icon: Icons.thermostat,
                                                        label: ci.ironingWarning!,
                                                        isWarning: true,
                                                        color: const Color(
                                                            0xFFD97706),
                                                      ),
                                                    ],
                                                    if (ci.ironingTip != null) ...[
                                                      const SizedBox(height: 5),
                                                      _TipChip(
                                                        icon: Icons.thermostat,
                                                        label: ci.ironingTip!,
                                                        isWarning: false,
                                                        color: const Color(
                                                            0xFFD97706),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  childCount: careItems.length,
                                ),
                              ),
                            const SliverToBoxAdapter(
                                child: SizedBox(height: 12)),
                          ],
                        ),
                      ),
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

class _TipChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isWarning;
  final Color color;

  const _TipChip({
    required this.icon,
    required this.label,
    required this.isWarning,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isWarning ? kDanger : color;
    return Row(
      children: [
        Icon(icon, size: 13, color: effectiveColor),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: effectiveColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

