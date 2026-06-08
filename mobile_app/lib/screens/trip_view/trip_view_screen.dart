import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/navigation/app_routes.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'package:mobile_app/widgets/custom_snackbar.dart';
import 'package:mobile_app/screens/item_selection/item_selection_screen.dart';
import 'widgets/trip_skeleton_loader.dart';
import 'widgets/trip_suitcase_tab.dart';
import 'widgets/trip_outfits_tab.dart';
import 'trip_view_view_model.dart';

const _kBlob1 = kGlowBlue;
const _kBlob2 = kGlowBlue2;

class TripViewScreen extends StatelessWidget {
  final String? tripId;
  final String destination;
  final int days;
  final String vibe;
  final DateTimeRange? dateRange;
  final Map<String, dynamic>? initialTripData;
  final String? tripPlans;
  final String? luggageSize;

  const TripViewScreen({
    super.key,
    this.tripId,
    required this.destination,
    required this.days,
    required this.vibe,
    this.dateRange,
    this.initialTripData,
    this.tripPlans,
    this.luggageSize,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: ChangeNotifierProvider(
        create: (_) => TripViewViewModel(
          tripId: tripId,
          destination: destination,
          days: days,
          vibe: vibe,
          dateRange: dateRange,
          initialTripData: initialTripData,
          tripPlans: tripPlans,
          luggageSize: luggageSize,
        ),
        child: const _TripViewBody(),
      ),
    );
  }
}

class _TripViewBody extends StatelessWidget {
  const _TripViewBody();

