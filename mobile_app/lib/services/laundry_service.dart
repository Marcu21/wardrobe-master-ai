enum LaundryStatus { Safe, Warning, Critical }

class PostWashCareItem {
  final String label;
  final String? imageUrl;
  final String? dryingTip;
  final String? ironingTip;
  final String? ironingWarning;

  const PostWashCareItem({
    required this.label,
    this.imageUrl,
    this.dryingTip,
    this.ironingTip,
    this.ironingWarning,
  });

  bool get hasAnyTip =>
      dryingTip != null || ironingTip != null || ironingWarning != null;
}

class LaundryAnalysisResult {
  final int recommendedTemp;
  final LaundryStatus status;
  final List<String> alerts;

  LaundryAnalysisResult({
    required this.recommendedTemp,
    required this.status,
    required this.alerts,
  });
}

class LaundryLoadSuggestion {
  final String title;
  final String reason;
  final List<Map<String, dynamic>> items;

  LaundryLoadSuggestion({
    required this.title,
    required this.reason,
    required this.items,
  });
}

class LaundryService {
  /// Analyzes a list of clothing items to determine if they are safe to wash together.
  LaundryAnalysisResult analyzeBasket(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return LaundryAnalysisResult(
        recommendedTemp: 30,
        status: LaundryStatus.Safe,
        alerts: [],
      );
    }

    int? minTemp;
    bool hasDark = false;
    bool hasLight = false;
    bool hasColor = false;
    bool hasHeavy = false;
    bool hasDelicate = false;
    bool hasFootwear = false;
    bool hasNonFootwear = false;

    final List<String> dryCleanItems = [];
    final List<String> handWashItems = [];
    final List<String> doNotWashItems = [];

    final List<String> heavyKeywords = [
      'denim',
      'jeans',
      'leather',
      'heavy wool',
    ];
    final List<String> delicateKeywords = [
      'silk',
      'lace',
      'linen',
      'chiffon',
      'satin',
    ];
    final List<String> footwearKeywords = [
      'shoe',
      'shoes',
      'sneaker',
      'sneakers',
      'footwear',
      'boot',
      'boots',
    ];

