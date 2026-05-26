import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/outfit_repository.dart';
import '../services/calendar_service.dart';

class SaveOutfitDialog extends StatefulWidget {
  final List<String> itemIds;
  final bool isAiGenerated;
  final bool isWearAction;
  final String? existingOutfitId;

  const SaveOutfitDialog({
    super.key,
    required this.itemIds,
    required this.isAiGenerated,
    this.isWearAction = false,
    this.existingOutfitId,
  });

  static Future<String?> show(
    BuildContext context, {
    required List<String> itemIds,
    required bool isAiGenerated,
    bool isWearAction = false,
    String? existingOutfitId,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => SaveOutfitDialog(
        itemIds: itemIds,
        isAiGenerated: isAiGenerated,
        isWearAction: isWearAction,
        existingOutfitId: existingOutfitId,
      ),
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
      final name = _nameController.text.trim();
      final outfitData = {
        'name': name,
        'item_ids': widget.itemIds,
        'rating': _rating.toDouble(),
        'is_ai_generated': widget.isAiGenerated,
        'created_by': widget.isAiGenerated ? 'AI Stylist' : 'User',
      };

      if (widget.isWearAction) {
        outfitData['wear_count'] = 1;
        outfitData['wear_dates'] = [Timestamp.now()];
      }

      String outfitId;
      if (widget.existingOutfitId != null && widget.isWearAction) {
        // If already saved and now we just want to wear it, we could just log wear.
        // But the user's prompt explicitly asks to "save the outfit to Firestore" with the dialog fields.
        // We will just do a save/update. Actually, let's just save it. Wait, if it exists, maybe we update?
        // Let's just follow the prompt perfectly: "save the outfit to Firestore".
        // For safety and to avoid duplicate creation from the dialog if existingOutfitId is provided,
        // we update the existing doc.
        outfitId = widget.existingOutfitId!;
        await FirebaseFirestore.instance
            .collection('outfits')
            .doc(outfitId)
            .update(outfitData);
      } else {
        outfitId = await OutfitRepository().saveOutfit(outfitData);
      }

      if (widget.isWearAction) {
        // Update clothing collection items' last_worn
        final batch = FirebaseFirestore.instance.batch();
        for (final itemId in widget.itemIds) {
          final itemRef = FirebaseFirestore.instance
              .collection('clothing')
              .doc(itemId);
          batch.update(itemRef, {'last_worn': FieldValue.serverTimestamp()});
        }
        await batch.commit();

        // Calendar Service
        await CalendarService().addOutfitEvent(name, DateTime.now());
      }

      if (mounted) {
        Navigator.of(context).pop(outfitId); // Close dialog and return ID
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isWearAction
                  ? 'Outfit logged as worn and saved to your collection!'
                  : 'Outfit saved successfully!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving outfit: $e')));
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
      title: Text(widget.isWearAction ? 'Wear this Look' : 'Save this Look'),
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
            const Text(
              'Rate this outfit:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
                const Text(
                  'Created by: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
              : Text(widget.isWearAction ? 'Wear' : 'Save'),
        ),
      ],
    );
  }
}
