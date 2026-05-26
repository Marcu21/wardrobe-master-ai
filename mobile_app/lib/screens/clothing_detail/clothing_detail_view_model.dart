import 'package:flutter/material.dart';
import 'package:mobile_app/services/clothing_repository.dart';
import 'package:mobile_app/services/wardrobe_state_service.dart';

class ClothingDetailViewModel extends ChangeNotifier {
  final Map<String, dynamic> itemData;

  late final TextEditingController categoryController;
  late final TextEditingController subCategoryController;
  late final TextEditingController materialController;
  late final TextEditingController primaryColorController;
  late final TextEditingController patternController;
  late final TextEditingController brandController;
  late final TextEditingController priceController;
  late final TextEditingController currencyController;
  late final TextEditingController purchaseDateController;
  late final TextEditingController fitController;
  late final TextEditingController lengthController;
  late final TextEditingController necklineController;
  late final TextEditingController sleeveLengthController;
  late final TextEditingController styleOccasionsController;
  late final TextEditingController seasonalityController;
  late final TextEditingController careInstructionsController;
  late final TextEditingController colorGroupController;
  late final TextEditingController maxTempController;

  String? _currentWardrobeId;
  String? get currentWardrobeId => _currentWardrobeId;

  String get currentWardrobeName {
    if (_currentWardrobeId == null) return 'All Wardrobes';
    final matches = wardrobeStateService.wardrobes.where(
      (w) => w['id'] == _currentWardrobeId,
    );
    return matches.isNotEmpty ? matches.first['name'] as String : 'All Wardrobes';
  }

  ClothingDetailViewModel({required this.itemData}) {
    final basic = itemData['basic_info'] as Map<String, dynamic>? ?? {};
    final sust = itemData['sustainability_info'] as Map<String, dynamic>? ?? {};
    final style = itemData['styling_info'] as Map<String, dynamic>? ?? {};
    final laundry = itemData['laundry_info'] as Map<String, dynamic>? ?? {};

    _currentWardrobeId = itemData['wardrobe_id'];

    categoryController = TextEditingController(text: basic['category'] ?? '');
    subCategoryController = TextEditingController(text: basic['sub_category'] ?? '');
    materialController = TextEditingController(text: basic['material'] ?? '');
    primaryColorController = _listToController(basic['primary_colors']);
    patternController = TextEditingController(text: basic['pattern'] ?? '');

    brandController = TextEditingController(text: sust['brand'] ?? '');
    priceController = TextEditingController(text: sust['price']?.toString() ?? '');
    currencyController = TextEditingController(text: sust['currency'] ?? '');
    purchaseDateController = TextEditingController(text: sust['purchase_date'] ?? '');

    fitController = TextEditingController(text: style['fit'] ?? '');
    lengthController = TextEditingController(text: style['length'] ?? '');
    necklineController = TextEditingController(text: style['neckline'] ?? '');
    sleeveLengthController = TextEditingController(text: style['sleeve_length'] ?? '');
    styleOccasionsController = _listToController(style['style_occasions']);
    seasonalityController = _listToController(style['seasonality']);

    careInstructionsController = _listToController(
      laundry['care_instructions'],
      separator: '\n',
    );
    colorGroupController = TextEditingController(text: laundry['color_group'] ?? '');
    maxTempController = TextEditingController(
      text: laundry['max_temp_celsius']?.toString() ?? '',
    );
  }

  TextEditingController _listToController(
    dynamic listVal, {
    String separator = ', ',
  }) {
    if (listVal is List) {
      if (listVal.isEmpty) return TextEditingController(text: '');
      return TextEditingController(
        text: listVal.map((e) => e.toString()).join(separator),
      );
    }
    return TextEditingController(text: listVal?.toString() ?? '');
  }

  List<String> _controllerToList(
    TextEditingController controller, {
    String separator = ',',
  }) {
    if (controller.text.isEmpty) return [];
    if (separator == '\n') {
      return controller.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return controller.text
        .split(separator)
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<String?> updateItemWardrobe(String? newWardrobeId) async {
    final oldWardrobeId = _currentWardrobeId;
    if (newWardrobeId == oldWardrobeId) return null;
    _currentWardrobeId = newWardrobeId;
    notifyListeners();
    try {
      await ClothingRepository().updateItem(itemData['id'], {
        'wardrobe_id': newWardrobeId,
      });
      return null;
    } catch (e) {
      _currentWardrobeId = oldWardrobeId;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> deleteItem() async {
    try {
      final String docId = itemData['id'];
      final String? imageUrl = itemData['imageUrl'];
      await ClothingRepository().deleteItem(docId, imageUrl: imageUrl);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateItem() async {
    try {
      final basicInfo = Map<String, dynamic>.from(itemData['basic_info'] ?? {});
      final sustainabilityInfo = Map<String, dynamic>.from(
        itemData['sustainability_info'] ?? {},
      );
      final stylingInfo = Map<String, dynamic>.from(itemData['styling_info'] ?? {});
      final laundryInfo = Map<String, dynamic>.from(itemData['laundry_info'] ?? {});

      basicInfo['category'] = categoryController.text;
      basicInfo['sub_category'] = subCategoryController.text;
      basicInfo['material'] = materialController.text;
      basicInfo['primary_colors'] = _controllerToList(primaryColorController);
      basicInfo['pattern'] = patternController.text;

      sustainabilityInfo['brand'] = brandController.text;
      if (priceController.text.isNotEmpty) {
        final price = double.tryParse(priceController.text.replaceAll(',', '.'));
        sustainabilityInfo['price'] = price ?? priceController.text;
      } else {
        sustainabilityInfo['price'] = null;
      }
      sustainabilityInfo['currency'] = currencyController.text;
      sustainabilityInfo['purchase_date'] = purchaseDateController.text;

      stylingInfo['fit'] = fitController.text;
      stylingInfo['length'] = lengthController.text;
      stylingInfo['neckline'] = necklineController.text;
      stylingInfo['sleeve_length'] = sleeveLengthController.text;
      stylingInfo['style_occasions'] = _controllerToList(styleOccasionsController);
      stylingInfo['seasonality'] = _controllerToList(seasonalityController);

      laundryInfo['care_instructions'] = _controllerToList(
        careInstructionsController,
        separator: '\n',
      );
      laundryInfo['color_group'] = colorGroupController.text;
      if (maxTempController.text.isNotEmpty) {
        final temp = int.tryParse(maxTempController.text);
        laundryInfo['max_temp_celsius'] = temp ?? maxTempController.text;
      } else {
        laundryInfo['max_temp_celsius'] = null;
      }

      await ClothingRepository().updateItem(itemData['id'], {
        'basic_info': basicInfo,
        'sustainability_info': sustainabilityInfo,
        'styling_info': stylingInfo,
        'laundry_info': laundryInfo,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  @override
  void dispose() {
    categoryController.dispose();
    subCategoryController.dispose();
    materialController.dispose();
    primaryColorController.dispose();
    patternController.dispose();
    brandController.dispose();
    priceController.dispose();
    currencyController.dispose();
    purchaseDateController.dispose();
    fitController.dispose();
    lengthController.dispose();
    necklineController.dispose();
    sleeveLengthController.dispose();
    styleOccasionsController.dispose();
    seasonalityController.dispose();
    careInstructionsController.dispose();
    colorGroupController.dispose();
    maxTempController.dispose();
    super.dispose();
  }
}
