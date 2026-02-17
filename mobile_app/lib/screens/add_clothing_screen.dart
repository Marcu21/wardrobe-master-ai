
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/firebase_service.dart';
import 'dart:convert';

class AddClothingScreen extends StatefulWidget {
  const AddClothingScreen({super.key});

  @override
  State<AddClothingScreen> createState() => _AddClothingScreenState();
}

class _AddClothingScreenState extends State<AddClothingScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  File? _itemImage;
  File? _tagImage;
  bool _isLoading = false;
  Map<String, dynamic>? _analysisResult;

  // Controllers for the form
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _subCategoryController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _fitController = TextEditingController();
  final TextEditingController _occasionController = TextEditingController();
  final TextEditingController _careController = TextEditingController();

  Future<void> _pickImage(bool isTag, ImageSource source) async {
      try {
        // Am adăugat limite de mărime și calitate pentru a evita eroarea de 1MB în Firestore
        final XFile? pickedFile = await _picker.pickImage(
          source: source,
          maxWidth: 800,       // Redimensionare la lățime maximă de 800px
          maxHeight: 800,      // Redimensionare la înălțime maximă de 800px
          imageQuality: 70,    // Compresie la 70% din calitate
        );

        if (pickedFile != null) {
          setState(() {
            if (isTag) {
              _tagImage = File(pickedFile.path);
            } else {
              _itemImage = File(pickedFile.path);
            }
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }

  void _showImageSourceModal(bool isTag) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 180,
          child: Column(
            children: [
              Text(
                isTag ? 'Select Tag Photo' : 'Select Item Photo',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(isTag, ImageSource.camera);
                    },
                  ),
                  _buildSourceOption(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(isTag, ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _analyzeItem() async {
    if (_itemImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an item image first.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _apiService.processItem(_itemImage!, tagFile: _tagImage);
      if (result != null && result['metadata'] != null) {
        setState(() {
          _analysisResult = result;
          _populateForm(result['metadata']);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateForm(Map<String, dynamic> metadata) {
    if (metadata['basic_info'] != null) {
      _categoryController.text = metadata['basic_info']['category'] ?? '';
      _subCategoryController.text = metadata['basic_info']['sub_category'] ?? '';
      _materialController.text = metadata['basic_info']['material'] ?? '';
      if (metadata['basic_info']['primary_colors'] != null) {
        _colorController.text = (metadata['basic_info']['primary_colors'] as List).join(', ');
      }
    }
    
    if (metadata['styling_info'] != null) {
      _fitController.text = metadata['styling_info']['fit'] ?? '';
      if (metadata['styling_info']['style_occasions'] != null) {
        _occasionController.text = (metadata['styling_info']['style_occasions'] as List).join(', ');
      }
    }

    if (metadata['laundry_info'] != null && metadata['laundry_info']['care_instructions'] != null) {
      _careController.text = (metadata['laundry_info']['care_instructions'] as List).join(', ');
    }

    if (metadata['sustainability_info'] != null) {
      _brandController.text = metadata['sustainability_info']['brand'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        title: const Text('Add New Item', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
           if (_analysisResult == null) ...[
              _buildImageUploadSection(),
              const SizedBox(height: 30),
              _buildAnalyzeButton(),
           ] else ...[
             _buildResultsView(),
           ]
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      children: [
        _buildUploadCard(
          title: 'Clothing Item',
          image: _itemImage,
          onTap: () => _showImageSourceModal(false),
          onClear: () => setState(() => _itemImage = null),
          isMain: true,
        ),
        const SizedBox(height: 20),
        _buildUploadCard(
          title: 'Care Tag (Optional)',
          image: _tagImage,
          onTap: () => _showImageSourceModal(true),
          onClear: () => setState(() => _tagImage = null),
          isMain: false,
        ),
      ],
    );
  }

  Widget _buildUploadCard({
    required String title,
    File? image,
    required VoidCallback onTap,
    required VoidCallback onClear,
    bool isMain = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: image == null ? onTap : null,
          child: Container(
            height: isMain ? 250 : 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: image != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(image, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: onClear,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 20, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  )
                : DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(20),
                    dashPattern: const [8, 4],
                    color: Colors.grey.shade400,
                    strokeWidth: 2,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isMain ? Icons.add_a_photo_outlined : Icons.tag_outlined,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isMain ? 'Tap to upload item' : 'Tap to upload tag',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    return _isLoading
        ? Container(
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                ),
                const SizedBox(width: 15),
                Text(
                  "AI-ul scanează materialul...",
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        : Container(
            height: 55,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.black, Color(0xFF2C2C2C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _analyzeItem,
                borderRadius: BorderRadius.circular(15),
                child: const Center(
                  child: Text(
                    "✨ Analyze with AI",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
  }

  Widget _buildResultsView() {
    Widget displayImage;
    if (_analysisResult != null && _analysisResult!['image_base64'] != null) {
      try {
        displayImage = Image.memory(
          base64Decode(_analysisResult!['image_base64']),
          fit: BoxFit.contain,
        );
      } catch (e) {
        debugPrint('Error decoding base64 image: $e');
        displayImage = Image.file(_itemImage!, fit: BoxFit.contain);
      }
    } else {
       displayImage = Image.file(_itemImage!, fit: BoxFit.contain);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: displayImage,
            ),
          ),
        ),
        const SizedBox(height: 30),
        const Text("AI Analysis Results", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _buildTextField("Category", _categoryController),
        _buildTextField("Sub Category", _subCategoryController),
        _buildTextField("Brand", _brandController),
        _buildTextField("Material", _materialController),
        _buildTextField("Color", _colorController),
        _buildTextField("Fit", _fitController),
        _buildTextField("Occasion", _occasionController),
        _buildTextField("Care Instructions", _careController, maxLines: 3),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () async {
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false, // Prevent dismissing by tapping outside
                builder: (BuildContext context) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                },
              );

              try {
                // Prepare metadata from form
                // We're updating the original metadata with user edits if needed, 
                // but for simplicity we'll take the form values where applicable.
                
                // Deep copy to not mutate original
                Map<String, dynamic> finalMetadata = jsonDecode(jsonEncode(_analysisResult!['metadata']));

                // Update basic info with text fields
                if (finalMetadata['basic_info'] == null) finalMetadata['basic_info'] = {};
                finalMetadata['basic_info']['category'] = _categoryController.text;
                finalMetadata['basic_info']['sub_category'] = _subCategoryController.text;
                finalMetadata['basic_info']['material'] = _materialController.text;
                finalMetadata['basic_info']['primary_colors'] = [_colorController.text]; // Simplify back to list

                if (finalMetadata['styling_info'] == null) finalMetadata['styling_info'] = {};
                finalMetadata['styling_info']['fit'] = _fitController.text;
                finalMetadata['styling_info']['style_occasions'] = [_occasionController.text];
                
                if (finalMetadata['laundry_info'] == null) finalMetadata['laundry_info'] = {};
                finalMetadata['laundry_info']['care_instructions'] = [_careController.text];

                if (finalMetadata['sustainability_info'] == null) finalMetadata['sustainability_info'] = {};
                finalMetadata['sustainability_info']['brand'] = _brandController.text;


                // Call Firebase Service
                await FirebaseService().saveItem(
                  itemImage: _itemImage!,
                  imageBase64: _analysisResult!['image_base64'], // Pass the bg-removed base64
                  metadata: finalMetadata,
                );

                // Hide loading
                if (mounted) Navigator.pop(context);

               // Show success
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Item saved to Wardrobe!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context); // Close screen
                }

              } catch (e) {
                // Hide loading
                if (mounted) Navigator.pop(context);
                
                // Show error
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to save: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text("Save to Wardrobe", style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
