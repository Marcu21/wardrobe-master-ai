import 'package:flutter/material.dart';
import 'package:mobile_app/services/packing_service.dart';
import 'package:mobile_app/services/weather_service.dart';
import 'package:mobile_app/services/wardrobe_state_service.dart';
import 'package:mobile_app/services/clothing_repository.dart';
import 'package:mobile_app/services/trip_repository.dart';

class TripViewViewModel extends ChangeNotifier {
  final String? tripId;
  final String destination;
  final int days;
  final String vibe;
  final DateTimeRange? dateRange;
  final Map<String, dynamic>? initialTripData;
  final String? tripPlans;
  final String? luggageSize;

  List<Map<String, dynamic>> clothingItems = [];
  List<String> editableItemIds = [];
  bool isLoading = true;
  String? errorMessage;
  bool isSyncing = false;
  bool isEditMode = false;
  CapsuleWardrobe? wardrobe;
  bool isStylistNoteExpanded = false;
  bool hasUnsavedChanges = false;
  final Set<int> loadingOutfitIndices = {};
  bool isAddingAdHocOutfit = false;
  late final TextEditingController adHocOutfitController;

  List<String> lastSyncedItemIds = [];
  String? currentTripId;

  bool _disposed = false;

  TripViewViewModel({
    required this.tripId,
    required this.destination,
    required this.days,
    required this.vibe,
    this.dateRange,
    this.initialTripData,
    this.tripPlans,
    this.luggageSize,
  }) {
    adHocOutfitController = TextEditingController();
    currentTripId = tripId;
    if (currentTripId != null && initialTripData != null) {
      _loadSavedTrip();
    } else {
      hasUnsavedChanges = true;
      _generateWardrobe();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _loadSavedTrip() {
    final data = initialTripData!;
    final outfitsList = data['outfits'] as List? ?? [];
    final parsedOutfits = outfitsList
        .map((o) => TripOutfit.fromJson(o as Map<String, dynamic>))
        .toList();

    wardrobe = CapsuleWardrobe(
      selectedItemIds: List<String>.from(data['item_ids'] ?? []),
      reasoning: data['reasoning'] as String? ?? '',
      warningMessage: data['warning_message'] as String?,
      outfits: parsedOutfits,
    );
    editableItemIds = List<String>.from(wardrobe!.selectedItemIds);
    lastSyncedItemIds = List<String>.from(editableItemIds);
    _fetchItems();
  }

  Future<void> _generateWardrobe() async {
    try {
      final weatherSummary = dateRange != null
          ? await WeatherService().getTripWeatherSummary(
              destination,
              dateRange!.start,
              dateRange!.end,
            )
          : 'Unknown Weather';

      final result = await PackingService().generatePackingList(
        destination: destination,
        days: days,
        vibe: vibe,
        weatherForecast: weatherSummary,
        wardrobeId: wardrobeStateService.activeWardrobeId,
        tripPlans: tripPlans,
        luggageSize: luggageSize,
      );

      if (!_disposed) {
        wardrobe = result;
        editableItemIds = List<String>.from(result.selectedItemIds);
        lastSyncedItemIds = List<String>.from(editableItemIds);
        _notify();
        _fetchItems();
      }
    } catch (e) {
      if (!_disposed) {
        isLoading = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        _notify();
      }
    }
  }

  Future<void> _fetchItems() async {
    if (editableItemIds.isEmpty) {
      if (!_disposed) {
        clothingItems = [];
        isLoading = false;
        _notify();
      }
      return;
    }
    try {
      final items = await ClothingRepository().getItemsByIds(editableItemIds);
      if (!_disposed) {
        clothingItems = items;
        isLoading = false;
        _notify();
      }
    } catch (e) {
      if (!_disposed) {
        isLoading = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        _notify();
      }
    }
  }

  void retryGenerate() {
    isLoading = true;
    errorMessage = null;
    _notify();
    _generateWardrobe();
  }

  void removeItem(String id) {
    editableItemIds.remove(id);
    _notify();
    _fetchItems();
  }

  void updateEditableItems(List<String> newIds) {
    editableItemIds = newIds;
    _notify();
    _fetchItems();
  }

  void toggleEditMode() {
    isEditMode = !isEditMode;
    if (!isEditMode) {
      editableItemIds = List<String>.from(lastSyncedItemIds);
      _notify();
      _fetchItems();
    } else {
      _notify();
    }
  }

  void toggleStylistNote() {
    isStylistNoteExpanded = !isStylistNoteExpanded;
    _notify();
  }

  Future<String?> syncAndRestyle() async {
    isSyncing = true;
    _notify();
    try {
      final weatherSummary = dateRange != null
          ? await WeatherService().getTripWeatherSummary(
              destination,
              dateRange!.start,
              dateRange!.end,
            )
          : 'Unknown Weather';

      final result = await PackingService().generatePackingList(
        destination: destination,
        days: days,
        vibe: vibe,
        weatherForecast: weatherSummary,
        itemIdsOverride: editableItemIds,
        tripPlans: tripPlans ?? initialTripData?['trip_plans'],
        luggageSize: luggageSize ?? initialTripData?['luggage_size'],
      );

      if (!_disposed) {
        wardrobe = result;
        editableItemIds = List<String>.from(result.selectedItemIds);
        lastSyncedItemIds = List<String>.from(editableItemIds);
        isEditMode = false;
        isSyncing = false;
        hasUnsavedChanges = true;
        _notify();
        _fetchItems();
      }
      return null;
    } catch (e) {
      if (!_disposed) {
        isSyncing = false;
        _notify();
      }
      return e.toString();
    }
  }

  // Pure async write. Never calls notifyListeners — firing it during the
  // microtask continuation of the save dialog's dismissal (or in the
  // ChangeNotifierProvider's teardown window) trips Flutter's
  // "wrong build scope" / `_dependents.isEmpty` assertions inside the
  // NestedScrollView + TabBarView subtree. The screen replaces the route
  // with a fresh saved-trip view after this returns instead of mutating
  // state in place.
  Future<String?> saveTrip(String tripName) async {
    if (wardrobe == null) return null;
    try {
      final outfitsList = wardrobe!.outfits.map((o) => o.toJson()).toList();
      final newTripId = await TripRepository().saveTrip(
        name: tripName,
        destination: destination,
        itemIds: wardrobe!.selectedItemIds,
        outfits: outfitsList,
        reasoning: wardrobe!.reasoning,
        vibe: vibe,
        tripPlans: tripPlans,
        luggageSize: luggageSize,
        startDate: dateRange?.start,
        endDate: dateRange?.end,
      );
      if (!_disposed) {
        currentTripId = newTripId;
        hasUnsavedChanges = false;
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateTrip({bool showGlobalLoader = true}) async {
    if (wardrobe == null || currentTripId == null) return null;
    if (showGlobalLoader) {
      isLoading = true;
      _notify();
    }
    try {
      final error = await _updateTripSilent();
      return error;
    } finally {
      if (showGlobalLoader && !_disposed) {
        isLoading = false;
        _notify();
      }
    }
  }

  Future<String?> _updateTripSilent() async {
    if (wardrobe == null || currentTripId == null) return null;
    try {
      final outfitsList = wardrobe!.outfits.map((o) => o.toJson()).toList();
      await TripRepository().updateTrip(
        currentTripId!,
        wardrobe!.selectedItemIds,
        outfitsList,
        wardrobe!.reasoning,
        vibe: vibe,
        tripPlans: tripPlans ?? initialTripData?['trip_plans'],
        luggageSize: luggageSize ?? initialTripData?['luggage_size'],
        startDate: dateRange?.start,
        endDate: dateRange?.end,
      );
      if (!_disposed) {
        hasUnsavedChanges = false;
        initialTripData?['item_ids'] = List<String>.from(lastSyncedItemIds);
        _notify();
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> editDayOutfit(int index, String feedback) async {
    loadingOutfitIndices.add(index);
    _notify();
    try {
      final outfit = wardrobe!.outfits[index];
      final weatherSummary = dateRange != null
          ? await WeatherService().getTripWeatherSummary(
              destination,
              dateRange!.start,
              dateRange!.end,
            )
          : 'Unknown Weather';

      final existingOutfits = <Map<String, dynamic>>[];
      for (int i = 0; i < wardrobe!.outfits.length; i++) {
        if (i != index) {
          existingOutfits.add({
            'context': wardrobe!.outfits[i].title,
            'used_item_ids': wardrobe!.outfits[i].itemIds,
          });
        }
      }

      final newOutfit = await PackingService().generateSpecificTripOutfit(
        destination: destination,
        vibe: vibe,
        weatherForecast: weatherSummary,
        suitcaseItemIds: editableItemIds,
        userContext: outfit.title,
        existingOutfits: existingOutfits,
        feedback: feedback,
        currentOutfitItemIds: outfit.itemIds,
      );

      if (!_disposed) {
        wardrobe!.outfits[index] = newOutfit;
        hasUnsavedChanges = true;
        _notify();
        if (currentTripId != null) {
          return await _updateTripSilent();
        }
      }
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      loadingOutfitIndices.remove(index);
      _notify();
    }
  }

  Future<String?> addAdHocOutfit(String contextPlan) async {
    if (contextPlan.isEmpty) return null;
    isAddingAdHocOutfit = true;
    _notify();
    try {
      final weatherSummary = dateRange != null
          ? await WeatherService().getTripWeatherSummary(
              destination,
              dateRange!.start,
              dateRange!.end,
            )
          : 'Unknown Weather';

      final existingOutfits = wardrobe!.outfits
          .map((o) => {'context': o.title, 'used_item_ids': o.itemIds})
          .toList();

      final newOutfit = await PackingService().generateSpecificTripOutfit(
        destination: destination,
        vibe: vibe,
        weatherForecast: weatherSummary,
        suitcaseItemIds: editableItemIds,
        userContext: contextPlan,
        existingOutfits: existingOutfits,
      );

      if (!_disposed) {
        wardrobe!.outfits.add(newOutfit);
        hasUnsavedChanges = true;
        adHocOutfitController.clear();
        _notify();
      }
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      if (!_disposed) {
        isAddingAdHocOutfit = false;
        _notify();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    adHocOutfitController.dispose();
    super.dispose();
  }
}
