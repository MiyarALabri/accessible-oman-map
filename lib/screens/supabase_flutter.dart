// Import Flutter material package
import 'package:flutter/material.dart';

// Import Supabase package
import 'package:supabase_flutter/supabase_flutter.dart';

// Filter screen widget
class FilterScreen extends StatefulWidget {

  // Callback function to return filtered places
  final Function(List<Map<String, dynamic>>) onApply;

  // Constructor
  const FilterScreen({super.key, required this.onApply});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

// State class for FilterScreen
class _FilterScreenState extends State<FilterScreen> {

  // Supabase client instance
  final supabase = Supabase.instance.client;

  // Filter options
  bool hasRamp = false;
  bool hasToilet = false;
  bool hasWideDoor = false;
  bool hasElevator = false;

  // Loading state
  bool loading = false;

  // Fetch filtered places from database
  Future<void> fetchFilteredPlaces() async {

    // Show loading indicator
    setState(() => loading = true);

    try {

      // Fetch all places from Supabase table
      final data = await supabase.from('places').select();

      // Convert response into a list
      final allPlaces = List<Map<String, dynamic>>.from(data);

      // Apply selected filters
      final places = allPlaces.where((p) {

        // Check wheelchair ramp filter
        if (hasRamp && p['has_ramp'] != true) return false;

        // Check accessible toilet filter
        if (hasToilet && p['has_toilet'] != true) return false;

        // Check wide door filter
        if (hasWideDoor && p['has_wide_door'] != true) return false;

        // Check elevator filter
        if (hasElevator && p['has_elevator'] != true) return false;

        return true;
      }).toList();

      // Send filtered places back to previous screen
      widget.onApply(places);

    } catch (e) {

      // Prevent errors if widget is removed
      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Filter error: $e'),
          backgroundColor: Colors.red,
        ),
      );

    } finally {

      // Stop loading
      if (mounted) setState(() => loading = false);
    }
  }

  // Apply filter button action
  void applyFilter() {

    // Check if no filter is selected
    if (!hasRamp && !hasToilet && !hasWideDoor && !hasElevator) {

      // Show warning message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one filter'),
        ),
      );

      return;
    }

    // Fetch filtered places
    fetchFilteredPlaces();
  }

  // Reset all selected filters
  void resetFilter() {

    setState(() {
      hasRamp = false;
      hasToilet = false;
      hasWideDoor = false;
      hasElevator = false;
    });
  }

  // Reusable filter card widget
  Widget _filterCard(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {

    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      child: SwitchListTile(

        // Padding inside card
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),

        // Icon avatar
        secondary: CircleAvatar(
          backgroundColor: const Color(0xFFE9F5EC),
          child: Icon(
            icon,
            color: const Color(0xFF12372A),
          ),
        ),

        // Main title
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),

        // Subtitle text
        subtitle: Text(subtitle),

        // Current switch value
        value: value,

        // Trigger when switch changes
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return ListView(
      padding: const EdgeInsets.all(16),

      children: [

        // Header image section
        ClipRRect(
          borderRadius: BorderRadius.circular(28),

          child: Stack(
            children: [

              // Background image
              Image.network(
                'https://images.unsplash.com/photo-1577495508048-b635879837f1?auto=format&fit=crop&w=1200&q=80',
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,

                // Show fallback color if image fails
                errorBuilder: (_, __, ___) => Container(
                  height: 150,
                  color: const Color(0xFF12372A),
                ),
              ),

              // Dark overlay with title
              Container(
                height: 150,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                ),

                child: const Align(
                  alignment: Alignment.bottomLeft,

                  child: Text(
                    'Choose accessibility needs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Ramp filter option
        _filterCard(
          'Wheelchair Ramp',
          'Show places with wheelchair ramps',
          Icons.accessible,
          hasRamp,
          (v) => setState(() => hasRamp = v),
        ),

        // Toilet filter option
        _filterCard(
          'Accessible Toilet',
          'Show places with disabled-friendly toilets',
          Icons.wc,
          hasToilet,
          (v) => setState(() => hasToilet = v),
        ),

        // Wide door filter option
        _filterCard(
          'Wide Door',
          'Show places with wide entrances',
          Icons.door_front_door,
          hasWideDoor,
          (v) => setState(() => hasWideDoor = v),
        ),

        // Elevator filter option
        _filterCard(
          'Elevator',
          'Show places with accessible elevators',
          Icons.elevator,
          hasElevator,
          (v) => setState(() => hasElevator = v),
        ),

        const SizedBox(height: 8),

        // Apply filter button
        ElevatedButton.icon(
          onPressed: loading ? null : applyFilter,

          // Show loading indicator while fetching
          icon: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.filter_alt),

          label: const Text('Apply Filter'),
        ),

        // Reset filter button
        TextButton.icon(
          onPressed: loading ? null : resetFilter,
          icon: const Icon(Icons.restart_alt),
          label: const Text('Reset Selection'),
        ),
      ],
    );
  }
}