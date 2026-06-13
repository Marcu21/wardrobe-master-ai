import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/packing_service.dart';

void main() {
  group('TripOutfit.fromJson', () {
    test('UT-D01: parses valid JSON with all fields correctly', () {
      final json = {
        'title': 'Museum Day',
        'description': 'A comfortable look for walking',
        'item_ids': ['id1', 'id2', 'id3'],
      };
      final outfit = TripOutfit.fromJson(json);
      expect(outfit.title, 'Museum Day');
      expect(outfit.description, 'A comfortable look for walking');
      expect(outfit.itemIds, ['id1', 'id2', 'id3']);
    });

    test('UT-D04: missing item_ids defaults to empty list', () {
      final json = {'title': 'Casual Look', 'description': 'desc'};
      final outfit = TripOutfit.fromJson(json);
      expect(outfit.itemIds, isEmpty);
    });

    test('UT-D05: null title falls back to "Unnamed Outfit"', () {
      final json = {'title': null, 'description': 'desc', 'item_ids': <String>[]};
      final outfit = TripOutfit.fromJson(json);
      expect(outfit.title, 'Unnamed Outfit');
    });
  });

  group('CapsuleWardrobe.fromJson', () {
    test('UT-D01: parses valid JSON with all fields correctly', () {
      final json = {
        'selected_item_ids': ['id1', 'id2'],
        'reasoning': 'Minimal capsule for Paris',
        'warning_message': null,
        'outfits': [
          {'title': 'Museum Explorer', 'description': 'Casual walk', 'item_ids': ['id1']},
        ],
      };
      final cw = CapsuleWardrobe.fromJson(json);
      expect(cw.selectedItemIds, ['id1', 'id2']);
      expect(cw.reasoning, 'Minimal capsule for Paris');
      expect(cw.outfits.length, 1);
      expect(cw.outfits.first.title, 'Museum Explorer');
    });

    test('UT-D02: missing outfits field defaults to empty list', () {
      final json = {
        'selected_item_ids': ['id1'],
        'reasoning': 'Test reasoning',
      };
      final cw = CapsuleWardrobe.fromJson(json);
      expect(cw.outfits, isEmpty);
    });

    test('UT-D03: warning_message null is preserved as Dart null', () {
      final json = {
        'selected_item_ids': <String>[],
        'reasoning': '',
        'warning_message': null,
        'outfits': <dynamic>[],
      };
      final cw = CapsuleWardrobe.fromJson(json);
      expect(cw.warningMessage, isNull);
    });
  });
}
