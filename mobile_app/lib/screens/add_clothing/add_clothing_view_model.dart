import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/clothing_repository.dart';
import 'package:mobile_app/services/storage_service.dart';

class AddClothingViewModel extends ChangeNotifier {
  final ApiService _apiService;
  final ImagePicker _picker;

  File? _itemImage;
  File? _tagImage;
  bool _isAnalyzing = false;
  String? _errorMessage;
  Map<String, dynamic>? _analysisResult;
  String? _selectedWardrobeId;

  File? get itemImage => _itemImage;
  File? get tagImage => _tagImage;
  bool get isAnalyzing => _isAnalyzing;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get analysisResult => _analysisResult;
  String? get selectedWardrobeId => _selectedWardrobeId;

  // Basic Info
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController subCategoryController = TextEditingController();
  final TextEditingController materialController = TextEditingController();
  final TextEditingController primaryColorController = TextEditingController();
  final TextEditingController patternController = TextEditingController();

  // Sustainability Info
  final TextEditingController brandController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController currencyController = TextEditingController();
  final TextEditingController purchaseDateController = TextEditingController();

  // Styling Info
  final TextEditingController fitController = TextEditingController();
  final TextEditingController lengthController = TextEditingController();
  final TextEditingController necklineController = TextEditingController();
  final TextEditingController sleeveLengthController = TextEditingController();
  final TextEditingController styleOccasionsController = TextEditingController();
  final TextEditingController seasonalityController = TextEditingController();

  // Laundry Info
  final TextEditingController careInstructionsController = TextEditingController();
  final TextEditingController colorGroupController = TextEditingController();
  final TextEditingController maxTempController = TextEditingController();

