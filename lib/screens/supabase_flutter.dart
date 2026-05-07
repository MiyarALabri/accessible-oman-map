import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FilterScreen extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onApply;

  const FilterScreen({super.key, required this.onApply});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  final supabase = Supabase.instance.client;

  bool hasRamp = false;
  bool hasToilet = false;
  bool hasWideDoor = false;
  bool hasElevator = false;
  bool loading = false;

  Future<void> fetchFilteredPlaces() async {
    setState(() => loading = true);

    try {
      final data = await supabase.from('places').select();
      final allPlaces = List<Map<String, dynamic>>.from(data);

      final places = allPlaces.where((p) {
        if (hasRamp && p['has_ramp'] != true) return false;
        if (hasToilet && p['has_toilet'] != true) return false;
        if (hasWideDoor && p['has_wide_door'] != true) return false;
        if (hasElevator && p['has_elevator'] != true) return false;
        return true;
      }).toList();

      widget.onApply(places);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Filter error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void applyFilter() {
    if (!hasRamp && !hasToilet && !hasWideDoor && !hasElevator) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one filter')),
      );
      return;
    }
    fetchFilteredPlaces();
  }

  void resetFilter() {
    setState(() {
      hasRamp = false;
      hasToilet = false;
      hasWideDoor = false;
      hasElevator = false;
    });
  }

  Widget _filterCard(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        secondary: CircleAvatar(
          backgroundColor: const Color(0xFFE9F5EC),
          child: Icon(icon, color: const Color(0xFF12372A)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Image.network(
                'https://images.unsplash.com/photo-1577495508048-b635879837f1?auto=format&fit=crop&w=1200&q=80',
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(height: 150, color: const Color(0xFF12372A)),
              ),
              Container(
                height: 150,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.35)),
                child: const Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'Choose accessibility needs',
                    style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _filterCard('Wheelchair Ramp', 'Show places with wheelchair ramps', Icons.accessible, hasRamp, (v) => setState(() => hasRamp = v)),
        _filterCard('Accessible Toilet', 'Show places with disabled-friendly toilets', Icons.wc, hasToilet, (v) => setState(() => hasToilet = v)),
        _filterCard('Wide Door', 'Show places with wide entrances', Icons.door_front_door, hasWideDoor, (v) => setState(() => hasWideDoor = v)),
        _filterCard('Elevator', 'Show places with accessible elevators', Icons.elevator, hasElevator, (v) => setState(() => hasElevator = v)),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: loading ? null : applyFilter,
          icon: loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.filter_alt),
          label: const Text('Apply Filter'),
        ),
        TextButton.icon(
          onPressed: loading ? null : resetFilter,
          icon: const Icon(Icons.restart_alt),
          label: const Text('Reset Selection'),
        ),
      ],
    );
  }
}
