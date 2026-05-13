import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/screens/clothing_detail_screen.dart';
import '../widgets/smart_clothing_image.dart';

const _kBgColor = Color(0xFFF4F3F0);
const _kBlob1 = Color(0x380D9488);
const _kBlob2 = Color(0x20047857);

class SustainabilityScreen extends StatefulWidget {
  const SustainabilityScreen({super.key});

  @override
  State<SustainabilityScreen> createState() => _SustainabilityScreenState();
}

class _SustainabilityScreenState extends State<SustainabilityScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _clothingStream;

  static const Color _green = Color(0xFF00695C);
  static const Color _greenLight = Color(0xFFE8F5E9);
  static const Color _orange = Color(0xFFE65100);
  static const Color _orangeLight = Color(0xFFFFF3E0);
  static const Color _red = Color(0xFFE53935);
  static const Color _redLight = Color(0xFFFFEBEE);

  @override
  void initState() {
    super.initState();
    _clothingStream = _firestore
        .collection('clothing')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgColor,
      body: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: _kBgColor)),
          Positioned(
            top: -70,
            right: -50,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kBlob1,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -50,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kBlob2,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 4,
                    left: 4,
                    right: 16,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          CupertinoIcons.back,
                          color: Colors.black87,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'Sustainability',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _clothingStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _green.withOpacity(0.07),
                                      border: Border.all(
                                        color: _green.withOpacity(0.15),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 52,
                                    height: 52,
                                    child: CircularProgressIndicator(
                                      color: _green.withOpacity(0.25),
                                      strokeWidth: 1.5,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: CircularProgressIndicator(
                                      color: _green,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                  const Icon(
                                    CupertinoIcons.leaf_arrow_circlepath,
                                    color: _green,
                                    size: 18,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Analyzing your wardrobe…',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Calculating sustainability metrics',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black45,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final allDocs = snapshot.data?.docs ?? [];
                      if (allDocs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: _green.withOpacity(0.07),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  CupertinoIcons.leaf_arrow_circlepath,
                                  size: 42,
                                  color: _green,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'No data yet.',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black54,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Add items to your wardrobe to start tracking',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black38,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Process logic
                      final now = DateTime.now();
                      List<Map<String, dynamic>> neglectedItems = [];
                      List<Map<String, dynamic>> bestInvestments = [];

                      double totalWardrobeValue = 0.0;
                      int activeItemsCount = 0;

                      for (var doc in allDocs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final wearCount =
                            (data['wear_count'] as num?)?.toInt() ?? 0;
                        final lastWornTimestamp =
                            data['last_worn'] as Timestamp?;
                        final sustainabilityInfo =
                            data['sustainability_info']
                                as Map<String, dynamic>? ??
                            {};

                        final brand =
                            sustainabilityInfo['brand']?.toString() ??
                            'Unknown Brand';
                        final currency =
                            sustainabilityInfo['currency']?.toString() ?? '\$';
                        final price =
                            (sustainabilityInfo['price'] as num?)?.toDouble() ??
                            0.0;
                        final purchaseDateStr =
                            sustainabilityInfo['purchase_date'] as String?;

                        double cpw = price;
                        if (wearCount > 0) cpw = price / wearCount;

                        int daysSinceLastWorn = 365;
                        if (lastWornTimestamp != null) {
                          daysSinceLastWorn = now
                              .difference(lastWornTimestamp.toDate())
                              .inDays;
                        } else if (purchaseDateStr != null &&
                            purchaseDateStr.isNotEmpty) {
                          try {
                            final purchaseDate = DateTime.parse(
                              purchaseDateStr,
                            );
                            daysSinceLastWorn = now
                                .difference(purchaseDate)
                                .inDays;
                          } catch (_) {}
                        }

                        final itemData = Map<String, dynamic>.from(data);
                        itemData['id'] = doc.id;
                        itemData['ui_brand'] = brand;
                        itemData['ui_currency'] = currency;
                        itemData['ui_wearCount'] = wearCount;
                        itemData['cpw'] = cpw;
                        itemData['daysSinceLastWorn'] = daysSinceLastWorn;

                        totalWardrobeValue += price;
                        if (wearCount > 0 && daysSinceLastWorn <= 180)
                          activeItemsCount++;
                        if (daysSinceLastWorn > 180)
                          neglectedItems.add(itemData);
                        if (wearCount > 0) bestInvestments.add(itemData);
                      }

                      final neglectedCount = neglectedItems.length;
                      final totalItemsCount = allDocs.length;
                      final utilizationPercentage = totalItemsCount > 0
                          ? (activeItemsCount / totalItemsCount) * 100
                          : 0.0;

                      neglectedItems.sort(
                        (a, b) => (b['daysSinceLastWorn'] as int).compareTo(
                          a['daysSinceLastWorn'] as int,
                        ),
                      );

                      bestInvestments.sort(
                        (a, b) =>
                            (a['cpw'] as double).compareTo(b['cpw'] as double),
                      );
                      final topInvestments = bestInvestments.take(5).toList();

                      final worstInvestments =
                          List<Map<String, dynamic>>.from(bestInvestments)
                            ..sort(
                              (a, b) => (b['cpw'] as double).compareTo(
                                a['cpw'] as double,
                              ),
                            );
                      final topWorstInvestments = worstInvestments
                          .take(5)
                          .toList();

                      // UI
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Wardrobe Health Card
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOutCubic,
                              builder: (context, v, child) =>
                                  Opacity(opacity: v, child: child),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: utilizationPercentage > 50
                                        ? [
                                            const Color(0xFFE8F5E9),
                                            const Color(0xFFF1F8E9),
                                          ]
                                        : [
                                            const Color(0xFFFFF3E0),
                                            const Color(0xFFFFF8F0),
                                          ],
                                  ),
                                  border: Border.all(
                                    color:
                                        (utilizationPercentage > 50
                                                ? _green
                                                : _orange)
                                            .withOpacity(0.20),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (utilizationPercentage > 50
                                                  ? _green
                                                  : _orange)
                                              .withOpacity(0.12),
                                      blurRadius: 24,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Icon + title
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color:
                                                (utilizationPercentage > 50
                                                        ? _green
                                                        : _orange)
                                                    .withOpacity(0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            CupertinoIcons
                                                .leaf_arrow_circlepath,
                                            color: utilizationPercentage > 50
                                                ? _green
                                                : _orange,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'WARDROBE HEALTH',
                                              style: TextStyle(
                                                fontSize: 10,
                                                letterSpacing: 3,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black45,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              utilizationPercentage > 50
                                                  ? 'Looking great!'
                                                  : 'Needs attention',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.black87,
                                                letterSpacing: -0.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),

                                    // Stats row
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _StatTile(
                                            label: 'Total Value',
                                            value:
                                                '${totalWardrobeValue.toStringAsFixed(0)} RON',
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Container(
                                          width: 1,
                                          height: 40,
                                          color: Colors.black.withOpacity(0.08),
                                        ),
                                        Expanded(
                                          child: _StatTile(
                                            label: 'Active Items',
                                            value:
                                                '$activeItemsCount / $totalItemsCount',
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Container(
                                          width: 1,
                                          height: 40,
                                          color: Colors.black.withOpacity(0.08),
                                        ),
                                        Expanded(
                                          child: _StatTile(
                                            label: 'Utilization',
                                            value:
                                                '${utilizationPercentage.toStringAsFixed(0)}%',
                                            color: utilizationPercentage > 50
                                                ? _green
                                                : _orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // Progress bar
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: LinearProgressIndicator(
                                        value: totalItemsCount > 0
                                            ? activeItemsCount / totalItemsCount
                                            : 0,
                                        minHeight: 6,
                                        backgroundColor: Colors.black
                                            .withOpacity(0.07),
                                        color: utilizationPercentage > 50
                                            ? _green
                                            : _orange,
                                      ),
                                    ),

                                    if (neglectedCount == 0 &&
                                        totalItemsCount > 0) ...[
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            CupertinoIcons
                                                .checkmark_circle_fill,
                                            color: _green,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Your wardrobe is well utilized!',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: _green,
                                              fontWeight: FontWeight.w600,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Consider Donating
                            if (neglectedItems.isNotEmpty) ...[
                              _SectionHeader(
                                label: 'NEGLECTED ITEMS',
                                title: 'Consider Donating or Selling',
                                subtitle: neglectedCount == 1
                                    ? '1 item hasn\'t been worn in 6+ months'
                                    : '$neglectedCount items haven\'t been worn in 6+ months',
                                accentColor: _orange,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 220,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: neglectedItems.length,
                                  itemBuilder: (context, index) {
                                    final item = neglectedItems[index];
                                    return _NeglectedCard(
                                      item: item,
                                      accentColor: _orange,
                                      accentBgColor: _orangeLight,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ClothingDetailScreen(
                                            itemData: item,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],

                            // Best Investments
                            if (topInvestments.isNotEmpty) ...[
                              _SectionHeader(
                                label: 'COST PER WEAR',
                                title: 'Best Investments',
                                subtitle:
                                    'Items you\'re getting the most value from',
                                accentColor: _green,
                              ),
                              const SizedBox(height: 16),
                              ...topInvestments.asMap().entries.map((e) {
                                final index = e.key;
                                final item = e.value;
                                final cpwFormatted =
                                    '${item['ui_currency']}${(item['cpw'] as double).toStringAsFixed(2)}';
                                return _InvestmentRow(
                                  item: item,
                                  cpwFormatted: cpwFormatted,
                                  rank: index + 1,
                                  accentColor: _green,
                                  accentBgColor: _greenLight,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ClothingDetailScreen(itemData: item),
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 32),
                            ],

                            // Worst Investments
                            if (topWorstInvestments.isNotEmpty) ...[
                              _SectionHeader(
                                label: 'COST PER WEAR',
                                title: 'Worst Investments',
                                subtitle:
                                    'Items you\'re getting the least value from',
                                accentColor: _red,
                              ),
                              const SizedBox(height: 16),
                              ...topWorstInvestments.asMap().entries.map((e) {
                                final index = e.key;
                                final item = e.value;
                                final cpwFormatted =
                                    '${item['ui_currency']}${(item['cpw'] as double).toStringAsFixed(2)}';
                                return _InvestmentRow(
                                  item: item,
                                  cpwFormatted: cpwFormatted,
                                  rank: index + 1,
                                  accentColor: _red,
                                  accentBgColor: _redLight,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ClothingDetailScreen(itemData: item),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Stat Tile

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black45,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Section Header

class _SectionHeader extends StatelessWidget {
  final String label;
  final String title;
  final String subtitle;
  final Color accentColor;

  const _SectionHeader({
    required this.label,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 3,
            fontWeight: FontWeight.w600,
            color: accentColor.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black45,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

// Neglected Card

class _NeglectedCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final Color accentColor;
  final Color accentBgColor;
  final VoidCallback onTap;

  const _NeglectedCard({
    required this.item,
    required this.accentColor,
    required this.accentBgColor,
    required this.onTap,
  });

  @override
  State<_NeglectedCard> createState() => _NeglectedCardState();
}

class _NeglectedCardState extends State<_NeglectedCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: 150,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.accentColor.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withOpacity(0.18),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    color: Colors.grey[50],
                    child: SmartClothingImage(
                      imageUrl: widget.item['imageUrl']?.toString(),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item['ui_brand'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Colors.black87,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.accentBgColor,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          '${widget.item['daysSinceLastWorn']}d ago',
                          style: TextStyle(
                            fontSize: 10,
                            color: widget.accentColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Investment Row

class _InvestmentRow extends StatefulWidget {
  final Map<String, dynamic> item;
  final String cpwFormatted;
  final int rank;
  final Color accentColor;
  final Color accentBgColor;
  final VoidCallback onTap;

  const _InvestmentRow({
    required this.item,
    required this.cpwFormatted,
    required this.rank,
    required this.accentColor,
    required this.accentBgColor,
    required this.onTap,
  });

  @override
  State<_InvestmentRow> createState() => _InvestmentRowState();
}

class _InvestmentRowState extends State<_InvestmentRow> {
  double _scale = 1.0;

  String _formatCpw(double cpw) {
    return cpw.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.accentColor.withOpacity(0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withOpacity(0.15),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Rank
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${widget.rank}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: widget.accentColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 72,
                  height: 72,
                  color: Colors.grey[50],
                  child: SmartClothingImage(
                    imageUrl: widget.item['imageUrl']?.toString(),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item['ui_brand'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Colors.black87,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${widget.item['ui_wearCount']} wears',
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              // CPW
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: _formatCpw(widget.item['cpw'] as double),
                          style: TextStyle(
                            color: widget.accentColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: ' ${widget.item['ui_currency']}',
                          style: TextStyle(
                            color: widget.accentColor.withOpacity(0.65),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'per wear',
                    style: TextStyle(
                      color: widget.accentColor.withOpacity(0.55),
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
