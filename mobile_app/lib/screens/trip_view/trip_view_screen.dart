import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/services/packing_service.dart';
import 'package:mobile_app/services/weather_service.dart';
import 'package:mobile_app/services/wardrobe_state_service.dart';
import 'package:mobile_app/services/firebase_service.dart';
import 'package:mobile_app/screens/item_selection/item_selection_screen.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'widgets/trip_skeleton_loader.dart';
import 'widgets/trip_suitcase_tab.dart';
import 'widgets/trip_outfits_tab.dart';

const _kBlob1 = Color(0x3840C4FF);
const _kBlob2 = Color(0x1E1565C0);

class TripViewScreen extends StatefulWidget {
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
  State<TripViewScreen> createState() => _TripViewScreenState();
}

class _TripViewScreenState extends State<TripViewScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _clothingItems = [];
  List<String> _editableItemIds = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSyncing = false;
  bool _isEditMode = false;
  CapsuleWardrobe? _wardrobe;
  bool _isStylistNoteExpanded = false;
  bool _hasUnsavedChanges = false;
  final Set<int> _loadingOutfitIndices = {};
  bool _isAddingAdHocOutfit = false;
  final TextEditingController _adHocOutfitController = TextEditingController();

  List<String> _lastSyncedItemIds = [];
  String? _currentTripId;

  @override
  void initState() {
    super.initState();
    _currentTripId = widget.tripId;
    if (_currentTripId != null && widget.initialTripData != null) {
      _loadSavedTrip();
    } else {
      _hasUnsavedChanges = true;
      _generateWardrobe();
    }
  }

  @override
  void dispose() {
    _adHocOutfitController.dispose();
    super.dispose();
  }

  void _loadSavedTrip() {
    final data = widget.initialTripData!;
    var outfitsList = data['outfits'] as List? ?? [];
    List<TripOutfit> parsedOutfits = outfitsList
        .map(
          (outfitJson) =>
              TripOutfit.fromJson(outfitJson as Map<String, dynamic>),
        )
        .toList();

    _wardrobe = CapsuleWardrobe(
      selectedItemIds: List<String>.from(data['item_ids'] ?? []),
      reasoning: data['reasoning'] as String? ?? '',
      warningMessage: data['warning_message'] as String?,
      outfits: parsedOutfits,
    );
    _editableItemIds = List<String>.from(_wardrobe!.selectedItemIds);
    _lastSyncedItemIds = List<String>.from(_editableItemIds);
    _fetchItems();
  }

  Future<void> _generateWardrobe() async {
    try {
      final weatherSummary = widget.dateRange != null
          ? await WeatherService().getTripWeatherSummary(
              widget.destination,
              widget.dateRange!.start,
              widget.dateRange!.end,
            )
          : 'Unknown Weather';

      final wardrobe = await PackingService().generatePackingList(
        destination: widget.destination,
        days: widget.days,
        vibe: widget.vibe,
        weatherForecast: weatherSummary,
        wardrobeId: wardrobeStateService.activeWardrobeId,
        tripPlans: widget.tripPlans,
        luggageSize: widget.luggageSize,
      );

      if (mounted) {
        setState(() {
          _wardrobe = wardrobe;
          _editableItemIds = List<String>.from(wardrobe.selectedItemIds);
          _lastSyncedItemIds = List<String>.from(_editableItemIds);
        });
        _fetchItems();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _fetchItems() async {
    if (_editableItemIds.isEmpty) {
      if (mounted) {
        setState(() {
          _clothingItems = [];
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final items = await FirebaseService().getItemsByIds(_editableItemIds);
      if (mounted) {
        setState(() {
          _clothingItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _openItemSelection() async {
    final newIds = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ItemSelectionScreen(initialSelectedIds: _editableItemIds),
      ),
    );

    if (newIds != null) {
      setState(() {
        _editableItemIds = newIds;
      });
      _fetchItems();
    }
  }

  void _removeItem(String id) {
    setState(() {
      _editableItemIds.remove(id);
    });
    _fetchItems();
  }

  Future<void> _syncAndRestyle() async {
    setState(() => _isSyncing = true);
    try {
      final weatherSummary = widget.dateRange != null
          ? await WeatherService().getTripWeatherSummary(
              widget.destination,
              widget.dateRange!.start,
              widget.dateRange!.end,
            )
          : 'Unknown Weather';

      final wardrobe = await PackingService().generatePackingList(
        destination: widget.destination,
        days: widget.days,
        vibe: widget.vibe,
        weatherForecast: weatherSummary,
        itemIdsOverride: _editableItemIds,
        tripPlans: widget.tripPlans ?? widget.initialTripData?['trip_plans'],
        luggageSize:
            widget.luggageSize ?? widget.initialTripData?['luggage_size'],
      );

      if (mounted) {
        setState(() {
          _wardrobe = wardrobe;
          _editableItemIds = List<String>.from(wardrobe.selectedItemIds);
          _lastSyncedItemIds = List<String>.from(_editableItemIds);
          _isEditMode = false;
          _isSyncing = false;
          _hasUnsavedChanges = true;
        });
        _fetchItems();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Trip Re-styled locally!")),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSyncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to re-style trip: $e")),
        );
      }
    }
  }

  Future<void> _saveTrip() async {
    if (_wardrobe == null) return;

    String tripName = widget.destination;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: tripName);
        return AlertDialog(
          title: const Text("Save Trip"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: "Trip Name"),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final outfitsList =
            _wardrobe!.outfits.map((o) => o.toJson()).toList();
        final newTripId = await FirebaseService().saveTrip(
          name: result,
          destination: widget.destination,
          itemIds: _wardrobe!.selectedItemIds,
          outfits: outfitsList,
          reasoning: _wardrobe!.reasoning,
          vibe: widget.vibe,
          tripPlans: widget.tripPlans,
          luggageSize: widget.luggageSize,
          startDate: widget.dateRange?.start,
          endDate: widget.dateRange?.end,
        );
        if (mounted) {
          setState(() {
            _currentTripId = newTripId;
            _hasUnsavedChanges = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Trip saved successfully!")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to save trip: $e")),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateTrip({
    String? successMessage,
    bool showGlobalLoader = true,
  }) async {
    if (_wardrobe == null || _currentTripId == null) return;

    if (showGlobalLoader) {
      setState(() => _isLoading = true);
    }
    try {
      final outfitsList =
          _wardrobe!.outfits.map((o) => o.toJson()).toList();
      await FirebaseService().updateTrip(
        _currentTripId!,
        _wardrobe!.selectedItemIds,
        outfitsList,
        _wardrobe!.reasoning,
        vibe: widget.vibe,
        tripPlans: widget.tripPlans ?? widget.initialTripData?['trip_plans'],
        luggageSize:
            widget.luggageSize ?? widget.initialTripData?['luggage_size'],
        startDate: widget.dateRange?.start,
        endDate: widget.dateRange?.end,
      );
      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage ?? "Trip updated successfully!"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update trip: $e")),
        );
      }
    } finally {
      if (mounted && showGlobalLoader) setState(() => _isLoading = false);
    }
  }

  Future<void> _editDayOutfit(int index) async {
    final outfit = _wardrobe!.outfits[index];
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Tweak this outfit"),
          content: TextField(
            controller: controller,
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
              onPressed: () =>
                  Navigator.pop(context, controller.text.trim()),
              child: const Text("Update"),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _loadingOutfitIndices.add(index));
      try {
        final weatherSummary = widget.dateRange != null
            ? await WeatherService().getTripWeatherSummary(
                widget.destination,
                widget.dateRange!.start,
                widget.dateRange!.end,
              )
            : 'Unknown Weather';

        final existingOutfits = <Map<String, dynamic>>[];
        for (int i = 0; i < _wardrobe!.outfits.length; i++) {
          if (i != index) {
            existingOutfits.add({
              'context': _wardrobe!.outfits[i].title,
              'used_item_ids': _wardrobe!.outfits[i].itemIds,
            });
          }
        }

        final newOutfit = await PackingService().generateSpecificTripOutfit(
          destination: widget.destination,
          vibe: widget.vibe,
          weatherForecast: weatherSummary,
          suitcaseItemIds: _editableItemIds,
          userContext: outfit.title,
          existingOutfits: existingOutfits,
          feedback: result,
          currentOutfitItemIds: outfit.itemIds,
        );

        if (mounted) {
          setState(() {
            _wardrobe!.outfits[index] = newOutfit;
            _hasUnsavedChanges = true;
          });

          if (_currentTripId != null) {
            await _updateTrip(
              successMessage: "Outfit updated successfully!",
              showGlobalLoader: false,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Outfit updated successfully!")),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to update outfit: $e")),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _loadingOutfitIndices.remove(index));
        }
      }
    }
  }

  Future<void> _addAdHocOutfit(String contextPlan) async {
    if (contextPlan.isEmpty) return;

    setState(() => _isAddingAdHocOutfit = true);
    try {
      final weatherSummary = widget.dateRange != null
          ? await WeatherService().getTripWeatherSummary(
              widget.destination,
              widget.dateRange!.start,
              widget.dateRange!.end,
            )
          : 'Unknown Weather';

      final existingOutfits = _wardrobe!.outfits
          .map((o) => {'context': o.title, 'used_item_ids': o.itemIds})
          .toList();

      final newOutfit = await PackingService().generateSpecificTripOutfit(
        destination: widget.destination,
        vibe: widget.vibe,
        weatherForecast: weatherSummary,
        suitcaseItemIds: _editableItemIds,
        userContext: contextPlan,
        existingOutfits: existingOutfits,
      );

      if (mounted) {
        setState(() {
          _wardrobe!.outfits.add(newOutfit);
          _hasUnsavedChanges = true;
          _adHocOutfitController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add outfit: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingAdHocOutfit = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasChanges =
        _editableItemIds.length != _lastSyncedItemIds.length ||
        !_editableItemIds.every((id) => _lastSyncedItemIds.contains(id));

    Widget? fab;
    if (_isSyncing) {
      fab = const FloatingActionButton.extended(
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
    } else if (hasChanges) {
      fab = FloatingActionButton.extended(
        onPressed: _syncAndRestyle,
        icon: const Icon(Icons.sync),
        label: const Text("Sync & Re-style"),
        backgroundColor: Colors.blueAccent,
      );
    } else if (_wardrobe != null && !_isLoading) {
      if (_currentTripId == null) {
        fab = FloatingActionButton.extended(
          onPressed: _saveTrip,
          icon: const Icon(Icons.bookmark_add),
          label: const Text("Save Trip"),
        );
      } else {
        bool hasUnsavedDatabaseChanges = false;
        if (widget.initialTripData != null) {
          List<String> initialDbIds = List<String>.from(
            widget.initialTripData!['item_ids'] ?? [],
          );
          hasUnsavedDatabaseChanges =
              _lastSyncedItemIds.length != initialDbIds.length ||
              !_lastSyncedItemIds.every((id) => initialDbIds.contains(id)) ||
              _hasUnsavedChanges;
        } else {
          hasUnsavedDatabaseChanges = _hasUnsavedChanges;
        }

        if (hasUnsavedDatabaseChanges) {
          fab = FloatingActionButton.extended(
            onPressed: _updateTrip,
            icon: const Icon(Icons.update),
            label: const Text("Update Trip"),
          );
        }
      }
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kBgColor,
        floatingActionButton: fab,
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
                          Positioned.fill(
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
                        if (!_isLoading)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isEditMode = !_isEditMode;
                                if (!_isEditMode) {
                                  _editableItemIds = List<String>.from(
                                    _lastSyncedItemIds,
                                  );
                                  _fetchItems();
                                }
                              });
                            },
                            child: Text(
                              _isEditMode ? "Cancel" : "Edit",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
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
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        tabs: const [
                          Tab(
                            icon: Icon(Icons.luggage),
                            text: "Suitcase",
                          ),
                          Tab(
                            icon: Icon(Icons.style),
                            text: "Daily Outfits",
                          ),
                        ],
                      ),
                    ),
                  ];
                },
                body: _isLoading
                    ? const TripSkeletonLoader()
                    : _errorMessage != null
                        ? _buildErrorBody()
                        : Padding(
                        padding: const EdgeInsets.only(
                          top: 8.0,
                          bottom: 16.0,
                        ),
                        child: TabBarView(
                          children: [
                            TripSuitcaseTab(
                              clothingItems: _clothingItems,
                              wardrobe: _wardrobe,
                              isEditMode: _isEditMode,
                              isStylistNoteExpanded: _isStylistNoteExpanded,
                              onToggleStylistNote: () => setState(() =>
                                  _isStylistNoteExpanded =
                                      !_isStylistNoteExpanded),
                              onOpenItemSelection: _openItemSelection,
                              onRemoveItem: _removeItem,
                            ),
                            TripOutfitsTab(
                              wardrobe: _wardrobe,
                              clothingItems: _clothingItems,
                              loadingOutfitIndices: _loadingOutfitIndices,
                              isAddingAdHocOutfit: _isAddingAdHocOutfit,
                              adHocOutfitController: _adHocOutfitController,
                              onEditDayOutfit: _editDayOutfit,
                              onAddAdHocOutfit: _addAdHocOutfit,
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBody() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, v, child) =>
          Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child)),
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
                    color: const Color(0xFFDC2626).withOpacity(0.06),
                    border: Border.all(
                      color: const Color(0xFFDC2626).withOpacity(0.14),
                      width: 1.5,
                    ),
                  ),
                ),
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFDC2626).withOpacity(0.08),
                  ),
                ),
                const Icon(
                  CupertinoIcons.xmark_circle,
                  color: Color(0xFFDC2626),
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
              _errorMessage!,
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
              onTap: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _generateWardrobe();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF40C4FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF40C4FF).withOpacity(0.35),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(CupertinoIcons.arrow_clockwise, color: Color(0xFF1565C0), size: 17),
                    SizedBox(width: 8),
                    Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1565C0),
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
}