  void _openItemSelection(BuildContext context) async {
    final vm = context.read<TripViewViewModel>();
    final newIds = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => ItemSelectionScreen(
          initialSelectedIds: List.from(vm.editableItemIds),
        ),
      ),
    );
    if (newIds != null && context.mounted) {
      vm.updateEditableItems(newIds);
    }
  }

  Future<void> _syncAndRestyle(BuildContext context) async {
    final vm = context.read<TripViewViewModel>();
    final error = await vm.syncAndRestyle();
    if (!context.mounted) return;
    if (error != null) {
      CustomSnackBar.showError(context, 'Failed to re-style trip: $error');
    } else {
      CustomSnackBar.showSuccess(context, 'Trip Re-styled locally!');
    }
  }

  Future<void> _saveTrip(BuildContext context) async {
    final vm = context.read<TripViewViewModel>();

    final String? name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SaveTripDialog(initialName: vm.destination),
    );

    if (name == null || name.isEmpty || !context.mounted) return;

    // Capture navigator reference BEFORE the await so we never call
    // .of(context) after the dialog-dismissal microtask, which is the
    // exact window where the framework was throwing the
    // "wrong build scope" / `_dependents.isEmpty` assertions.
    final navigator = Navigator.of(context);

    final saveError = await vm.saveTrip(name);
    if (!context.mounted) return;

    if (saveError != null) {
      CustomSnackBar.showError(context, 'Failed to save trip: $saveError');
      return;
    }

    CustomSnackBar.showSuccess(context, 'Trip saved successfully!');

    // Navigate to MyTrips and clear the setup + view screens from the stack.
    // pushNamedAndRemoveUntil tears down TripView's provider via normal route
    // lifecycle (safe, no notifyListeners against a mid-teardown subtree).
    navigator.pushNamedAndRemoveUntil(
      AppRoutes.trips,
      (route) => route.isFirst,
    );
  }

  Future<void> _updateTrip(BuildContext context) async {
    final vm = context.read<TripViewViewModel>();
    final error = await vm.updateTrip();
    if (!context.mounted) return;
    if (error != null) {
      CustomSnackBar.showError(context, 'Failed to update trip: $error');
    } else {
      CustomSnackBar.showSuccess(context, 'Trip updated successfully!');
    }
  }

  Future<void> _editDayOutfit(BuildContext context, int index) async {
    final vm = context.read<TripViewViewModel>();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => const _EditOutfitDialog(),
    );
    if (result == null || result.isEmpty || !context.mounted) return;
    final error = await vm.editDayOutfit(index, result);
    if (!context.mounted) return;
    if (error != null) {
      CustomSnackBar.showError(context, 'Failed to update outfit: $error');
    } else {
      CustomSnackBar.showSuccess(context, 'Outfit updated successfully!');
    }
  }

  Future<void> _addAdHocOutfit(BuildContext context, String contextPlan) async {
    final vm = context.read<TripViewViewModel>();
    final error = await vm.addAdHocOutfit(contextPlan);
    if (error != null && context.mounted) {
      CustomSnackBar.showError(context, 'Failed to add outfit: $error');
    }
  }

  Widget _buildErrorBody(BuildContext context, TripViewViewModel vm) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - v)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kDanger.withOpacity(0.06),
                    border: Border.all(
                      color: kDanger.withOpacity(0.14),
                      width: 1.5,
                    ),
                  ),
                ),
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kDanger.withOpacity(0.08),
                  ),
                ),
                const Icon(
                  CupertinoIcons.xmark_circle,
                  color: kDanger,
                  size: 34,
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Could not generate packing list',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              vm.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black.withOpacity(0.45),
                height: 1.55,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: vm.retryGenerate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: kBlueBright.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: kBlueBright.withOpacity(0.35),
                    width: 1.5,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.arrow_clockwise,
                      color: kBlueAccent,
                      size: 17,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kBlueAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context, TripViewViewModel vm) {
    final bool hasChanges =
        vm.editableItemIds.length != vm.lastSyncedItemIds.length ||
        !vm.editableItemIds.every((id) => vm.lastSyncedItemIds.contains(id));

    if (vm.isSyncing) {
      return const FloatingActionButton.extended(
        onPressed: null,
        icon: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
        label: Text("Syncing..."),
      );
    }
    if (hasChanges) {
      return FloatingActionButton.extended(
        onPressed: () => _syncAndRestyle(context),
        icon: const Icon(Icons.sync),
        label: const Text("Sync & Re-style"),
        backgroundColor: Colors.blueAccent,
      );
    }
    if (vm.wardrobe != null && !vm.isLoading) {
      if (vm.currentTripId == null) {
        return FloatingActionButton.extended(
          onPressed: () => _saveTrip(context),
          icon: const Icon(Icons.bookmark_add),
          label: const Text("Save Trip"),
        );
      }
      bool hasUnsavedDatabaseChanges = false;
      if (vm.initialTripData != null) {
        final initialDbIds = List<String>.from(
          vm.initialTripData!['item_ids'] ?? [],
        );
        hasUnsavedDatabaseChanges =
            vm.lastSyncedItemIds.length != initialDbIds.length ||
            !vm.lastSyncedItemIds.every((id) => initialDbIds.contains(id)) ||
            vm.hasUnsavedChanges;
      } else {
        hasUnsavedDatabaseChanges = vm.hasUnsavedChanges;
      }
      if (hasUnsavedDatabaseChanges) {
        return FloatingActionButton.extended(
          onPressed: () => _updateTrip(context),
          icon: const Icon(Icons.update),
          label: const Text("Update Trip"),
        );
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildBodyContent(BuildContext context, TripViewViewModel vm) {
    if (vm.isLoading) return const TripSkeletonLoader();
    if (vm.errorMessage != null) return _buildErrorBody(context, vm);
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
      child: TabBarView(
        children: [
          TripSuitcaseTab(
            clothingItems: vm.clothingItems,
            wardrobe: vm.wardrobe,
            isEditMode: vm.isEditMode,
            isStylistNoteExpanded: vm.isStylistNoteExpanded,
            onToggleStylistNote: vm.toggleStylistNote,
            onOpenItemSelection: () => _openItemSelection(context),
            onRemoveItem: vm.removeItem,
          ),
          TripOutfitsTab(
            wardrobe: vm.wardrobe,
            clothingItems: vm.clothingItems,
            loadingOutfitIndices: vm.loadingOutfitIndices,
            isAddingAdHocOutfit: vm.isAddingAdHocOutfit,
            adHocOutfitController: vm.adHocOutfitController,
            onEditDayOutfit: (index) => _editDayOutfit(context, index),
            onAddAdHocOutfit: (plan) => _addAdHocOutfit(context, plan),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Read immutable trip metadata once. The widget itself does NOT watch
    // the VM — provider notifications are scoped to the Consumer leaves
    // below so the NestedScrollView/TabBarView skeleton never reconciles
    // in response to notifyListeners(), which is what was causing the
    // cross-build-scope assertion during saveTrip().
    final tripMeta = context.read<TripViewViewModel>();

    return Scaffold(
      backgroundColor: kBgColor,
      floatingActionButton: Consumer<TripViewViewModel>(
        builder: (context, vm, _) => _buildFab(context, vm),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: kBgColor)),
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
            bottom: true,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    floating: false,
                    pinned: true,
                    toolbarHeight: 80.0,
                    expandedHeight: 130.0,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    centerTitle: true,
                    leading: IconButton(
                      icon: const Icon(
                        CupertinoIcons.back,
                        color: Colors.black87,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    flexibleSpace: Stack(
                      children: [
                        const Positioned.fill(
                          child: ColoredBox(color: kBgColor),
                        ),
                        Positioned(
                          top: -60,
                          right: -50,
                          child: IgnorePointer(
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: 50,
                                sigmaY: 50,
                              ),
                              child: Container(
                                width: 240,
                                height: 240,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _kBlob1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      Consumer<TripViewViewModel>(
                        builder: (context, vm, _) {
                          if (vm.isLoading) return const SizedBox.shrink();
                          return TextButton(
                            onPressed: vm.toggleEditMode,
                            child: Text(
                              vm.isEditMode ? "Cancel" : "Edit",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 17),
                        Text(
                          tripMeta.destination,
                          style: TextStyle(
                            fontSize: 22.0,
                            fontWeight: FontWeight.w900,
                            color: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${tripMeta.days} Days • ${tripMeta.vibe}",
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
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      tabs: const [
                        Tab(icon: Icon(Icons.luggage), text: "Suitcase"),
                        Tab(icon: Icon(Icons.style), text: "Daily Outfits"),
                      ],
                    ),
                  ),
                ];
              },
              body: Consumer<TripViewViewModel>(
                builder: (context, vm, _) => _buildBodyContent(context, vm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditOutfitDialog extends StatefulWidget {
  const _EditOutfitDialog();

  @override
  State<_EditOutfitDialog> createState() => _EditOutfitDialogState();
}

class _EditOutfitDialogState extends State<_EditOutfitDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Tweak this outfit"),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: "What would you like to change?",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
        ),
        maxLines: 2,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isNotEmpty) Navigator.pop(context, text);
          },
          child: const Text("Update"),
        ),
      ],
    );
  }
}

// Owns its own TextEditingController so Flutter disposes it only when the
// dialog widget is fully unmounted. Manually disposing the controller
// right after showDialog() returns is what was actually causing the
// "_dependents.isEmpty" / "wrong build scope" crash cascade — the
// dialog's TextField was still being rebuilt during the dismiss
// animation and tried to read from a disposed controller.
class _SaveTripDialog extends StatefulWidget {
  final String initialName;
  const _SaveTripDialog({required this.initialName});

  @override
  State<_SaveTripDialog> createState() => _SaveTripDialogState();
}

class _SaveTripDialogState extends State<_SaveTripDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Save Trip"),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(labelText: "Trip Name"),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isNotEmpty) Navigator.pop(context, text);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}

