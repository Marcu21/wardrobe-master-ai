import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'package:mobile_app/widgets/global_wardrobe_selector.dart';
import 'laundry_view_model.dart';
import 'widgets/animated_alert.dart';
import 'widgets/laundry_splits_modal.dart';
import 'widgets/laundry_status_banner.dart';
import 'widgets/virtual_basket_view.dart';
import 'widgets/wardrobe_filter_chips.dart';
import 'widgets/wardrobe_grid_item.dart';
import 'package:mobile_app/services/laundry_service.dart';

const _kBlob1 = Color(0x384F46E5);
const _kBlob2 = Color(0x206352D2);

Widget _buildBlobBackground() {
  return Stack(
    children: [
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
    ],
  );
}

class LaundryScreen extends StatelessWidget {
  const LaundryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LaundryViewModel(),
      child: const _LaundryBody(),
    );
  }
}

class _LaundryBody extends StatelessWidget {
  const _LaundryBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LaundryViewModel>();

    if (vm.isLoading) {
      return Scaffold(
        backgroundColor: kBgColor,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            'Smart Laundry',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Stack(
          children: [
            _buildBlobBackground(),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blueGrey.withOpacity(0.07),
                          border: Border.all(
                            color: Colors.blueGrey.withOpacity(0.15),
                            width: 1.5,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 46,
                        height: 46,
                        child: CircularProgressIndicator(
                          color: Colors.blueGrey.withOpacity(0.25),
                          strokeWidth: 1.5,
                        ),
                      ),
                      const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          color: Colors.blueGrey,
                          strokeWidth: 2.5,
                        ),
                      ),
                      const Icon(
                        CupertinoIcons.sparkles,
                        color: Colors.blueGrey,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Loading wardrobe…',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Getting your items ready',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black45,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (vm.errorMessage != null) {
      return Scaffold(
        backgroundColor: kBgColor,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            'Smart Laundry',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Stack(
          children: [
            _buildBlobBackground(),
            Center(
              child: Text(
                vm.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }

    final result = vm.analysisResult;
    final basketItems = vm.basketItems;

    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    String statusSubtitle;

    if (basketItems.isEmpty) {
      statusColor = Colors.blueGrey;
      statusIcon = CupertinoIcons.sparkles;
      statusTitle = 'Ready to Wash';
      statusSubtitle = 'Add items from your wardrobe below';
    } else {
      switch (result.status) {
        case LaundryStatus.Safe:
          statusColor = const Color(0xFF16A34A);
          statusIcon = CupertinoIcons.checkmark_circle;
          statusTitle = 'Safe to Wash';
          statusSubtitle =
              '${basketItems.length} item${basketItems.length == 1 ? '' : 's'} in basket';
          break;
        case LaundryStatus.Warning:
          statusColor = const Color(0xFFD97706);
          statusIcon = CupertinoIcons.exclamationmark_triangle;
          statusTitle = 'Warning';
          statusSubtitle =
              '${basketItems.length} item${basketItems.length == 1 ? '' : 's'} — check alerts below';
          break;
        case LaundryStatus.Critical:
          statusColor = const Color(0xFFDC2626);
          statusIcon = CupertinoIcons.xmark_circle;
          statusTitle = 'Critical Issue';
          statusSubtitle =
              '${basketItems.length} item${basketItems.length == 1 ? '' : 's'} — cannot wash together';
          break;
      }
    }

    final filteredDocs = vm.filteredDocs;

    return Scaffold(
      backgroundColor: kBgColor,
      body: Stack(
        children: [
          _buildBlobBackground(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverAppBar(
                  pinned: false,
                  floating: false,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: true,
                  iconTheme: IconThemeData(color: Colors.black),
                  title: Text(
                    'Smart Laundry',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  actions: [GlobalWardrobeSelector(isActionItem: true)],
                ),

                SliverPersistentHeader(
                  pinned: true,
                  delegate: StatusHeaderDelegate(
                    height: 80.0,
                    child: LaundryStatusBanner(
                      statusColor: statusColor,
                      statusIcon: statusIcon,
                      statusTitle: statusTitle,
                      statusSubtitle: statusSubtitle,
                      recommendedTemp: result.recommendedTemp,
                      hasItems: basketItems.isNotEmpty,
                    ),
                  ),
                ),

                if (basketItems.isNotEmpty && result.alerts.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ...result.alerts.asMap().entries.map(
                              (entry) => AnimatedAlert(
                                key: ValueKey(entry.value),
                                alert: entry.value,
                                color: statusColor,
                                index: entry.key,
                              ),
                            ),
                            if (result.status == LaundryStatus.Warning ||
                                result.status == LaundryStatus.Critical)
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: GestureDetector(
                                    onTap: () => showLaundryAutoSplitModal(
                                      context,
                                      basketItems.toList(),
                                      vm.laundryService,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.85),
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(
                                          color: statusColor.withOpacity(0.30),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: statusColor.withOpacity(0.12),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.auto_awesome,
                                            color: statusColor,
                                            size: 15,
                                          ),
                                          const SizedBox(width: 7),
                                          Text(
                                            'Auto-Split Load',
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VirtualBasketView(
                        basketItems: basketItems.toList(),
                        statusColor: statusColor,
                        onRemove: vm.removeFromBasket,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MY WARDROBE',
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 3,
                                fontWeight: FontWeight.w600,
                                color: Colors.black.withOpacity(0.35),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Select to add to basket',
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
                      WardrobeFilterChips(
                        allWardrobeItems: vm.allWardrobeItems,
                        selectedCategory: vm.selectedCategory,
                        selectedSubCategory: vm.selectedSubCategory,
                        onCategoryChanged: vm.setCategory,
                        onSubCategoryChanged: vm.setSubCategory,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                filteredDocs.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 48.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    CupertinoIcons.tray,
                                    size: 32,
                                    color: Colors.black.withOpacity(0.25),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'No items match the filters',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black45,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                            childAspectRatio: 0.75,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = filteredDocs[index];
                              return WardrobeGridItem(
                                item: item,
                                onTap: () => vm.addToBasket(item),
                              );
                            },
                            childCount: filteredDocs.length,
                          ),
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
