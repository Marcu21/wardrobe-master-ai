import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/global_wardrobe_selector.dart';
import 'trip_view_screen.dart';

class PackingSetupScreen extends StatefulWidget {
  const PackingSetupScreen({super.key});

  @override
  State<PackingSetupScreen> createState() => _PackingSetupScreenState();
}

class _PackingSetupScreenState extends State<PackingSetupScreen> {
  final _destinationController = TextEditingController();
  final _tripPlansController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  String? _selectedVibe;
  String _selectedLuggage = 'Carry-on';

  final List<String> _vibes = [
    'Business',
    'City Break',
    'Vacation',
    'Beach',
    'Skiing',
    'Event',
  ];

  @override
  void dispose() {
    _destinationController.dispose();
    _tripPlansController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    // Hide the keyboard if it is visible
    FocusScope.of(context).unfocus();

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _generateCapsuleWardrobe() {
    FocusScope.of(context).unfocus();

    if (_destinationController.text.trim().isEmpty ||
        _selectedDateRange == null ||
        _selectedVibe == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please enter a destination, select travel dates, and pick a vibe.',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final days = _selectedDateRange!.duration.inDays + 1;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TripViewScreen(
          destination: _destinationController.text.trim(),
          days: days,
          vibe: _selectedVibe!,
          dateRange: _selectedDateRange!,
          tripPlans: _tripPlansController.text.trim().isNotEmpty
              ? _tripPlansController.text.trim()
              : null,
          luggageSize: _selectedLuggage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0, // Material 3 transparent fix
        title: const Text(
          'Plan Your Trip',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: const [GlobalWardrobeSelector(isActionItem: true)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildSectionTitle('Where are you going?'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _destinationController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'e.g., Milan, Italy',
                  prefixIcon: const Icon(
                    Icons.flight_takeoff,
                    color: Colors.blueAccent,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Colors.blueAccent,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('When?'),
              const SizedBox(height: 12),
              InkWell(
                onTap: _selectDateRange,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedDateRange != null
                          ? Colors.blueAccent
                          : Colors.grey.shade300,
                      width: _selectedDateRange != null ? 2 : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: _selectedDateRange != null
                            ? Colors.blueAccent
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDateRange != null
                            ? '${DateFormat('MMM d').format(_selectedDateRange!.start)} - ${DateFormat('MMM d').format(_selectedDateRange!.end)}'
                            : 'Select Dates',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedDateRange != null
                              ? Colors.black87
                              : Colors.black54,
                          fontWeight: _selectedDateRange != null
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Note: Precise weather forecast is available for trips starting within the next 5 days. For later dates, we'll use seasonal averages to suggest your wardrobe.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('Trip Vibe (Optional)'),
              const SizedBox(height: 12),
              Column(
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
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('Luggage Size'),
              const SizedBox(height: 12),
              _buildLuggageOption(
                'Backpack',
                'Backpack',
                'Minimalist (~6-8 items)',
                Icons.backpack_outlined,
              ),
              const SizedBox(height: 8),
              _buildLuggageOption(
                'Carry-on',
                'Carry-on',
                'Standard Capsule (~10-14 items)',
                Icons.luggage_outlined,
              ),
              const SizedBox(height: 8),
              _buildLuggageOption(
                'Checked Bag',
                'Checked Bag',
                'Comfort & Variety (No strict limit)',
                Icons.cases_outlined,
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('Trip Plans & Itinerary (Optional)'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tripPlansController,
                textInputAction: TextInputAction.done,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'e.g., Visiting museums, hiking on Tuesday, fancy dinner...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Colors.blueAccent,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generateCapsuleWardrobe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87, // Primary action color
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: Colors.black.withOpacity(0.3),
                  ),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text(
                    'Generate Capsule Wardrobe',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildChip(String vibe) {
    final isSelected = _selectedVibe == vibe;
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
      onSelected: (selected) {
        setState(() {
          _selectedVibe = selected ? vibe : null;
        });
      },
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

  Widget _buildLuggageOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _selectedLuggage == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedLuggage = value;
        });
      },
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
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
}

class _SmartLoadingDialog extends StatefulWidget {
  const _SmartLoadingDialog();

  @override
  State<_SmartLoadingDialog> createState() => _SmartLoadingDialogState();
}

class _SmartLoadingDialogState extends State<_SmartLoadingDialog>
    with SingleTickerProviderStateMixin {
  final List<String> _messages = [
    "Analyzing weather...",
    "Selecting best fabrics...",
    "Color matching...",
    "Folding your outfits...",
  ];
  int _currentIndex = 0;
  Timer? _timer;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _messages.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -5 * _controller.value),
                    child: child,
                  );
                },
                child: const Icon(
                  Icons.luggage,
                  size: 60,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _messages[_currentIndex],
                  key: ValueKey<int>(_currentIndex),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