    for (final item in items) {
      final basicInfo = item['basic_info'] as Map<String, dynamic>? ?? {};
      final laundryInfo = item['laundry_info'] as Map<String, dynamic>? ?? {};

      // Parse temperature
      final tempRaw = laundryInfo['max_temp_celsius'];
      if (tempRaw != null) {
        int? temp;
        if (tempRaw is int) {
          temp = tempRaw;
        } else if (tempRaw is String) {
          temp = int.tryParse(tempRaw);
        }

        if (temp != null) {
          if (minTemp == null || temp < minTemp) {
            minTemp = temp;
          }
        }
      }

      // Parse color group
      final colorGroup = laundryInfo['color_group']?.toString();
      if (colorGroup == 'Dark') {
        hasDark = true;
      } else if (colorGroup == 'Light') {
        hasLight = true;
      } else if (colorGroup == 'Color') {
        hasColor = true;
      }

      // Parse material and sub_category
      final material = basicInfo['material']?.toString().toLowerCase() ?? '';
      final category = basicInfo['category']?.toString().toLowerCase() ?? '';
      final subCategory =
          basicInfo['sub_category']?.toString().toLowerCase() ?? '';

      final combinedText = '$material $subCategory';
      final categoryCombined = '$category $subCategory';

      final sustainabilityInfo =
          item['sustainability_info'] as Map<String, dynamic>? ?? {};
      final brand = sustainabilityInfo['brand']?.toString() ?? '';

      final rawSub = subCategory.isNotEmpty ? subCategory : category;
      final displaySub = rawSub.isNotEmpty
          ? rawSub[0].toUpperCase() + rawSub.substring(1)
          : 'Item';
      final itemLabel =
          brand.isNotEmpty ? '$brand $displaySub' : displaySub;

      bool isFootwear = false;
      for (final kw in footwearKeywords) {
        if (categoryCombined.contains(kw)) {
          isFootwear = true;
          hasFootwear = true;
          break;
        }
      }

      if (!isFootwear) {
        hasNonFootwear = true;
      }

      for (final kw in heavyKeywords) {
        if (combinedText.contains(kw)) {
          hasHeavy = true;
          break;
        }
      }

      for (final kw in delicateKeywords) {
        if (combinedText.contains(kw)) {
          hasDelicate = true;
          break;
        }
      }

      // Parse care instructions for wash-method constraints
      final careInstructions =
          (laundryInfo['care_instructions'] as List<dynamic>? ?? [])
              .map((e) => e.toString().toLowerCase())
              .toList();

      // Pre-compute shared facts used across multiple checks below.
      final hasDryClean = careInstructions.any(
        (i) => i.contains('dry clean') && !_isNegated(i),
      );
      // 'wash' covers: "machine wash", "hand wash", "wash at 30°C", etc.
      // _isNegated excludes "do not wash", "do not machine wash", etc.
      final canBeWashed = careInstructions.any(
        (i) => i.contains('wash') && !_isNegated(i),
      );
      final canMachineWash = careInstructions.any(
        (i) => i.contains('machine wash') && !_isNegated(i),
      );
      final hasHandWash = careInstructions.any(
        (i) =>
            (i.contains('hand wash') || i.contains('handwash')) &&
            !_isNegated(i),
      );

      bool itemFlagged = false;

      // Priority 1: Dry clean only — checked before "do not wash" so that items
      // labelled with both "Do not wash" and "Dry clean" get the right message.
      if (hasDryClean && !canBeWashed) {
        dryCleanItems.add(itemLabel);
        itemFlagged = true;
      }

      // Priority 2: Cannot be washed at all (spot clean / explicit no-wash).
      // "Do not machine wash" is intentionally excluded — it means hand washing
      // may still be acceptable and is handled by Priority 3.
      if (!itemFlagged) {
        for (final instruction in careInstructions) {
          if (instruction.contains('do not wash') ||
              instruction.contains('spot clean')) {
            doNotWashItems.add(itemLabel);
            itemFlagged = true;
            break;
          }
        }
      }

      // Priority 3: Hand wash only — only warn when machine washing is not an
      // option; if a machine wash instruction also exists, the machine is fine.
      if (!itemFlagged && hasHandWash && !canMachineWash) {
        handWashItems.add(itemLabel);
        itemFlagged = true;
      }

      // Delicate/gentle cycle — independent, runs even when itemFlagged.
      // Checks 'delicate' broadly to catch "Delicate wash", "Delicate machine
      // wash at 30°C", etc., not just the phrase "delicate cycle".
      if (!hasDelicate) {
        for (final instruction in careInstructions) {
          if (instruction.contains('gentle') ||
              instruction.contains('delicate')) {
            hasDelicate = true;
            break;
          }
        }
      }
    }

    int recommendedTemp = minTemp ?? 30;
    LaundryStatus status = LaundryStatus.Safe;
    List<String> alerts = [];

    // Rule A: Temperature Bottleneck
    if (recommendedTemp <= 30 && items.isNotEmpty) {
      alerts.add("Cold wash recommended to protect delicate items.");
    }

    // Rule B: Color Bleeding Risk
    if (hasDark && hasLight) {
      status = LaundryStatus.Critical;
      alerts.add(
        "CRITICAL: Do not wash dark items with light items! Color bleeding risk.",
      );
    } else if (hasColor && hasLight) {
      status = LaundryStatus.Warning;
      alerts.add(
        "WARNING: Colored items may transfer pigment to light items. Use a color catcher or wash separately.",
      );
    }

    // Rule C: Material Friction / Weight Clash
    if (hasHeavy && hasDelicate) {
      if (status != LaundryStatus.Critical) {
        status = LaundryStatus.Warning;
      }
      alerts.add(
        "WARNING: Heavy items (like denim) can damage delicate fabrics (like silk/lace) in the drum. Consider separating.",
      );
    }

