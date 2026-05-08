// Place model class
class Place {

  // Unique place ID
  final String id;

  // Place name
  final String name;

  // Place description
  final String description;

  // Latitude coordinate
  final double lat;

  // Longitude coordinate
  final double lng;

  // Accessibility features
  final bool hasRamp;
  final bool hasToilet;
  final bool hasWideDoor;
  final bool hasElevator;

  // Optional image URL
  final String? imageUrl;

  // Constructor
  Place({
    required this.id,
    required this.name,
    required this.description,
    required this.lat,
    required this.lng,
    required this.hasRamp,
    required this.hasToilet,
    required this.hasWideDoor,
    required this.hasElevator,
    this.imageUrl,
  });

  // Convert Supabase JSON data into Place object
  factory Place.fromJson(
    Map<String, dynamic> json,
  ) {

    return Place(

      // Convert ID to string
      id: json['id'].toString(),

      // Place name
      name: json['name'] ?? '',

      // Place description
      description:
          json['description'] ?? '',

      // Parse latitude value
      lat: double.tryParse(
            json['lat'].toString(),
          ) ??
          0,

      // Parse longitude value
      lng: double.tryParse(
            json['lng'].toString(),
          ) ??
          0,

      // Accessibility features
      hasRamp:
          json['has_ramp'] ?? false,

      hasToilet:
          json['has_toilet'] ?? false,

      hasWideDoor:
          json['has_wide_door'] ?? false,

      hasElevator:
          json['has_elevator'] ?? false,

      // Place image URL
      imageUrl: json['image_url'],
    );
  }

  // Convert Place object into JSON map
  Map<String, dynamic> toJson() {

    return {

      // Place ID
      'id': id,

      // Place name
      'name': name,

      // Place description
      'description': description,

      // Latitude value
      'lat': lat,

      // Longitude value
      'lng': lng,

      // Accessibility features
      'has_ramp': hasRamp,

      'has_toilet': hasToilet,

      'has_wide_door': hasWideDoor,

      'has_elevator': hasElevator,

      // Image URL
      'image_url': imageUrl,
    };
  }
}