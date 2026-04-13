
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_app/services/firebase_service.dart';

class ClothingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> itemData;

  const ClothingDetailScreen({super.key, required this.itemData});

  @override
  State<ClothingDetailScreen> createState() => _ClothingDetailScreenState();
}

class _ClothingDetailScreenState extends State<ClothingDetailScreen> {
  // --- Controllers for ALL fields ---
  
  // Basic Info
  late TextEditingController _categoryController;
  late TextEditingController _subCategoryController;
  late TextEditingController _materialController;
  late TextEditingController _primaryColorController; // List
  late TextEditingController _patternController;

  // Sustainability Info
  late TextEditingController _brandController;
  late TextEditingController _priceController;
  late TextEditingController _currencyController;
  late TextEditingController _purchaseDateController;

  // Styling Info
  late TextEditingController _fitController;
  late TextEditingController _lengthController;
  late TextEditingController _necklineController;
  late TextEditingController _sleeveLengthController;
  late TextEditingController _styleOccasionsController; // List
  late TextEditingController _seasonalityController; // List

  // Laundry Info
  late TextEditingController _careInstructionsController; // List
  late TextEditingController _colorGroupController;
  late TextEditingController _maxTempController;

  bool _isUpdating = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    // Safety: ensure sub-maps exist
    final data = widget.itemData;
    final basic = data['basic_info'] as Map<String, dynamic>? ?? {};
    final sust = data['sustainability_info'] as Map<String, dynamic>? ?? {};
    final style = data['styling_info'] as Map<String, dynamic>? ?? {};
    final laundry = data['laundry_info'] as Map<String, dynamic>? ?? {};

    // --- Initialize Controllers ---
    
    // Basic
    _categoryController = TextEditingController(text: basic['category'] ?? '');
    _subCategoryController = TextEditingController(text: basic['sub_category'] ?? '');
    _materialController = TextEditingController(text: basic['material'] ?? '');
    _primaryColorController = _listToController(basic['primary_colors']);
    _patternController = TextEditingController(text: basic['pattern'] ?? '');

    // Sustainability
    _brandController = TextEditingController(text: sust['brand'] ?? '');
    _priceController = TextEditingController(text: sust['price']?.toString() ?? '');
    _currencyController = TextEditingController(text: sust['currency'] ?? '');
    _purchaseDateController = TextEditingController(text: sust['purchase_date'] ?? '');

    // Styling
    _fitController = TextEditingController(text: style['fit'] ?? '');
    _lengthController = TextEditingController(text: style['length'] ?? '');
    _necklineController = TextEditingController(text: style['neckline'] ?? '');
    _sleeveLengthController = TextEditingController(text: style['sleeve_length'] ?? '');
    _styleOccasionsController = _listToController(style['style_occasions']);
    _seasonalityController = _listToController(style['seasonality']);

