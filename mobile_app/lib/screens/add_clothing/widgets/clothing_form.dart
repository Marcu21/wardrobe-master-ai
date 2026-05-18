import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/services/wardrobe_state_service.dart';
import 'package:mobile_app/theme/app_colors.dart';

class ClothingForm extends StatelessWidget {
  final TextEditingController categoryController;
  final TextEditingController subCategoryController;
  final TextEditingController materialController;
  final TextEditingController primaryColorController;
  final TextEditingController patternController;
  final TextEditingController brandController;
  final TextEditingController priceController;
  final TextEditingController currencyController;
  final TextEditingController purchaseDateController;
  final TextEditingController fitController;
  final TextEditingController lengthController;
  final TextEditingController necklineController;
  final TextEditingController sleeveLengthController;
  final TextEditingController styleOccasionsController;
  final TextEditingController seasonalityController;
  final TextEditingController careInstructionsController;
  final TextEditingController colorGroupController;
  final TextEditingController maxTempController;
  final String? selectedWardrobeId;
  final void Function(String?) onWardrobeChanged;

  const ClothingForm({
    super.key,
    required this.categoryController,
    required this.subCategoryController,
    required this.materialController,
    required this.primaryColorController,
    required this.patternController,
    required this.brandController,
    required this.priceController,
    required this.currencyController,
    required this.purchaseDateController,
    required this.fitController,
    required this.lengthController,
    required this.necklineController,
    required this.sleeveLengthController,
    required this.styleOccasionsController,
    required this.seasonalityController,
    required this.careInstructionsController,
    required this.colorGroupController,
    required this.maxTempController,
    required this.selectedWardrobeId,
    required this.onWardrobeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFormSection(
          icon: CupertinoIcons.info_circle,
          title: 'Basic Info',
          children: [
            _buildWardrobeDropdown(),
            _buildField('Category', categoryController),
            _buildField('Sub Category', subCategoryController),
            _buildField('Material', materialController),
            _buildField('Colors (comma separated)', primaryColorController),
            _buildField('Pattern', patternController, isLast: true),
          ],
        ),
        const SizedBox(height: 14),

        _buildFormSection(
          icon: CupertinoIcons.leaf_arrow_circlepath,
          title: 'Sustainability & Purchase',
          children: [
            _buildField('Brand', brandController),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    'Price',
                    priceController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildField(
                    'Currency',
                    currencyController,
                    isLast: true,
                  ),
                ),
              ],
            ),
            _buildField(
              'Purchase Date',
              purchaseDateController,
              hint: 'YYYY-MM-DD',
              isLast: true,
            ),
          ],
        ),
        const SizedBox(height: 14),

        _buildFormSection(
          icon: CupertinoIcons.pencil_outline,
          title: 'Styling',
          children: [
            _buildField('Fit', fitController),
            _buildField('Length', lengthController),
            _buildField('Neckline', necklineController),
            _buildField('Sleeve Length', sleeveLengthController),
            _buildField('Occasions (comma separated)', styleOccasionsController),
            _buildField(
              'Seasonality (comma separated)',
              seasonalityController,
              isLast: true,
            ),
          ],
        ),
        const SizedBox(height: 14),

        _buildFormSection(
          icon: CupertinoIcons.thermometer,
          title: 'Laundry & Care',
          children: [
            _buildField(
              'Care Instructions (one per line)',
              careInstructionsController,
              maxLines: 4,
            ),
            _buildField('Color Group', colorGroupController),
            _buildField(
              'Max Temp (°C)',
              maxTempController,
              keyboardType: TextInputType.number,
              isLast: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: kPrimaryLight,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 14, color: kPrimary),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 18),
            color: Colors.black.withOpacity(0.05),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hint,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 10 : 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: Colors.black.withOpacity(0.45),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: Colors.black.withOpacity(0.03),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildWardrobeDropdown() {
    final wardrobes = wardrobeStateService.wardrobes;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String?>(
        value: selectedWardrobeId,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: 'Wardrobe',
          labelStyle: TextStyle(
            color: Colors.black.withOpacity(0.45),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: Colors.black.withOpacity(0.03),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
        ),
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('All Wardrobes'),
          ),
          ...wardrobes.map(
            (w) => DropdownMenuItem<String?>(
              value: w['id'],
              child: Text(w['name']),
            ),
          ),
        ],
        onChanged: onWardrobeChanged,
      ),
    );
  }
}
