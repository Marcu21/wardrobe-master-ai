
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class SaveOutfitDialog extends StatefulWidget {
  final List<String> itemIds;
  final bool isAiGenerated;

  const SaveOutfitDialog({
    Key? key,
    required this.itemIds,
    required this.isAiGenerated,
  }) : super(key: key);

  static Future<void> show(BuildContext context, {required List<String> itemIds, required bool isAiGenerated}) {
    return showDialog(
      context: context,
      builder: (context) => SaveOutfitDialog(itemIds: itemIds, isAiGenerated: isAiGenerated),
    );
  }

  @override
  State<SaveOutfitDialog> createState() => _SaveOutfitDialogState();
}

class _SaveOutfitDialogState extends State<SaveOutfitDialog> {
  final TextEditingController _nameController = TextEditingController();
  int _rating = 5;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveOutfit() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an outfit name')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseService().saveOutfit({
        'name': _nameController.text.trim(),
        'item_ids': widget.itemIds,
        'rating': _rating.toDouble(),
        'is_ai_generated': widget.isAiGenerated,
      });

      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Outfit saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving outfit: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save this Look'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Outfit Name',
                hintText: 'e.g., Casual Friday',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            const Text('Rate this outfit:', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Created by: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Icon(
                  widget.isAiGenerated ? Icons.auto_awesome : Icons.person,
                  color: widget.isAiGenerated ? Colors.purple : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(widget.isAiGenerated ? 'AI Stylist' : 'You'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveOutfit,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
