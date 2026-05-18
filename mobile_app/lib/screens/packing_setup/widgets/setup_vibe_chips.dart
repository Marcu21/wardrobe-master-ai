import 'package:flutter/material.dart';

class SetupVibeChips extends StatelessWidget {
  final String? selectedVibe;
  final void Function(String?) onVibeSelected;

  const SetupVibeChips({
    super.key,
    required this.selectedVibe,
    required this.onVibeSelected,
  });

  Widget _buildChip(String vibe) {
    final isSelected = selectedVibe == vibe;
    return ChoiceChip(
      labelPadding: EdgeInsets.zero,
      label: Container(
        width: double.infinity,
        alignment: Alignment.center,
        child: Text(
          vibe,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) => onVibeSelected(selected ? vibe : null),
      selectedColor: Colors.blueAccent,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? Colors.blueAccent : Colors.grey.shade300,
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(vertical: 12.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildChip('Business')),
            const SizedBox(width: 8),
            Expanded(child: _buildChip('Vacation')),
            const SizedBox(width: 8),
            Expanded(child: _buildChip('Event')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildChip('City Break')),
            const SizedBox(width: 8),
            Expanded(child: _buildChip('Beach')),
            const SizedBox(width: 8),
            Expanded(child: _buildChip('Skiing')),
          ],
        ),
      ],
    );
  }
}
