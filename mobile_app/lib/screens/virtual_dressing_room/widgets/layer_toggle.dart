import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LayerToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const LayerToggle({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: value ? Colors.deepPurple.withOpacity(0.06) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? Colors.deepPurple.withOpacity(0.20)
              : Colors.black.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value
                  ? Colors.deepPurple.withOpacity(0.10)
                  : Colors.black.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: value ? Colors.deepPurple : Colors.black45,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: value ? Colors.deepPurple : Colors.black87,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeColor: Colors.deepPurple,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