    // Laundry
    _careInstructionsController = _listToController(laundry['care_instructions'], separator: '\n');
    _colorGroupController = TextEditingController(text: laundry['color_group'] ?? '');
    _maxTempController = TextEditingController(text: laundry['max_temp_celsius']?.toString() ?? '');
  }

  TextEditingController _listToController(dynamic listVal, {String separator = ', '}) {
    if (listVal is List) {
      if (listVal.isEmpty) return TextEditingController(text: '');
      return TextEditingController(text: listVal.map((e) => e.toString()).join(separator));
    }
    return TextEditingController(text: listVal?.toString() ?? '');
  }

  List<String> _controllerToList(TextEditingController controller, {String separator = ','}) {
    if (controller.text.isEmpty) return [];
    if (separator == '\n') {
       return controller.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return controller.text.split(separator).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _subCategoryController.dispose();
    _materialController.dispose();
    _primaryColorController.dispose();
    _patternController.dispose();
    
    _brandController.dispose();
    _priceController.dispose();
    _currencyController.dispose();
    _purchaseDateController.dispose();

    _fitController.dispose();
    _lengthController.dispose();
    _necklineController.dispose();
    _sleeveLengthController.dispose();
    _styleOccasionsController.dispose();
    _seasonalityController.dispose();

    _careInstructionsController.dispose();
    _colorGroupController.dispose();
    _maxTempController.dispose();
    super.dispose();
  }

  Future<void> _deleteItem() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      final String docId = widget.itemData['id'];
      final String? imageUrl = widget.itemData['imageUrl'];
      await FirebaseService().deleteItem(docId, imageUrl: imageUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Item deleted successfully"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Return to gallery
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting item: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Item"),
          content: const Text("Are you sure you want to delete this item? This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _deleteItem();
    }
  }

  Future<void> _updateItem() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      // --- Deep Copy Logic (Manual) ---
      // We cannot use jsonEncode because widget.itemData contains Firestore Timestamps (createdAt).
      // Instead, we manually clone the specific sub-maps we want to update.
      // Map.from creates a shallow copy of the Map structure, which is sufficient here 
      // because we are replacing the nested values (Strings, Lists) with new ones.

      final basicInfo = Map<String, dynamic>.from(widget.itemData['basic_info'] ?? {});
      final sustainabilityInfo = Map<String, dynamic>.from(widget.itemData['sustainability_info'] ?? {});
      final stylingInfo = Map<String, dynamic>.from(widget.itemData['styling_info'] ?? {});
      final laundryInfo = Map<String, dynamic>.from(widget.itemData['laundry_info'] ?? {});

      // --- Update Basic Info ---
      basicInfo['category'] = _categoryController.text;
      basicInfo['sub_category'] = _subCategoryController.text;
      basicInfo['material'] = _materialController.text;
      basicInfo['primary_colors'] = _controllerToList(_primaryColorController);
      basicInfo['pattern'] = _patternController.text;

      // --- Update Sustainability Info ---
      sustainabilityInfo['brand'] = _brandController.text;
      
      // Parse Price carefully
      if (_priceController.text.isNotEmpty) {
          final price = double.tryParse(_priceController.text.replaceAll(',', '.')); // Handle commas
          sustainabilityInfo['price'] = price ?? _priceController.text; 
      } else {
          sustainabilityInfo['price'] = null;
      }
      
      sustainabilityInfo['currency'] = _currencyController.text;
      sustainabilityInfo['purchase_date'] = _purchaseDateController.text;

      // --- Update Styling Info ---
      stylingInfo['fit'] = _fitController.text;
      stylingInfo['length'] = _lengthController.text;
      stylingInfo['neckline'] = _necklineController.text;
      stylingInfo['sleeve_length'] = _sleeveLengthController.text;
      stylingInfo['style_occasions'] = _controllerToList(_styleOccasionsController);
      stylingInfo['seasonality'] = _controllerToList(_seasonalityController);

      // --- Update Laundry Info ---
      laundryInfo['care_instructions'] = _controllerToList(_careInstructionsController, separator: '\n');
      laundryInfo['color_group'] = _colorGroupController.text;
      
      // Parse Max Temp
      if (_maxTempController.text.isNotEmpty) {
         final temp = int.tryParse(_maxTempController.text);
         laundryInfo['max_temp_celsius'] = temp ?? _maxTempController.text;
      } else {
         laundryInfo['max_temp_celsius'] = null;
      }


      // --- Prepare Final Update Map ---
      Map<String, dynamic> updates = {
        'basic_info': basicInfo,
        'sustainability_info': sustainabilityInfo,
        'styling_info': stylingInfo,
        'laundry_info': laundryInfo,
      };

      await FirebaseService().updateItem(widget.itemData['id'], updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Details updated successfully!")),
        );
        Navigator.pop(context); // Return to gallery
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating item: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.itemData['imageUrl'] as String?;

    return Scaffold(
      backgroundColor: Colors.grey[50], // M3 Light Background benefit
      appBar: AppBar(
        title: const Text("Item Details", style: TextStyle(fontWeight: FontWeight.bold)),
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          _isDeleting
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _confirmDelete,
                ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Header
              _buildImageHeader(imageUrl),
  
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                     _buildSectionHeader("Basic Info", Icons.info_outline),
                     _buildCard([
                       _buildTextField("Category", _categoryController),
                       _buildTextField("Sub Category", _subCategoryController),
                       _buildTextField("Material", _materialController),
                       _buildTextField("Colors (comma separated)", _primaryColorController),
                       _buildTextField("Pattern", _patternController),
                     ]),
  
                     _buildSectionHeader("Sustainability & Purchase", Icons.eco_outlined),
                     _buildCard([
                       _buildTextField("Brand", _brandController),
                       Row(children: [
                         Expanded(child: _buildTextField("Price", _priceController, keyboardType: TextInputType.number)),
                         const SizedBox(width: 12),
                         Expanded(child: _buildTextField("Currency", _currencyController)),
                       ]),
                       _buildTextField("Purchase Date", _purchaseDateController, hint: "YYYY-MM-DD"),
                     ]),
  
                     _buildSectionHeader("Styling", Icons.style_outlined),
                     _buildCard([
                       _buildTextField("Fit", _fitController),
                       _buildTextField("Length", _lengthController),
                       _buildTextField("Neckline", _necklineController),
                       _buildTextField("Sleeve Length", _sleeveLengthController),
                       _buildTextField("Occasions (comma separated)", _styleOccasionsController),
                       _buildTextField("Seasonality (comma separated)", _seasonalityController),
                     ]),
  
                     _buildSectionHeader("Laundry & Care", Icons.local_laundry_service_outlined),
                     _buildCard([
                       _buildTextField("Care Instructions (one per line)", _careInstructionsController, maxLines: 4),
                       _buildTextField("Color Group", _colorGroupController),
                       _buildTextField("Max Temp (°C)", _maxTempController, keyboardType: TextInputType.number),
                     ]),
  
                     const SizedBox(height: 32),
                     SizedBox(
                       height: 56,
                       width: double.infinity,
                       child: ElevatedButton(
                         onPressed: _isUpdating ? null : _updateItem,
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.black,
                           foregroundColor: Colors.white,
                           elevation: 0,
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(28), // M3 full round
                           ),
                         ),
                         child: _isUpdating 
                           ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                           : const Text("Update Item", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                       ),
                     ),
                     const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.blueGrey[800]),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildImageHeader(String? imageUrl) {
    Widget imageWidget;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http')) {
        imageWidget = CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) => Container(
            color: Colors.grey[100],
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (context, url, error) => _buildPlaceholderIcon(Icons.broken_image),
        );
      } else if (imageUrl.startsWith('data:image')) {
        final base64String = imageUrl.split(',').last;
        try {
          imageWidget = Image.memory(base64Decode(base64String), fit: BoxFit.contain);
        } catch (e) {
          imageWidget = _buildPlaceholderIcon(Icons.broken_image);
        }
      } else {
         try {
            imageWidget = Image.memory(base64Decode(imageUrl), fit: BoxFit.contain);
         } catch (e) {
            imageWidget = _buildPlaceholderIcon(Icons.image);
         }
      }
    } else {
      imageWidget = _buildPlaceholderIcon(Icons.checkroom);
    }

    return Container(
      height: 320,
      width: double.infinity,
      color: Colors.white,
      child: Center(child: imageWidget),
    );
  }

  Widget _buildPlaceholderIcon(IconData icon) {
     return Container(
       color: Colors.grey[100], 
       child: Center(child: Icon(icon, size: 48, color: Colors.grey[400]))
     );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
          fillColor: Colors.white,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          isDense: true,
          border: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.5)),
        ),
        style: const TextStyle(fontSize: 15, color: Colors.black87),
      ),
    );
  }
}
