enum LaundryStatus { Safe, Warning, Critical }

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

    return LaundryAnalysisResult(
      recommendedTemp: recommendedTemp,
      status: status,
      alerts: alerts,
    );
  }

  /// Suggests how to safely split items into mutually exclusive laundry loads.
  List<LaundryLoadSuggestion> suggestOptimalSplits(
    List<Map<String, dynamic>> items,
  ) {
    if (items.isEmpty) return [];

    final List<Map<String, dynamic>> footwear = [];
    final List<Map<String, dynamic>> delicates = [];
    final List<Map<String, dynamic>> lights = [];
    final List<Map<String, dynamic>> darks = [];
    final List<Map<String, dynamic>> colors = [];

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

      final category = basicInfo['category']?.toString().toLowerCase() ?? '';
      final subCategory =
          basicInfo['sub_category']?.toString().toLowerCase() ?? '';
      final material = basicInfo['material']?.toString().toLowerCase() ?? '';
      final colorGroup = laundryInfo['color_group']?.toString();

      final categoryCombined = '$category $subCategory';
      final materialCombined = '$material $subCategory';

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

      bool isDelicate = false;
      for (final kw in delicateKeywords) {
        if (materialCombined.contains(kw)) {
          isDelicate = true;
          break;
        }
      }

      if (isDelicate) {
        delicates.add(item);
        continue;
      }

      if (colorGroup == 'Light') {
        lights.add(item);
      } else if (colorGroup == 'Dark') {
        darks.add(item);
      } else if (colorGroup == 'Color') {
        colors.add(item);
      } else {
        // Default to colors if unknown
        colors.add(item);
      }
    }

    final List<LaundryLoadSuggestion> suggestions = [];

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

    if (darks.isNotEmpty) {
      suggestions.add(
        LaundryLoadSuggestion(
          title: 'Darks Load',
          reason: 'Dark items can bleed; keep them separated from lights.',
          items: darks,
        ),
      );
    }

    if (colors.isNotEmpty) {
      suggestions.add(
        LaundryLoadSuggestion(
          title: 'Colors Load',
          reason: 'Wash colored items together to maintain vibrancy.',
          items: colors,
        ),
      );
    }

    return suggestions;
  }
}
