import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'widgets/selection_filter_chips.dart';
import 'widgets/selection_grid_item.dart';
import 'item_selection_view_model.dart';

const _kBlob1 = kGlowBlue;
const _kBlob2 = kGlowBlue2;

class ItemSelectionScreen extends StatelessWidget {
  final List<String> initialSelectedIds;

  const ItemSelectionScreen({super.key, required this.initialSelectedIds});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          ItemSelectionViewModel(initialSelectedIds: initialSelectedIds),
      child: const _ItemSelectionBody(),
    );
  }
}

class _ItemSelectionBody extends StatelessWidget {
  const _ItemSelectionBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ItemSelectionViewModel>();

    return Scaffold(
      backgroundColor: kBgColor,
      body: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: kBgColor)),
          Positioned(
            top: -80,
            right: -60,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kBlob1,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -60,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  width: 190,
                  height: 190,
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
                    right: 4,
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
                          'Select Items',
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, vm.selectedIds.toList()),
                        child: Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildContent(context, vm)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ItemSelectionViewModel vm) {
    if (vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blueGrey),
      );
    }
    if (vm.errorMessage != null) {
      return Center(
        child: Text(
          vm.errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    final filteredDocs = vm.filteredDocs;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectionFilterChips(
                allWardrobeItems: vm.allWardrobeItems.toList(),
                selectedCategory: vm.selectedCategory,
                selectedSubCategory: vm.selectedSubCategory,
                onCategoryChanged: vm.setCategory,
                onSubCategoryChanged: vm.setSubCategory,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        filteredDocs.isEmpty
            ? SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40.0),
                    child: Text(
                      'No available items match the criteria.',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4.0,
                        mainAxisSpacing: 6.0,
                        childAspectRatio: 0.75,
                      ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filteredDocs[index];
                      final id = item['id'] as String;
                      return SelectionGridItem(
                        key: ValueKey(id),
                        item: item,
                        isSelected: vm.selectedIds.contains(id),
                        onTap: () => vm.toggleSelection(id),
                      );
                    },
                    childCount: filteredDocs.length,
                  ),
                ),
              ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

