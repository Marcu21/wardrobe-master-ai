import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../services/packing_service.dart';
import '../services/weather_service.dart';

class PackingResultScreen extends StatefulWidget {
  final String destination;
  final int days;
  final String vibe;
  final DateTimeRange dateRange;

  const PackingResultScreen({
    super.key,
    required this.destination,
    required this.days,
    required this.vibe,
    required this.dateRange,
  });

  @override
  State<PackingResultScreen> createState() => _PackingResultScreenState();
}

class _PackingResultScreenState extends State<PackingResultScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Map<String, dynamic>> _clothingItems = [];
  final Set<String> _packedItemIds = {};
  bool _isLoading = true;
  CapsuleWardrobe? _generatedWardrobe;
  bool _isStylistNoteExpanded = false;

  @override
  void initState() {
    super.initState();
    _generateWardrobe();
  }

  Future<void> _generateWardrobe() async {
    try {
      final weatherSummary = await WeatherService().getTripWeatherSummary(
        widget.destination, 
        widget.dateRange.start,
        widget.dateRange.end
      );
      
      final wardrobe = await PackingService().generatePackingList(
        destination: widget.destination,
        days: widget.days,
        vibe: widget.vibe,
        weatherForecast: weatherSummary,
      );

      final snapshot = await _firestore
          .collection('clothing')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .get();
      // Filter locally to avoid 10-item limit of 'whereIn'
      final items = snapshot.docs
          .where((doc) => wardrobe.selectedItemIds.contains(doc.id))
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();

      if (mounted) {
        setState(() {
          _generatedWardrobe = wardrobe;
          _clothingItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error generating wardrobe: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildImageWidget(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) => Container(
            color: Colors.grey[100],
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image),
          ),
        );
      } else if (imageUrl.startsWith('data:image')) {
        final base64String = imageUrl.split(',').last;
        try {
          return Image.memory(
            base64Decode(base64String),
            fit: BoxFit.contain,
          );
        } catch (e) {
          return Container(color: Colors.grey[200], child: const Icon(Icons.broken_image));
        }
      } else {
        try {
          return Image.memory(
            base64Decode(imageUrl),
            fit: BoxFit.contain,
          );
        } catch (e) {
          return Container(color: Colors.grey[200], child: const Icon(Icons.image));
        }
      }
    }
    return Container(color: Colors.grey[200], child: const Icon(Icons.checkroom));
  }

  void _togglePacked(String itemId) {
    setState(() {
      if (_packedItemIds.contains(itemId)) {
        _packedItemIds.remove(itemId);
      } else {
        _packedItemIds.add(itemId);
      }
    });
  }

  Widget _buildSkeletonLoader() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Expanded(
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 0.85,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: _isLoading 
          ? SafeArea(child: _buildSkeletonLoader())
          : SafeArea(
              top: false,
              bottom: true,
              child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    floating: false,
                    pinned: true,
                    toolbarHeight: 80.0,
                    expandedHeight: 130.0,
                    backgroundColor: Colors.grey[50],
                    elevation: innerBoxIsScrolled ? 2 : 0,
                    centerTitle: true,
                    shadowColor: Colors.black.withOpacity(0.3),
                    iconTheme: const IconThemeData(color: Colors.black87),
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 17), 
                        Text(
                          widget.destination,
                          style: TextStyle(
                            fontSize: 22.0,
                            fontWeight: FontWeight.w900,
                            color: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${widget.days} Days • ${widget.vibe}",
                          style: TextStyle(
                            fontSize: 13.0,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    bottom: TabBar(
                      labelColor: Colors.black87,
                      unselectedLabelColor: Colors.grey[500],
                      indicatorColor: Theme.of(context).primaryColor,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      tabs: const [
                        Tab(icon: Icon(Icons.luggage), text: "Checklist"),
                        Tab(icon: Icon(Icons.style), text: "Daily Outfits"),
                      ],
                    ),
                  ),
                ];
              },
              body: Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                child: TabBarView(
                  children: [
                    _buildChecklistTab(),
                    _buildOutfitsTab(),
                  ],
                ),
              ),
            ),
            ),
      ),
    );
  }

  Widget _buildChecklistTab() {
    if (_clothingItems.isEmpty) {
      return const Center(child: Text("No items found or failed to load."));
    }

    return CustomScrollView(
      slivers: [
        if (_generatedWardrobe?.reasoning.isNotEmpty ?? false)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 12),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 16, color: Colors.amber[800]),
                          const SizedBox(width: 8),
                          Text(
                            "STYLIST'S SECRET",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.amber[900],
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _generatedWardrobe!.reasoning,
                        maxLines: _isStylistNoteExpanded ? null : 3,
                        overflow: _isStylistNoteExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.grey[800],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _isStylistNoteExpanded = !_isStylistNoteExpanded;
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: Icon(
                            _isStylistNoteExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            size: 16,
                            color: Colors.amber[900],
                          ),
                          label: Text(
                            _isStylistNoteExpanded ? "Show Less" : "Read More",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[900],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 0.85,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = _clothingItems[index];
              final isPacked = _packedItemIds.contains(item['id']);

              return GestureDetector(
                onTap: () => _togglePacked(item['id']),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImageWidget(item['imageUrl']?.toString()),
                        if (isPacked)
                          Positioned.fill(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                              child: Container(
                                color: Colors.white.withOpacity(0.2),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                        child: const Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.green,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ],
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
            childCount: _clothingItems.length,
          ),
        ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildOutfitsTab() {
    if (_generatedWardrobe == null || _generatedWardrobe!.outfits.isEmpty) {
       return const Center(child: Text("No outfits generated."));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 40),
      physics: const BouncingScrollPhysics(),
      itemCount: _generatedWardrobe!.outfits.length,
      itemBuilder: (context, index) {
        final outfit = _generatedWardrobe!.outfits[index];
        final outfitItems = _clothingItems
            .where((item) => outfit.itemIds.contains(item['id']))
            .toList();

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Day ${index + 1}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      outfit.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                  ],
                ),
              ),
              if (outfitItems.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 20.0, bottom: 20.0, right: 20.0),
                  child: SizedBox(
                    height: 140,
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      itemCount: outfitItems.length,
                      itemBuilder: (context, idx) {
                        final itemInfo = outfitItems[idx];
                        return Row(
                          children: [
                            Container(
                              width: 110,
                              height: 130,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildImageWidget(itemInfo['imageUrl']?.toString()), 
                              ),
                            ),
                            if (idx != outfitItems.length - 1)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Icon(Icons.add, size: 16, color: Colors.grey[300]),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.grey[400], size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        outfit.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
