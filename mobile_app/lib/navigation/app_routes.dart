import 'dart:io';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String auth = '/';
  static const String home = '/home';
  static const String addClothing = '/wardrobe/add';
  static const String clothingDetail = '/wardrobe/detail';
  static const String outfitDetail = '/outfit/detail';
  static const String dressingRoom = '/dressing-room';
  static const String tripView = '/trip/view';
  static const String tripSetup = '/trip/setup';
  static const String trips = '/trips';
  static const String calendar = '/calendar';
  static const String sustainability = '/sustainability';
  static const String aiStylist = '/ai-stylist';
  static const String shopping = '/shopping';
  static const String laundry = '/laundry';
  static const String matchResult = '/match-result';
  static const String itemSelection = '/item-selection';
  static const String settings = '/settings';
}

class ClothingDetailArgs {
  final Map<String, dynamic> itemData;
  const ClothingDetailArgs(this.itemData);
}

class OutfitDetailArgs {
  final Map<String, dynamic> outfitData;
  final String outfitId;
  const OutfitDetailArgs({required this.outfitData, required this.outfitId});
}

class VirtualDressingRoomArgs {
  final List<String>? initialItemIds;
  const VirtualDressingRoomArgs({this.initialItemIds});
}

class TripViewArgs {
  final String destination;
  final int days;
  final String vibe;
  final DateTimeRange? dateRange;
  final Map<String, dynamic>? initialTripData;
  final String? tripPlans;
  final String? luggageSize;
  final String? tripId;

  const TripViewArgs({
    required this.destination,
    required this.days,
    required this.vibe,
    this.dateRange,
    this.initialTripData,
    this.tripPlans,
    this.luggageSize,
    this.tripId,
  });
}

class MatchResultArgs {
  final Map<String, dynamic> scannedItemData;
  final File imageFile;
  const MatchResultArgs({required this.scannedItemData, required this.imageFile});
}

class AddClothingArgs {
  final Map<String, dynamic>? initialAnalysisResult;
  final File? initialImageFile;
  const AddClothingArgs({this.initialAnalysisResult, this.initialImageFile});
}

class ItemSelectionArgs {
  final List<String> initialSelectedIds;
  const ItemSelectionArgs(this.initialSelectedIds);
}
