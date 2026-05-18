import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/widgets/save_outfit_dialog.dart';
import 'package:mobile_app/widgets/global_wardrobe_selector.dart';
import 'package:mobile_app/services/wardrobe_state_service.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'widgets/clothing_carousel_row.dart';
import 'widgets/circle_icon_button.dart';
import 'widgets/layer_toggle.dart';

const _kBlob1 = Color(0x38A855F7);
const _kBlob2 = Color(0x209333EA);

class VirtualDressingRoomScreen extends StatefulWidget {
  final List<String>? initialItemIds;

  const VirtualDressingRoomScreen({super.key, this.initialItemIds});

  @override
  State<VirtualDressingRoomScreen> createState() =>
      _VirtualDressingRoomScreenState();
}

class _VirtualDressingRoomScreenState
    extends State<VirtualDressingRoomScreen> {
  final List<Map<String, dynamic>> _outerwear = [];
  final List<Map<String, dynamic>> _midwear = [];
  final List<Map<String, dynamic>> _tops = [];
  final List<Map<String, dynamic>> _bottoms = [];
  final List<Map<String, dynamic>> _shoes = [];

  int _outerwearIndex = 0;
  int _midwearIndex = 0;
  int _topsIndex = 0;
  int _bottomsIndex = 0;
  int _shoesIndex = 0;

  bool _showOuterwear = false;
  bool _showMidwear = false;
  bool _showTops = true;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    wardrobeStateService.addListener(_onWardrobeChanged);
    _fetchClothingItems();
  }

  @override
  void dispose() {
    wardrobeStateService.removeListener(_onWardrobeChanged);
    super.dispose();
  }

  void _onWardrobeChanged() {
    _fetchClothingItems();
  }

  Future<void> _fetchClothingItems() async {
    try {
      var query = FirebaseFirestore.instance
          .collection('clothing')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid);

      if (wardrobeStateService.activeWardrobeId != null) {
        query = query.where(
          'wardrobe_id',
          isEqualTo: wardrobeStateService.activeWardrobeId,
        );
      }

      final snapshot = await query.get();

      final List<Map<String, dynamic>> newOuterwear = [];
      final List<Map<String, dynamic>> newMidwear = [];
      final List<Map<String, dynamic>> newTops = [];
      final List<Map<String, dynamic>> newBottoms = [];
      final List<Map<String, dynamic>> newShoes = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;

        Map<String, dynamic> basicInfo = data['basic_info'] ?? {};
        String category = (basicInfo['category'] ?? '')
            .toString()
            .toLowerCase();
        String subCategory = (basicInfo['sub_category'] ?? '')
            .toString()
            .toLowerCase();

        if (category.contains('shoe') || category.contains('footwear')) {
          newShoes.add(data);
        } else if (category.contains('bottom') ||
            category.contains('pant') ||
            subCategory.contains('jean') ||
            subCategory.contains('short')) {
          newBottoms.add(data);
        } else if (category.contains('outerwear') ||
            subCategory.contains('jacket') ||
            subCategory.contains('coat')) {
          newOuterwear.add(data);
        } else if (category.contains('midwear') ||
            subCategory.contains('sweater') ||
            subCategory.contains('hoodie') ||
            subCategory.contains('cardigan')) {
          newMidwear.add(data);
        } else if (category.contains('top') ||
            subCategory.contains('shirt') ||
            subCategory.contains('t-shirt')) {
          newTops.add(data);
        } else {
          newTops.add(data);
        }
      }

      if (mounted) {
        setState(() {
          _outerwearIndex = 0;
          _midwearIndex = 0;
          _topsIndex = 0;
          _bottomsIndex = 0;
          _shoesIndex = 0;

          if (widget.initialItemIds != null &&
              widget.initialItemIds!.isNotEmpty) {
            _showOuterwear = false;
            _showMidwear = false;
            _showTops = false;

            int foundOuter = newOuterwear.indexWhere(
              (item) => widget.initialItemIds!.contains(item['id']),
            );
            if (foundOuter != -1) {
              final item = newOuterwear.removeAt(foundOuter);
              newOuterwear.insert(0, item);
              _showOuterwear = true;
            }

            int foundMid = newMidwear.indexWhere(
              (item) => widget.initialItemIds!.contains(item['id']),
            );
            if (foundMid != -1) {
              final item = newMidwear.removeAt(foundMid);
              newMidwear.insert(0, item);
              _showMidwear = true;
            }

            int foundTop = newTops.indexWhere(
              (item) => widget.initialItemIds!.contains(item['id']),
            );
            if (foundTop != -1) {
              final item = newTops.removeAt(foundTop);
              newTops.insert(0, item);
              _showTops = true;
            }

            int foundBottom = newBottoms.indexWhere(
              (item) => widget.initialItemIds!.contains(item['id']),
            );
            if (foundBottom != -1) {
              final item = newBottoms.removeAt(foundBottom);
              newBottoms.insert(0, item);
            }

            int foundShoe = newShoes.indexWhere(
              (item) => widget.initialItemIds!.contains(item['id']),
            );
            if (foundShoe != -1) {
              final item = newShoes.removeAt(foundShoe);
              newShoes.insert(0, item);
            }
          } else {
            _showTops = true;
            _showOuterwear = false;
            _showMidwear = false;
          }

          _outerwear.clear();
          _midwear.clear();
          _tops.clear();
          _bottoms.clear();
          _shoes.clear();

          _outerwear.addAll(newOuterwear);
          _midwear.addAll(newMidwear);
          _tops.addAll(newTops);
          _bottoms.addAll(newBottoms);
          _shoes.addAll(newShoes);

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching clothing: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _saveOutfit() {
    final selectedIds = <String>[];

    if (_showOuterwear && _outerwear.isNotEmpty) {
      selectedIds.add(_outerwear[_outerwearIndex]['id']);
    }
    if (_showMidwear && _midwear.isNotEmpty) {
      selectedIds.add(_midwear[_midwearIndex]['id']);
    }
    if (_showTops && _tops.isNotEmpty) {
      selectedIds.add(_tops[_topsIndex]['id']);
    }
    if (_bottoms.isNotEmpty) {
      selectedIds.add(_bottoms[_bottomsIndex]['id']);
    }
    if (_shoes.isNotEmpty) {
      selectedIds.add(_shoes[_shoesIndex]['id']);
    }

    if (selectedIds.isNotEmpty) {
      SaveOutfitDialog.show(
        context,
        itemIds: selectedIds,
        isAiGenerated: false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one item'),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _openLayersMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    MediaQuery.of(context).padding.bottom + 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(top: 12, bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const Text(
                        'LAYERS',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 4.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Manage outfit layers',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const SizedBox(height: 20),
                      LayerToggle(
                        icon: CupertinoIcons.umbrella,
                        label: 'Outerwear',
                        subtitle: 'Jackets & Coats',
                        value: _showOuterwear,
                        onChanged: (v) {
                          setModalState(() => _showOuterwear = v);
                          setState(() => _showOuterwear = v);
                        },
                      ),
                      const SizedBox(height: 10),
                      LayerToggle(
                        icon: CupertinoIcons.thermometer,
                        label: 'Midwear',
                        subtitle: 'Hoodies & Sweaters',
                        value: _showMidwear,
                        onChanged: (v) {
                          setModalState(() => _showMidwear = v);
                          setState(() => _showMidwear = v);
                        },
                      ),
                      const SizedBox(height: 10),
                      LayerToggle(
                        icon: Icons.dry_cleaning,
                        label: 'Tops',
                        subtitle: 'T-Shirts & Shirts',
                        value: _showTops,
                        onChanged: (v) {
                          setModalState(() => _showTops = v);
                          setState(() => _showTops = v);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int fOuter = _showOuterwear ? 4 : 0;
    int fMid = _showMidwear ? 4 : 0;
    int fTop = _showTops ? 3 : 0;
    int fBot = 5;
    int fShoe = 2;

    int activeLayers = 2;
    if (_showOuterwear) activeLayers++;
    if (_showMidwear) activeLayers++;
    if (_showTops) activeLayers++;

    double vpBottoms = activeLayers <= 3 ? 0.75 : 0.60;
    double vpTops = activeLayers <= 3 ? 0.65 : 0.50;
    double vpMidwear = activeLayers <= 3 ? 0.75 : 0.60;
    double vpOuterwear = activeLayers <= 3 ? 0.85 : 0.70;
    double vpShoes = activeLayers <= 3 ? 0.5 : 0.5;

    return Scaffold(
      backgroundColor: kBgColor,
      body: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: kBgColor)),
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
                    right: 12,
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
                      const Expanded(child: GlobalWardrobeSelector()),
                      CircleIconButton(
                        icon: CupertinoIcons.layers_alt,
                        onTap: _openLayersMenu,
                      ),
                      const SizedBox(width: 8),
                      CircleIconButton(
                        icon: CupertinoIcons.checkmark_circle_fill,
                        isPrimary: true,
                        onTap: _saveOutfit,
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? Center(
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
                                      color: Colors.deepPurple.withOpacity(
                                        0.07,
                                      ),
                                      border: Border.all(
                                        color: Colors.deepPurple.withOpacity(
                                          0.15,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 52,
                                    height: 52,
                                    child: CircularProgressIndicator(
                                      color: Colors.deepPurple.withOpacity(
                                        0.25,
                                      ),
                                      strokeWidth: 1.5,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: CircularProgressIndicator(
                                      color: Colors.deepPurple,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                  const Icon(
                                    CupertinoIcons.wand_stars,
                                    color: Colors.deepPurple,
                                    size: 18,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Loading your wardrobe…',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Preparing your dressing room',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black45,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Stack(
                          children: [
                            // LAYER 1: Bottoms & Shoes
                            Column(
                              children: [
                                if (fOuter + fMid + fTop > 0)
                                  Spacer(flex: fOuter + fMid + fTop),
                                Expanded(
                                  flex: fBot,
                                  child: ClothingCarouselRowInternal(
                                    key: ValueKey(vpBottoms),
                                    items: _bottoms,
                                    onIndexChanged: (index) =>
                                        _bottomsIndex = index,
                                    viewportFraction: vpBottoms,
                                  ),
                                ),
                                ClothingCarouselRow(
                                  key: ValueKey(vpShoes),
                                  items: _shoes,
                                  flex: fShoe,
                                  onIndexChanged: (index) =>
                                      _shoesIndex = index,
                                  alignment: Alignment.bottomCenter,
                                  viewportFraction: vpShoes,
                                ),
                              ],
                            ),

                            // LAYER 2: Tops
                            if (_showTops)
                              Column(
                                children: [
                                  if (fOuter + fMid > 0)
                                    Spacer(flex: fOuter + fMid),
                                  ClothingCarouselRow(
                                    key: ValueKey(vpTops),
                                    items: _tops,
                                    flex: fTop,
                                    onIndexChanged: (index) =>
                                        _topsIndex = index,
                                    viewportFraction: vpTops,
                                  ),
                                  if (fBot + fShoe > 0)
                                    Spacer(flex: fBot + fShoe),
                                ],
                              ),

                            // LAYER 3: Midwear
                            if (_showMidwear)
                              Column(
                                children: [
                                  if (fOuter > 0) Spacer(flex: fOuter),
                                  ClothingCarouselRow(
                                    key: ValueKey(vpMidwear),
                                    items: _midwear,
                                    flex: fMid,
                                    onIndexChanged: (index) =>
                                        _midwearIndex = index,
                                    viewportFraction: vpMidwear,
                                  ),
                                  if (fTop + fBot + fShoe > 0)
                                    Spacer(flex: fTop + fBot + fShoe),
                                ],
                              ),

                            // LAYER 4: Outerwear
                            if (_showOuterwear)
                              Column(
                                children: [
                                  ClothingCarouselRow(
                                    key: ValueKey(vpOuterwear),
                                    items: _outerwear,
                                    flex: fOuter,
                                    onIndexChanged: (index) =>
                                        _outerwearIndex = index,
                                    viewportFraction: vpOuterwear,
                                  ),
                                  if (fMid + fTop + fBot + fShoe > 0)
                                    Spacer(flex: fMid + fTop + fBot + fShoe),
                                ],
                              ),
                          ],
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
