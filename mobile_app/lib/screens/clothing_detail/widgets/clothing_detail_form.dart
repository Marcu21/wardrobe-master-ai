import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/services/wardrobe_state_service.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'package:mobile_app/widgets/scale_button.dart';

class ClothingDetailForm extends StatelessWidget {
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
  final String? currentWardrobeId;
  final void Function(String?) onWardrobeChanged;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  const ClothingDetailForm({
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
    required this.currentWardrobeId,
    required this.onWardrobeChanged,
    required this.onSave,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'DETAILS',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.35),
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Edit item info',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),

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
              _buildField(
                'Occasions (comma separated)',
                styleOccasionsController,
              ),
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

          const SizedBox(height: 20),

          ScaleButton(
            onTap: onSave,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B52F0), Color(0xFF3730C8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    CupertinoIcons.checkmark_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          ScaleButton(
            onTap: onDelete,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFDC2626).withOpacity(0.25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    CupertinoIcons.delete,
                    color: Color(0xFFDC2626),
                    size: 17,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Delete Item',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
    return AnimatedBuilder(
      animation: wardrobeStateService,
      builder: (context, _) {
        final wardrobes = wardrobeStateService.wardrobes;
        final isValid =
            currentWardrobeId == null ||
            wardrobes.any((w) => w['id'] == currentWardrobeId);
        final dropdownValue = isValid ? currentWardrobeId : null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String?>(
            value: dropdownValue,
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
            onChanged: (val) => onWardrobeChanged(val),
          ),
        );
      },
    );
  }
}