  AddClothingViewModel({
    Map<String, dynamic>? initialAnalysisResult,
    File? initialImageFile,
    String? wardrobeId,
  })  : _apiService = ApiService(),
        _picker = ImagePicker() {
    _selectedWardrobeId = wardrobeId;
    if (initialAnalysisResult != null && initialImageFile != null) {
      _analysisResult = initialAnalysisResult;
      _itemImage = initialImageFile;
      if (_analysisResult!['metadata'] != null) {
        _populateForm(_analysisResult!['metadata']);
      }
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

  void setWardrobeId(String? id) {
    _selectedWardrobeId = id;
    notifyListeners();
  }

  void clearItemImage() {
    _itemImage = null;
    notifyListeners();
  }

  void clearTagImage() {
    _tagImage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void resetAnalysis() {
    _analysisResult = null;
    _itemImage = null;
    _tagImage = null;
    notifyListeners();
  }

  Future<void> pickImage(bool isTag, ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 95,
    );
    if (pickedFile != null) {
      if (isTag) {
        _tagImage = File(pickedFile.path);
      } else {
        _itemImage = File(pickedFile.path);
      }
      notifyListeners();
    }
  }

  Future<void> analyzeItem() async {
    _isAnalyzing = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _apiService.processItem(_itemImage!, tagFile: _tagImage);
      if (result != null && result['metadata'] != null) {
        _analysisResult = result;
        _populateForm(result['metadata']);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  /// Returns null on success, or the error message string on failure.
  Future<String?> saveItem() async {
    try {
      Map<String, dynamic> finalMetadata = jsonDecode(
        jsonEncode(_analysisResult!['metadata'] ?? {}),
      );

      finalMetadata['basic_info'] = finalMetadata['basic_info'] ?? {};
      finalMetadata['basic_info']['category'] = categoryController.text;
      finalMetadata['basic_info']['sub_category'] = subCategoryController.text;
      finalMetadata['basic_info']['material'] = materialController.text;
      finalMetadata['basic_info']['pattern'] = patternController.text;
      finalMetadata['basic_info']['primary_colors'] =
          _controllerToList(primaryColorController);

      finalMetadata['sustainability_info'] =
          finalMetadata['sustainability_info'] ?? {};
      finalMetadata['sustainability_info']['brand'] = brandController.text;
      final price =
          double.tryParse(priceController.text.replaceAll(',', '.'));
      finalMetadata['sustainability_info']['price'] =
          price ?? (priceController.text.isEmpty ? null : priceController.text);
      finalMetadata['sustainability_info']['currency'] = currencyController.text;
      finalMetadata['sustainability_info']['purchase_date'] =
          purchaseDateController.text;

      finalMetadata['styling_info'] = finalMetadata['styling_info'] ?? {};
      finalMetadata['styling_info']['fit'] = fitController.text;
      finalMetadata['styling_info']['length'] = lengthController.text;
      finalMetadata['styling_info']['neckline'] = necklineController.text;
      finalMetadata['styling_info']['sleeve_length'] =
          sleeveLengthController.text;
      finalMetadata['styling_info']['style_occasions'] =
          _controllerToList(styleOccasionsController);
      finalMetadata['styling_info']['seasonality'] =
          _controllerToList(seasonalityController);

      finalMetadata['laundry_info'] = finalMetadata['laundry_info'] ?? {};
      finalMetadata['laundry_info']['care_instructions'] = _controllerToList(
        careInstructionsController,
        separator: '\n',
      );
      finalMetadata['laundry_info']['color_group'] = colorGroupController.text;
      final temp = int.tryParse(maxTempController.text);
      finalMetadata['laundry_info']['max_temp_celsius'] =
          temp ?? (maxTempController.text.isEmpty ? null : maxTempController.text);

      final Uint8List imageBytes =
          base64Decode(_analysisResult!['image_base64']);
      final String? downloadUrl =
          await StorageService().uploadImageToStorage(imageBytes, 'items');

      if (downloadUrl == null) {
        throw Exception('Failed to upload image to storage.');
      }

      await ClothingRepository().saveItem(
        imageUrl: downloadUrl,
        metadata: finalMetadata,
        wardrobeId: _selectedWardrobeId,
      );

      return null;
    } catch (e) {
      return e.toString();
    }
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

  void _populateForm(Map<String, dynamic> metadata) {
    if (metadata['basic_info'] != null) {
      categoryController.text = metadata['basic_info']['category'] ?? '';
      subCategoryController.text =
          metadata['basic_info']['sub_category'] ?? '';
      materialController.text = metadata['basic_info']['material'] ?? '';
      patternController.text = metadata['basic_info']['pattern'] ?? '';
      if (metadata['basic_info']['primary_colors'] != null) {
        primaryColorController.text =
            (metadata['basic_info']['primary_colors'] as List).join(', ');
      }
    }
    if (metadata['styling_info'] != null) {
      fitController.text = metadata['styling_info']['fit'] ?? '';
      lengthController.text = metadata['styling_info']['length'] ?? '';
      necklineController.text = metadata['styling_info']['neckline'] ?? '';
      sleeveLengthController.text =
          metadata['styling_info']['sleeve_length'] ?? '';
      if (metadata['styling_info']['style_occasions'] != null) {
        styleOccasionsController.text =
            (metadata['styling_info']['style_occasions'] as List).join(', ');
      }
      if (metadata['styling_info']['seasonality'] != null) {
        seasonalityController.text =
            (metadata['styling_info']['seasonality'] as List).join(', ');
      }
    }
    if (metadata['laundry_info'] != null) {
      if (metadata['laundry_info']['care_instructions'] != null) {
        careInstructionsController.text =
            (metadata['laundry_info']['care_instructions'] as List).join('\n');
      }
      colorGroupController.text =
          metadata['laundry_info']['color_group'] ?? '';
      maxTempController.text =
          metadata['laundry_info']['max_temp_celsius']?.toString() ?? '';
    }
    if (metadata['sustainability_info'] != null) {
      brandController.text =
          metadata['sustainability_info']['brand'] ?? '';
      priceController.text =
          metadata['sustainability_info']['price']?.toString() ?? '';
      currencyController.text =
          metadata['sustainability_info']['currency'] ?? '';
      purchaseDateController.text =
          metadata['sustainability_info']['purchase_date'] ?? '';
    }
  }
}
