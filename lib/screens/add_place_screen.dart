// Import Flutter material package
import 'package:flutter/material.dart';

// Import Flutter map package
import 'package:flutter_map/flutter_map.dart';

// Import latitude and longitude package
import 'package:latlong2/latlong.dart';

// Import Supabase package
import 'package:supabase_flutter/supabase_flutter.dart';

// Add Place screen widget
class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() =>
      _AddPlaceScreenState();
}

// State class for AddPlaceScreen
class _AddPlaceScreenState
    extends State<AddPlaceScreen> {

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Controller for place name
  final nameController =
      TextEditingController();

  // Controller for description
  final descController =
      TextEditingController();

  // Accessibility feature states
  bool hasRamp = false;
  bool hasToilet = false;
  bool hasWideDoor = false;
  bool hasElevator = false;

  // Default selected map location
  LatLng selectedLocation =
      const LatLng(23.5880, 58.3829);

  // Loading state
  bool isLoading = false;

  // Supabase client instance
  final supabase = Supabase.instance.client;

  // Save place into database
  Future<void> savePlace() async {

    // Validate form fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Enable loading state
    setState(() => isLoading = true);

    try {

      // Insert place data into Supabase
      await supabase.from('places').insert({

        'name':
            nameController.text.trim(),

        'description':
            descController.text.trim(),

        'lat':
            selectedLocation.latitude,

        'lng':
            selectedLocation.longitude,

        'has_ramp':
            hasRamp,

        'has_toilet':
            hasToilet,

        'has_wide_door':
            hasWideDoor,

        'has_elevator':
            hasElevator,
      });

      if (!mounted) return;

      // Close screen after success
      Navigator.pop(context, true);

    } catch (e) {

      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );

    } finally {

      // Disable loading state
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {

    // Dispose controllers
    nameController.dispose();
    descController.dispose();

    super.dispose();
  }

  // Accessibility option tile widget
  Widget _optionTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {

    return Card(
      margin: const EdgeInsets.only(bottom: 8),

      child: SwitchListTile(

        // Feature icon
        secondary: Icon(
          icon,
          color: const Color(0xFF12372A),
        ),

        // Feature title
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),

        // Feature description
        subtitle: Text(subtitle),

        // Switch value
        value: value,

        // Update switch state
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      // Screen app bar
      appBar: AppBar(
        title: const Text(
          'Add Accessible Place',
        ),
      ),

      body: Stack(
        children: [

          // Interactive map widget
          FlutterMap(

            options: MapOptions(

              // Initial map location
              initialCenter: selectedLocation,

              // Initial zoom level
              initialZoom: 12,

              // Update selected location on tap
              onTap: (_, point) =>
                  setState(() =>
                      selectedLocation = point),
            ),

            children: [

              // OpenStreetMap tiles
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),

              // Marker layer
              MarkerLayer(

                markers: [

                  // Selected location marker
                  Marker(
                    point: selectedLocation,

                    width: 64,
                    height: 64,

                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 48,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Bottom draggable form
          Align(
            alignment: Alignment.bottomCenter,

            child: DraggableScrollableSheet(

              // Initial sheet size
              initialChildSize: 0.55,

              // Minimum sheet size
              minChildSize: 0.33,

              // Maximum sheet size
              maxChildSize: 0.88,

              builder: (context, controller) {

                return Container(

                  decoration: const BoxDecoration(

                    color: Color(0xFFF7F8F3),

                    borderRadius:
                        BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 18,
                      ),
                    ],
                  ),

                  child: Form(
                    key: _formKey,

                    child: ListView(
                      controller: controller,

                      padding:
                          const EdgeInsets.all(18),

                      children: [

                        // Drag handle indicator
                        Center(
                          child: Container(
                            width: 46,
                            height: 5,

                            decoration: BoxDecoration(
                              color:
                                  Colors.grey.shade400,

                              borderRadius:
                                  BorderRadius.circular(
                                99,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Instructions text
                        const Text(
                          'Tap on the map to select the exact location.',

                          style: TextStyle(
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Place name field
                        TextFormField(

                          controller:
                              nameController,

                          decoration:
                              const InputDecoration(

                            labelText: 'Place Name',

                            prefixIcon: Icon(
                              Icons.place_outlined,
                            ),
                          ),

                          // Validate place name
                          validator: (value) {

                            return (value ?? '')
                                    .trim()
                                    .isEmpty
                                ? 'Enter place name'
                                : null;
                          },
                        ),

                        const SizedBox(height: 12),

                        // Description field
                        TextFormField(

                          controller:
                              descController,

                          minLines: 2,
                          maxLines: 3,

                          decoration:
                              const InputDecoration(

                            labelText: 'Description',

                            prefixIcon: Icon(
                              Icons.notes_outlined,
                            ),
                          ),

                          // Validate description
                          validator: (value) {

                            return (value ?? '')
                                    .trim()
                                    .isEmpty
                                ? 'Enter description'
                                : null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // Accessibility options
                        _optionTile(
                          'Wheelchair Ramp',
                          'Entrance supports wheelchair access',
                          Icons.accessible,
                          hasRamp,
                          (v) =>
                              setState(() => hasRamp = v),
                        ),

                        _optionTile(
                          'Accessible Toilet',
                          'Toilet is suitable for disabled users',
                          Icons.wc,
                          hasToilet,
                          (v) => setState(
                              () => hasToilet = v),
                        ),

                        _optionTile(
                          'Wide Door',
                          'Door is wide enough for wheelchair users',
                          Icons.door_front_door,
                          hasWideDoor,
                          (v) => setState(
                              () => hasWideDoor = v),
                        ),

                        _optionTile(
                          'Elevator',
                          'Elevator is available and accessible',
                          Icons.elevator,
                          hasElevator,
                          (v) => setState(
                              () => hasElevator = v),
                        ),

                        const SizedBox(height: 10),

                        // Save button
                        SizedBox(
                          width: double.infinity,

                          child: ElevatedButton.icon(

                            // Disable button while loading
                            onPressed:
                                isLoading
                                    ? null
                                    : savePlace,

                            // Loading indicator
                            icon: isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,

                                    child:
                                        CircularProgressIndicator(
                                      color:
                                          Colors.white,

                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.save_alt,
                                  ),

                            label:
                                const Text(
                              'Save Place',
                            ),
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