import 'package:flutter/material.dart';
import '../services/wardrobe_state_service.dart';

class GlobalWardrobeSelector extends StatefulWidget {
  final bool isActionItem;

  const GlobalWardrobeSelector({
    super.key,
    this.isActionItem = false,
  });

  @override
  State<GlobalWardrobeSelector> createState() => _GlobalWardrobeSelectorState();
}

class _GlobalWardrobeSelectorState extends State<GlobalWardrobeSelector> {

  String _getActiveWardrobeName() {
    final activeId = wardrobeStateService.activeWardrobeId;
    if (activeId == null) return widget.isActionItem ? "All" : "All Wardrobes";
    final wardrobe = wardrobeStateService.wardrobes.firstWhere(
      (w) => w['id'] == activeId,
      orElse: () => {'name': widget.isActionItem ? 'All' : 'All Wardrobes'}
    );
    return wardrobe['name'];
  }

  void _showCreateDialog() {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Wardrobe'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'e.g., Summer Vacation',
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(context);
                  await wardrobeStateService.createWardrobe(name);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text('Create', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(Map<String, dynamic> wardrobe) {
    final TextEditingController nameController = TextEditingController(text: wardrobe['name'] ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Wardrobe'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'New Wardrobe Name',
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty && newName != wardrobe['name']) {
                  Navigator.pop(context);
                  await wardrobeStateService.updateWardrobe(wardrobe['id'], newName);
                } else {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> wardrobe) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Wardrobe?'),
          content: Text(
            'Are you sure you want to delete "${wardrobe['name']}"?\n\n'
            'Any clothing currently assigned to this wardrobe will NOT be deleted, but will instead be moved to "All Wardrobes".',
            style: const TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await wardrobeStateService.deleteWardrobe(wardrobe['id']);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Wardrobe deleted successfully.')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete wardrobe: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showWardrobeManagerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return AnimatedBuilder(
          animation: wardrobeStateService,
          builder: (builderContext, _) {
            final wardrobes = wardrobeStateService.wardrobes;
            final activeId = wardrobeStateService.activeWardrobeId;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Manage Wardrobes',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.checkroom),
                            title: const Text('All Wardrobes', style: TextStyle(fontWeight: FontWeight.w600)),
                            trailing: activeId == null ? const Icon(Icons.check, color: Colors.green) : null,
                            onTap: () {
                              wardrobeStateService.setActiveWardrobe(null);
                              Navigator.pop(sheetContext);
                            },
                          ),
                          ...wardrobes.map((w) {
                            final isSelected = activeId == w['id'];
                            return ListTile(
                              leading: const Icon(Icons.checkroom),
                              title: Text(w['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                              onTap: () {
                                wardrobeStateService.setActiveWardrobe(w['id']);
                                Navigator.pop(sheetContext);
                              },
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected) const Icon(Icons.check, color: Colors.green),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                                    onPressed: () => _showEditDialog(w),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                    onPressed: () => _showDeleteConfirmation(w),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          _showCreateDialog();
                        },
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Add New Wardrobe', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: wardrobeStateService,
      builder: (context, _) {
        final activeName = _getActiveWardrobeName();

        if (widget.isActionItem) {
          // Compact UI for placing in AppBar actions (e.g. VirtualDressingRoom, Stylist)
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: InkWell(
                onTap: () => _showWardrobeManagerSheet(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.checkroom, size: 16, color: Colors.black87),
                      const SizedBox(width: 4),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                         child: ConstrainedBox(
                           key: ValueKey(activeName),
                           constraints: const BoxConstraints(maxWidth: 80), // limit width to not squeeze appbar 
                           child: Text(
                             activeName,
                             style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                             overflow: TextOverflow.ellipsis,
                           ),
                         ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black54),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Default: Centered Title format (for WardrobeGallery, Laundry)
        return GestureDetector(
          onTap: () => _showWardrobeManagerSheet(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                 duration: const Duration(milliseconds: 300),
                 child: Text(
                   activeName,
                   key: ValueKey(activeName),
                   style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
                 ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: Colors.black),
            ],
          ),
        );
      },
    );
  }
}
