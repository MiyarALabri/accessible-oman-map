class Place {
  final String id;
  final String name;
  final String description;
  final double lat;
  final double lng;

  final bool hasRamp;
  final bool hasToilet;
  final bool hasWideDoor;
  final bool hasElevator;

  final String? imageUrl;

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

  // 🔥 تحويل من Supabase → Object
  factory Place.fromJson(Map<String, dynamic> json) {
  return Place(
    id: json['id'].toString(), // 🔥 مهم
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    lat: double.tryParse(json['lat'].toString()) ?? 0,
    lng: double.tryParse(json['lng'].toString()) ?? 0,
    hasRamp: json['has_ramp'] ?? false,
    hasToilet: json['has_toilet'] ?? false,
    hasWideDoor: json['has_wide_door'] ?? false,
    hasElevator: json['has_elevator'] ?? false,
    imageUrl: json['image_url'],
  );
}

  // 🔥 تحويل Object → Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'lat': lat,
      'lng': lng,
      'has_ramp': hasRamp,
      'has_toilet': hasToilet,
      'has_wide_door': hasWideDoor,
      'has_elevator': hasElevator,
      'image_url': imageUrl,
    };
  }
}