    // Rule D: The Footwear Hygiene Rule
    if (hasFootwear && hasNonFootwear) {
      status = LaundryStatus.Critical;
      alerts.add(
        "CRITICAL HYGIENE RISK: Never wash shoes with regular clothes! It is unhygienic and the hard soles will severely damage your fabrics in the drum.",
      );
    } else if (hasFootwear && !hasNonFootwear) {
      if (status != LaundryStatus.Critical) {
        status = LaundryStatus.Warning;
      }
      alerts.add(
        "WARNING: When washing shoes, remove the laces and insoles, use a protective mesh laundry bag, and add some old towels to balance the drum and prevent machine damage. Use a cold, gentle cycle.",
      );
      if (recommendedTemp > 30) {
        recommendedTemp = 30;
      }
    }

    // Rule E: Care instruction wash-method constraints
    for (final label in dryCleanItems) {
      status = LaundryStatus.Critical;
      alerts.add(
        "CRITICAL: $label is dry clean only — remove it from this load and take it to a dry cleaner.",
      );
    }

    for (final label in doNotWashItems) {
      status = LaundryStatus.Critical;
      alerts.add(
        "CRITICAL: $label cannot be washed — remove it from this load (spot clean only).",
      );
    }

    for (final label in handWashItems) {
      if (status != LaundryStatus.Critical) {
        status = LaundryStatus.Warning;
      }
      alerts.add(
        "WARNING: $label requires hand washing — machine washing may damage it.",
      );
    }

