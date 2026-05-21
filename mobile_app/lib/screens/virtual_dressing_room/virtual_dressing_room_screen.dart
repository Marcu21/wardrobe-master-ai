import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/widgets/save_outfit_dialog.dart';
import 'package:mobile_app/widgets/global_wardrobe_selector.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'widgets/clothing_carousel_row.dart';
import 'widgets/circle_icon_button.dart';
import 'widgets/layer_toggle.dart';
import 'virtual_dressing_room_view_model.dart';

const _kBlob1 = Color(0x38A855F7);
const _kBlob2 = Color(0x209333EA);

class VirtualDressingRoomScreen extends StatelessWidget {
  final List<String>? initialItemIds;

  const VirtualDressingRoomScreen({super.key, this.initialItemIds});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          VirtualDressingRoomViewModel(initialItemIds: initialItemIds),
      child: const _VirtualDressingRoomBody(),
    );
  }
}

class _VirtualDressingRoomBody extends StatelessWidget {
  const _VirtualDressingRoomBody();

  void _saveOutfit(BuildContext context) {
    final vm = context.read<VirtualDressingRoomViewModel>();
    final selectedIds = vm.getSelectedIds();
    if (selectedIds.isNotEmpty) {
      SaveOutfitDialog.show(context, itemIds: selectedIds, isAiGenerated: false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one item'),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _openLayersMenu(BuildContext context) {
    final vm = context.read<VirtualDressingRoomViewModel>();
    bool localOuter = vm.showOuterwear;
    bool localMid = vm.showMidwear;
    bool localTop = vm.showTops;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext sheetContext) {
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
                        value: localOuter,
                        onChanged: (v) {
                          setModalState(() => localOuter = v);
                          vm.setShowOuterwear(v);
                        },
                      ),
                      const SizedBox(height: 10),
                      LayerToggle(
                        icon: CupertinoIcons.thermometer,
                        label: 'Midwear',
                        subtitle: 'Hoodies & Sweaters',
                        value: localMid,
                        onChanged: (v) {
                          setModalState(() => localMid = v);
                          vm.setShowMidwear(v);
                        },
                      ),
                      const SizedBox(height: 10),
                      LayerToggle(
                        icon: Icons.dry_cleaning,
                        label: 'Tops',
                        subtitle: 'T-Shirts & Shirts',
                        value: localTop,
                        onChanged: (v) {
                          setModalState(() => localTop = v);
                          vm.setShowTops(v);
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
    final vm = context.watch<VirtualDressingRoomViewModel>();

    final int fOuter = vm.showOuterwear ? 4 : 0;
    final int fMid = vm.showMidwear ? 4 : 0;
    final int fTop = vm.showTops ? 3 : 0;
    const int fBot = 5;
    const int fShoe = 2;

    int activeLayers = 2;
    if (vm.showOuterwear) activeLayers++;
    if (vm.showMidwear) activeLayers++;
    if (vm.showTops) activeLayers++;

    final double vpBottoms = activeLayers <= 3 ? 0.75 : 0.60;
    final double vpTops = activeLayers <= 3 ? 0.65 : 0.50;
    final double vpMidwear = activeLayers <= 3 ? 0.75 : 0.60;
    final double vpOuterwear = activeLayers <= 3 ? 0.85 : 0.70;
    const double vpShoes = 0.5;

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
                        onTap: () => _openLayersMenu(context),
                      ),
                      const SizedBox(width: 8),
                      CircleIconButton(
                        icon: CupertinoIcons.checkmark_circle_fill,
                        isPrimary: true,
                        onTap: () => _saveOutfit(context),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
                Expanded(
                  child: vm.isLoading
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
                            Column(
                              children: [
                                if (fOuter + fMid + fTop > 0)
                                  Spacer(flex: fOuter + fMid + fTop),
                                Expanded(
                                  flex: fBot,
                                  child: ClothingCarouselRowInternal(
                                    key: ValueKey(vpBottoms),
                                    items: vm.bottoms,
                                    onIndexChanged: vm.setBottomsIndex,
                                    viewportFraction: vpBottoms,
                                  ),
                                ),
                                ClothingCarouselRow(
                                  key: ValueKey(vpShoes),
                                  items: vm.shoes,
                                  flex: fShoe,
                                  onIndexChanged: vm.setShoesIndex,
                                  alignment: Alignment.bottomCenter,
                                  viewportFraction: vpShoes,
                                ),
                              ],
                            ),
                            if (vm.showTops)
                              Column(
                                children: [
                                  if (fOuter + fMid > 0)
                                    Spacer(flex: fOuter + fMid),
                                  ClothingCarouselRow(
                                    key: ValueKey(vpTops),
                                    items: vm.tops,
                                    flex: fTop,
                                    onIndexChanged: vm.setTopsIndex,
                                    viewportFraction: vpTops,
                                  ),
                                  if (fBot + fShoe > 0)
                                    const Spacer(flex: fBot + fShoe),
                                ],
                              ),
                            if (vm.showMidwear)
                              Column(
                                children: [
                                  if (fOuter > 0) Spacer(flex: fOuter),
                                  ClothingCarouselRow(
                                    key: ValueKey(vpMidwear),
                                    items: vm.midwear,
                                    flex: fMid,
                                    onIndexChanged: vm.setMidwearIndex,
                                    viewportFraction: vpMidwear,
                                  ),
                                  if (fTop + fBot + fShoe > 0)
                                    Spacer(flex: fTop + fBot + fShoe),
                                ],
                              ),
                            if (vm.showOuterwear)
                              Column(
                                children: [
                                  ClothingCarouselRow(
                                    key: ValueKey(vpOuterwear),
                                    items: vm.outerwear,
                                    flex: fOuter,
                                    onIndexChanged: vm.setOuterwearIndex,
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
