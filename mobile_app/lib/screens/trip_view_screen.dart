import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../services/packing_service.dart';
import '../services/weather_service.dart';
import '../services/wardrobe_state_service.dart';
import '../services/firebase_service.dart';
import 'item_selection_screen.dart';
import '../utils/outfit_sorting_utils.dart';
import '../widgets/smart_clothing_image.dart';

const _kBgColor = Color(0xFFF4F3F0);
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
      print('Error generating wardrobe: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
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
      print("Error fetching items: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to re-style trip: $e")));
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
        final outfitsList = _wardrobe!.outfits.map((o) => o.toJson()).toList();
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Failed to save trip: $e")));
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
      final outfitsList = _wardrobe!.outfits.map((o) => o.toJson()).toList();
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to update trip: $e")));
      }
    } finally {
      if (mounted && showGlobalLoader) setState(() => _isLoading = false);
    }
  }

  Widget _buildSkeletonLoader() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Building your capsule wardrobe…",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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
        backgroundColor: _kBgColor,
        floatingActionButton: fab,
        body: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: _kBgColor)),
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
                            Positioned.fill(child: ColoredBox(color: _kBgColor)),
                            Positioned(
                              top: -60,
                              right: -50,
                              child: IgnorePointer(
                                child: ImageFiltered(
                                  imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
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
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          tabs: const [
                            Tab(icon: Icon(Icons.luggage), text: "Suitcase"),
                            Tab(icon: Icon(Icons.style), text: "Daily Outfits"),
                          ],
                        ),
                      ),
                    ];
                  },
                  body: _isLoading
                      ? _buildSkeletonLoader()
                      : Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                          child: TabBarView(
                            children: [_buildChecklistTab(), _buildOutfitsTab()],
                          ),
                        ),
                ),
              ),
          ],
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
        if (_wardrobe?.warningMessage != null &&
            _wardrobe!.warningMessage!.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _wardrobe!.warningMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (_isEditMode)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Suitcase Items",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _openItemSelection,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Items"),
                  ),
                ],
              ),
            ),
          ),
        if (_wardrobe?.reasoning.isNotEmpty ?? false)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: 12,
              ),
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
                          Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: Colors.amber[800],
                          ),
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
                        _wardrobe!.reasoning,
                        maxLines: _isStylistNoteExpanded ? null : 3,
                        overflow: _isStylistNoteExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
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
                            _isStylistNoteExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
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
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = _clothingItems[index];

              return Container(
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
                      SmartClothingImage(
                        imageUrl: item['imageUrl']?.toString(),
                      ),
                      if (_isEditMode)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeItem(item['id']),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.redAccent,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }, childCount: _clothingItems.length),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
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
              onPressed: () => Navigator.pop(context, controller.text.trim()),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to add outfit: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingAdHocOutfit = false);
      }
    }
  }

  Widget _buildOutfitsTab() {
    if (_wardrobe == null || _wardrobe!.outfits.isEmpty) {
      return const Center(child: Text("No outfits generated."));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
      physics: const BouncingScrollPhysics(),
      itemCount: _wardrobe!.outfits.length + 1,
      itemBuilder: (context, index) {
        if (index == _wardrobe!.outfits.length) {
          return Container(
            margin: const EdgeInsets.only(top: 8, bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Add another outfit",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _adHocOutfitController,
                          enabled: !_isAddingAdHocOutfit,
                          decoration: const InputDecoration(
                            hintText: "Need an outfit for a specific occasion?",
                            hintStyle: TextStyle(fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          onSubmitted: (val) => _addAdHocOutfit(val),
                        ),
                      ),
                      _isAddingAdHocOutfit
                          ? const Padding(
                              padding: EdgeInsets.all(14.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: Icon(
                                Icons.send_rounded,
                                color: Theme.of(context).primaryColor,
                              ),
                              onPressed: () => _addAdHocOutfit(
                                _adHocOutfitController.text.trim(),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final outfit = _wardrobe!.outfits[index];
        final outfitItems = _clothingItems
            .where((item) => outfit.itemIds.contains(item['id']))
            .toList();

        OutfitSortingUtils.sortOutfitItems(outfitItems);

        final isLoading = _loadingOutfitIndices.contains(index);

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
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "Outfit ${index + 1}",
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
                        IconButton(
                          icon: const Icon(Icons.edit_note),
                          color: Colors.grey[600],
                          onPressed: () => _editDayOutfit(index),
                        ),
                      ],
                    ),
                  ),
                  if (outfitItems.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 20.0,
                        bottom: 20.0,
                        right: 20.0,
                      ),
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
                                    child: SmartClothingImage(
                                      imageUrl: itemInfo['imageUrl']
                                          ?.toString(),
                                    ),
                                  ),
                                ),
                                if (idx != outfitItems.length - 1)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0,
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      size: 16,
                                      color: Colors.grey[300],
                                    ),
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
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.grey[400],
                          size: 18,
                        ),
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
              if (isLoading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