    return LaundryAnalysisResult(
      recommendedTemp: recommendedTemp,
      status: status,
      alerts: alerts,
    );
  }

  bool _isNegated(String instruction) =>
      instruction.contains('do not') ||
      instruction.contains("don't") ||
      instruction.contains('cannot') ||
      instruction.contains('never') ||
      instruction.contains('no ');

  /// Returns post-wash care tips (drying + ironing) for each item that has
  /// specific instructions. Items with no relevant tips are omitted.
  List<PostWashCareItem> getPostWashCareInstructions(
    List<Map<String, dynamic>> items,
  ) {
    return items
        .map((item) {
          final laundryInfo =
              item['laundry_info'] as Map<String, dynamic>? ?? {};
          final basicInfo = item['basic_info'] as Map<String, dynamic>? ?? {};
          final sustainabilityInfo =
              item['sustainability_info'] as Map<String, dynamic>? ?? {};

          final careInstructions =
              (laundryInfo['care_instructions'] as List<dynamic>? ?? [])
                  .map((e) => e.toString().toLowerCase())
                  .toList();

          final brand = sustainabilityInfo['brand']?.toString() ?? '';
          final subCategory = basicInfo['sub_category']?.toString() ?? '';
          final category = basicInfo['category']?.toString() ?? '';
          final rawSub = subCategory.isNotEmpty ? subCategory : category;
          final displaySub = rawSub.isNotEmpty
              ? rawSub[0].toUpperCase() + rawSub.substring(1)
              : 'Item';
          final label = brand.isNotEmpty ? '$brand $displaySub' : displaySub;

          return PostWashCareItem(
            label: label,
            imageUrl: item['imageUrl']?.toString() ??
                item['image_url']?.toString(),
            dryingTip: _extractDryingTip(careInstructions),
            ironingTip: _extractIroningTip(careInstructions),
            ironingWarning: _extractIroningWarning(careInstructions),
          );
        })
        .where((ci) => ci.hasAnyTip)
        .toList();
  }

  String? _extractDryingTip(List<String> instructions) {
    for (final i in instructions) {
      if (i.contains('tumble dry') || i.contains('tumble-dry')) {
        if (_isNegated(i)) return 'Do not tumble dry';
        if (i.contains('low')) return 'Tumble dry on low heat';
        if (i.contains('medium')) return 'Tumble dry on medium heat';
        if (i.contains('high')) return 'Tumble dry on high heat';
        return 'Tumble dry';
      }
      if (i.contains('dry flat') || i.contains('flat dry') ||
          i.contains('lay flat')) {
        return 'Lay flat to dry';
      }
      if (i.contains('hang to dry') ||
          i.contains('line dry') ||
          i.contains('hang dry') ||
          i.contains('drip dry')) {
        return 'Hang to dry';
      }
      if (i.contains('air dry') || i.contains('air-dry')) {
        return 'Air dry only';
      }
      if (i.contains('dry in shade') ||
          (i.contains('shade') && i.contains('dry'))) {
        return 'Dry in shade';
      }
      if (i.contains('wring') && _isNegated(i)) return 'Do not wring';
    }
    return null;
  }

  String? _extractIroningWarning(List<String> instructions) {
    for (final i in instructions) {
      if (!i.contains('iron') && !i.contains('steam')) continue;
      if (i.contains('before') &&
          !i.startsWith('iron') &&
          !i.startsWith('do not iron')) continue;
      if (i.contains('iron') && _isNegated(i)) {
        if (i.contains('decoration') || i.contains('design') ||
            i.contains('graphic') || i.contains('print') ||
            i.contains('logo') || i.contains('embroidery') ||
            i.contains('applique') || i.contains('sequin') ||
            i.contains('badge') || i.contains('patch') ||
            i.contains('motif')) {
          return 'Do not iron over design';
        }
        if (i.contains('direct')) return 'Do not iron directly on fabric';
        return 'Do not iron';
      }
      if (i.contains('steam') && _isNegated(i)) return 'Do not use steam';
    }
    return null;
  }

  String? _extractIroningTip(List<String> instructions) {
    for (final i in instructions) {
      if (!i.contains('iron') && !i.contains('steam')) continue;

      if (i.contains('iron')) {
        if (i.contains('before') &&
            !i.startsWith('iron') &&
            !i.startsWith('do not iron')) continue;
        if (_isNegated(i)) continue;

        final hasSteam = i.contains('steam') &&
            !i.contains('without steam') &&
            !i.contains('no steam');
        if (hasSteam) return 'Steam iron only';

        if (i.contains('inside out') ||
            i.contains('reverse side') ||
            i.contains('wrong side')) {
          return 'Iron inside out';
        }
        if (i.contains('110') || i.contains('low') || i.contains('cool')) {
          return 'Iron on low heat (max 110°C)';
        }
        if (i.contains('150') || i.contains('medium') || i.contains('warm')) {
          return 'Iron on medium heat (max 150°C)';
        }
        if (i.contains('200') || i.contains('high')) {
          return 'Iron on high heat (max 200°C)';
        }
        return 'Iron as needed';
      }

      if (i.contains('steam') && !_isNegated(i)) return 'Steam ironing acceptable';
    }
    return null;
  }

  /// Suggests how to safely split items into mutually exclusive laundry loads.
  List<LaundryLoadSuggestion> suggestOptimalSplits(
    List<Map<String, dynamic>> items,
  ) {
    if (items.isEmpty) return [];

    final List<Map<String, dynamic>> dryClean = [];
    final List<Map<String, dynamic>> specialCare = [];
    final List<Map<String, dynamic>> handWashOnly = [];
    final List<Map<String, dynamic>> footwear = [];
    final List<Map<String, dynamic>> delicates = [];
    final List<Map<String, dynamic>> lights = [];
    final List<Map<String, dynamic>> darks = [];
    final List<Map<String, dynamic>> colors = [];

    final List<String> delicateMaterialKeywords = [
      'silk',
      'lace',
      'linen',
      'chiffon',
      'satin',
    ];
    final List<String> footwearKeywords = [
      'shoe',
      'shoes',
      'sneaker',
      'sneakers',
      'footwear',
      'boot',
      'boots',
    ];

    for (final item in items) {
      final basicInfo = item['basic_info'] as Map<String, dynamic>? ?? {};
      final laundryInfo = item['laundry_info'] as Map<String, dynamic>? ?? {};

      final category = basicInfo['category']?.toString().toLowerCase() ?? '';
      final subCategory =
          basicInfo['sub_category']?.toString().toLowerCase() ?? '';
      final material = basicInfo['material']?.toString().toLowerCase() ?? '';
      final colorGroup = laundryInfo['color_group']?.toString();

      final categoryCombined = '$category $subCategory';
      final materialCombined = '$material $subCategory';

      final careInstructions =
          (laundryInfo['care_instructions'] as List<dynamic>? ?? [])
              .map((e) => e.toString().toLowerCase())
              .toList();

      final hasDryClean = careInstructions.any(
        (i) => i.contains('dry clean') && !_isNegated(i),
      );
      final canBeWashed = careInstructions.any(
        (i) => i.contains('wash') && !_isNegated(i),
      );
      final canMachineWash = careInstructions.any(
        (i) => i.contains('machine wash') && !_isNegated(i),
      );
      final hasHandWash = careInstructions.any(
        (i) =>
            (i.contains('hand wash') || i.contains('handwash')) &&
            !_isNegated(i),
      );
      final isDoNotWash = careInstructions.any(
        (i) => i.contains('do not wash') || i.contains('spot clean'),
      );

      // Mirror the same priority order as analyzeBasket.

      // Priority 1: Dry clean only
      if (hasDryClean && !canBeWashed) {
        dryClean.add(item);
        continue;
      }

      // Priority 2: Cannot be washed at all
      if (isDoNotWash) {
        specialCare.add(item);
        continue;
      }

      // Priority 3: Hand wash only (no machine wash instruction)
      if (hasHandWash && !canMachineWash) {
        handWashOnly.add(item);
        continue;
      }

      // Priority 4: Footwear
      bool isFootwear = false;
      for (final kw in footwearKeywords) {
        if (categoryCombined.contains(kw)) {
          isFootwear = true;
          break;
        }
      }
      if (isFootwear) {
        footwear.add(item);
        continue;
      }

      // Priority 5: Delicate material OR delicate/gentle care instruction
      bool isDelicate = delicateMaterialKeywords.any(
        (kw) => materialCombined.contains(kw),
      );
      if (!isDelicate) {
        isDelicate = careInstructions.any(
          (i) => i.contains('gentle') || i.contains('delicate'),
        );
      }
      if (isDelicate) {
        delicates.add(item);
        continue;
      }

      // Priority 6: Color-based machine wash loads
      if (colorGroup == 'Light') {
        lights.add(item);
      } else if (colorGroup == 'Dark') {
        darks.add(item);
      } else if (colorGroup == 'Color') {
        colors.add(item);
      } else {
        colors.add(item);
      }
    }

    final List<LaundryLoadSuggestion> suggestions = [];

    if (dryClean.isNotEmpty) {
      suggestions.add(
        LaundryLoadSuggestion(
          title: 'Dry Clean Only',
          reason:
              'These items cannot be machine washed — take them to a dry cleaner.',
          items: dryClean,
        ),
      );
    }

    if (specialCare.isNotEmpty) {
      suggestions.add(
        LaundryLoadSuggestion(
          title: 'Special Care',
          reason:
              'These items cannot be washed in any machine — spot clean or follow the care label.',
          items: specialCare,
        ),
      );
    }

    if (handWashOnly.isNotEmpty) {
      suggestions.add(
        LaundryLoadSuggestion(
          title: 'Hand Wash Only',
          reason:
              'These items must be washed by hand — machine washing may damage them.',
          items: handWashOnly,
        ),
      );
    }

    if (footwear.isNotEmpty) {
      suggestions.add(
        LaundryLoadSuggestion(
          title: 'Footwear Load',
          reason:
              'Shoes must be washed separately for hygiene and machine safety.',
          items: footwear,
        ),
      );
    }

    if (delicates.isNotEmpty) {
      suggestions.add(
        LaundryLoadSuggestion(
          title: 'Delicates Load',
          reason:
              'Delicate fabrics need a gentle, cold cycle to prevent damage.',
          items: delicates,
        ),
      );
    }

    if (lights.isNotEmpty) {
      suggestions.add(
        LaundryLoadSuggestion(
          title: 'Whites & Lights Load',
          reason: 'Wash light colors together to prevent color bleeding.',
          items: lights,
        ),
      );
    }

    final darksAndColors = [...darks, ...colors];
    if (darksAndColors.isNotEmpty) {
      suggestions.add(
        LaundryLoadSuggestion(
          title: 'Darks & Colors Load',
          reason:
              'Dark and colored items are safe to wash together — keep them away from lights only.',
          items: darksAndColors,
        ),
      );
    }

    return suggestions;
  }
}
