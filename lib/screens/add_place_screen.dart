import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descController = TextEditingController();

  bool hasRamp = false;
  bool hasToilet = false;
  bool hasWideDoor = false;
  bool hasElevator = false;

  LatLng selectedLocation = const LatLng(23.5880, 58.3829);
  bool isLoading = false;

  final supabase = Supabase.instance.client;

  Future<void> savePlace() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await supabase.from('places').insert({
        'name': nameController.text.trim(),
        'description': descController.text.trim(),
        'lat': selectedLocation.latitude,
        'lng': selectedLocation.longitude,
        'has_ramp': hasRamp,
        'has_toilet': hasToilet,
        'has_wide_door': hasWideDoor,
        'has_elevator': hasElevator,
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descController.dispose();
    super.dispose();
  }

  Widget _optionTile(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        secondary: Icon(icon, color: const Color(0xFF12372A)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Accessible Place')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: selectedLocation,
              initialZoom: 12,
              onTap: (_, point) => setState(() => selectedLocation = point),
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              MarkerLayer(
                markers: [
                  Marker(
                    point: selectedLocation,
                    width: 64,
                    height: 64,
                    child: const Icon(Icons.location_pin, color: Colors.red, size: 48),
                  ),
                ],
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: DraggableScrollableSheet(
              initialChildSize: 0.55,
              minChildSize: 0.33,
              maxChildSize: 0.88,
              builder: (context, controller) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F8F3),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 18)],
                  ),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      controller: controller,
                      padding: const EdgeInsets.all(18),
                      children: [
                        Center(
                          child: Container(
                            width: 46,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Tap on the map to select the exact location.', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: 'Place Name', prefixIcon: Icon(Icons.place_outlined)),
                          validator: (value) => (value ?? '').trim().isEmpty ? 'Enter place name' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: descController,
                          minLines: 2,
                          maxLines: 3,
                          decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.notes_outlined)),
                          validator: (value) => (value ?? '').trim().isEmpty ? 'Enter description' : null,
                        ),
                        const SizedBox(height: 14),
                        _optionTile('Wheelchair Ramp', 'Entrance supports wheelchair access', Icons.accessible, hasRamp, (v) => setState(() => hasRamp = v)),
                        _optionTile('Accessible Toilet', 'Toilet is suitable for disabled users', Icons.wc, hasToilet, (v) => setState(() => hasToilet = v)),
                        _optionTile('Wide Door', 'Door is wide enough for wheelchair users', Icons.door_front_door, hasWideDoor, (v) => setState(() => hasWideDoor = v)),
                        _optionTile('Elevator', 'Elevator is available and accessible', Icons.elevator, hasElevator, (v) => setState(() => hasElevator = v)),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isLoading ? null : savePlace,
                            icon: isLoading
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.save_alt),
                            label: const Text('Save Place'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
