import 'package:flutter/material.dart';

class SetupLuggageSelector extends StatelessWidget {
  final String selectedLuggage;
  final ValueChanged<String> onLuggageSelected;

  const SetupLuggageSelector({
    super.key,
    required this.selectedLuggage,
    required this.onLuggageSelected,
  });

  Widget _buildOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = selectedLuggage == value;
    return InkWell(
      onTap: () => onLuggageSelected(value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.grey.shade300,
            width: isSelected ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blueAccent : Colors.grey.shade600,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildOption(
          'Backpack',
          'Backpack',
          'Minimalist (~6-8 items)',
          Icons.backpack_outlined,
        ),
        const SizedBox(height: 8),
        _buildOption(
          'Carry-on',
          'Carry-on',
          'Standard Capsule (~10-14 items)',
          Icons.luggage_outlined,
        ),
        const SizedBox(height: 8),
        _buildOption(
          'Checked Bag',
          'Checked Bag',
          'Comfort & Variety (No strict limit)',
          Icons.cases_outlined,
        ),
      ],
    );
  }
}
