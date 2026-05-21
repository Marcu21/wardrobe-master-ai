import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/widgets/global_wardrobe_selector.dart';
import 'package:mobile_app/navigation/app_routes.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'widgets/setup_vibe_chips.dart';
import 'widgets/setup_luggage_selector.dart';

const _kBlob1 = Color(0x3840C4FF);
const _kBlob2 = Color(0x1E1565C0);

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

  @override
  void dispose() {
    _destinationController.dispose();
    _tripPlansController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
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

    Navigator.pushNamed(
      context,
      AppRoutes.tripView,
      arguments: TripViewArgs(
        destination: _destinationController.text.trim(),
        days: days,
        vibe: _selectedVibe!,
        dateRange: _selectedDateRange!,
        tripPlans: _tripPlansController.text.trim().isNotEmpty
            ? _tripPlansController.text.trim()
            : null,
        luggageSize: _selectedLuggage,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: kBgColor)),
          Positioned(
            top: -80,
            right: -60,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kBlob1,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -60,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kBlob2,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 4,
                    left: 4,
                    right: 4,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          CupertinoIcons.back,
                          color: Colors.black87,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'Plan Your Trip',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                        ),
                      ),
                      const GlobalWardrobeSelector(isActionItem: true),
                    ],
                  ),
                ),
                Expanded(
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
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 16),
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
                                width:
                                    _selectedDateRange != null ? 2 : 1.5,
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
                          padding: const EdgeInsets.only(
                            top: 8,
                            left: 4,
                            right: 4,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 14,
                                color: Colors.grey[600],
                              ),
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
                        SetupVibeChips(
                          selectedVibe: _selectedVibe,
                          onVibeSelected: (vibe) =>
                              setState(() => _selectedVibe = vibe),
                        ),
                        const SizedBox(height: 32),

                        _buildSectionTitle('Luggage Size'),
                        const SizedBox(height: 12),
                        SetupLuggageSelector(
                          selectedLuggage: _selectedLuggage,
                          onLuggageSelected: (val) =>
                              setState(() => _selectedLuggage = val),
                        ),
                        const SizedBox(height: 32),

                        _buildSectionTitle(
                          'Trip Plans & Itinerary (Optional)',
                        ),
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
                              backgroundColor: Colors.black87,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              shadowColor:
                                  Colors.black.withOpacity(0.3),
                            ),
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text(
                              'Generate Capsule Wardrobe',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
