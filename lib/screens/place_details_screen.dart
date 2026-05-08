// Import Flutter material package
import 'package:flutter/material.dart';

// Import image picker package
import 'package:image_picker/image_picker.dart';

// Import Supabase package
import 'package:supabase_flutter/supabase_flutter.dart';

// Import review screen
import 'add_review_screen.dart';

// Place details screen widget
class PlaceDetailsScreen extends StatefulWidget {

  // Store selected place information
  final Map place;

  // Constructor
  const PlaceDetailsScreen({super.key, required this.place});

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

// State class for PlaceDetailsScreen
class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {

  // Supabase client instance
  final supabase = Supabase.instance.client;

  // Store reviews and images
  List<Map<String, dynamic>> reviews = [];
  List<Map<String, dynamic>> images = [];

  // Loading states
  bool loadingImages = true;
  bool loadingReviews = true;
  bool uploading = false;

  @override
  void initState() {
    super.initState();

    // Fetch reviews and images when screen opens
    fetchReviews();
    fetchImages();
  }

  // Fetch reviews from database
  Future<void> fetchReviews() async {
    try {

      // Get reviews for current place
      final data = await supabase
          .from('reviews')
          .select()
          .eq('place_id', widget.place['id']);

      if (!mounted) return;

      // Save reviews into state
      setState(() => reviews = List<Map<String, dynamic>>.from(data));

    } catch (e) {

      // Print review error
      debugPrint('REVIEWS ERROR: $e');

    } finally {

      // Stop loading state
      if (mounted) setState(() => loadingReviews = false);
    }
  }

  // Fetch images from database
  Future<void> fetchImages() async {
    try {

      // Get images for current place
      final data = await supabase
          .from('place_images')
          .select()
          .eq('place_id', widget.place['id']);

      if (!mounted) return;

      // Save images into state
      setState(() => images = List<Map<String, dynamic>>.from(data));

    } catch (e) {

      // Print image error
      debugPrint('IMAGES ERROR: $e');

    } finally {

      // Stop loading state
      if (mounted) setState(() => loadingImages = false);
    }
  }

  // Upload a new place photo
  Future<void> addPhoto() async {

    // Open image picker
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );

    // Stop if no image selected
    if (picked == null) return;

    // Start uploading
    setState(() => uploading = true);

    try {

      // Read image bytes
      final bytes = await picked.readAsBytes();

      // Get file extension
      final extension = picked.name.split('.').last.toLowerCase();

      // Validate image extension
      final safeExtension =
          ['jpg', 'jpeg', 'png', 'webp'].contains(extension)
              ? extension
              : 'jpg';

      // Create unique file name
      final fileName =
          '${widget.place['id']}/${DateTime.now().millisecondsSinceEpoch}.$safeExtension';

      // Upload image to Supabase storage
      await supabase.storage
          .from('place-images')
          .uploadBinary(fileName, bytes);

      // Generate public image URL
      final imageUrl = supabase.storage
          .from('place-images')
          .getPublicUrl(fileName);

      // Save image URL in database
      await supabase.from('place_images').insert({
        'place_id': widget.place['id'],
        'image_url': imageUrl,
      });

      // Refresh image list
      await fetchImages();

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo uploaded successfully ✅'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {

      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo upload failed: $e'),
          backgroundColor: Colors.red,
        ),
      );

    } finally {

      // Stop uploading state
      if (mounted) setState(() => uploading = false);
    }
  }

  // Calculate average rating
  double avgRating() {

    // Return zero if no reviews exist
    if (reviews.isEmpty) return 0;

    // Calculate ratings sum
    final sum = reviews.fold<double>(
      0,
      (total, r) =>
          total + (double.tryParse('${r['rating']}') ?? 0),
    );

    // Return average rating
    return sum / reviews.length;
  }

  // Check if place has accessibility features
  bool get isAccessible {
    final place = widget.place;

    return place['has_ramp'] == true ||
        place['has_toilet'] == true ||
        place['has_wide_door'] == true ||
        place['has_elevator'] == true;
  }

  @override
  Widget build(BuildContext context) {

    // Store current place
    final place = widget.place;

    return Scaffold(

      // App bar title
      appBar: AppBar(
        title: Text(place['name'] ?? 'Details'),
      ),

      // Pull to refresh
      body: RefreshIndicator(
        onRefresh: () async {

          // Refresh reviews and images
          await Future.wait([
            fetchReviews(),
            fetchImages(),
          ]);
        },

        child: ListView(
          padding: const EdgeInsets.all(16),

          children: [

            // Place image section
            ClipRRect(
              borderRadius: BorderRadius.circular(28),

              child: Stack(
                children: [

                  // Main place image
                  Image.network(
                    images.isNotEmpty
                        ? images.first['image_url']
                        : 'https://images.unsplash.com/photo-1582719508461-905c673771fd?auto=format&fit=crop&w=1200&q=80',
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,

                    // Show fallback if image fails
                    errorBuilder: (_, __, ___) => Container(
                      height: 220,
                      color: const Color(0xFF12372A),
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),

                  // Dark overlay with place title
                  Container(
                    height: 220,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.28),
                    ),

                    child: Align(
                      alignment: Alignment.bottomLeft,

                      child: Text(
                        place['name'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Place information card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    // Accessibility status and rating
                    Row(
                      children: [

                        Icon(
                          isAccessible
                              ? Icons.check_circle
                              : Icons.info,
                          color: isAccessible
                              ? Colors.green
                              : Colors.orange,
                        ),

                        const SizedBox(width: 8),

                        Text(
                          isAccessible
                              ? 'Accessible place'
                              : 'Limited accessibility information',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),

                        const Spacer(),

                        // Average rating
                        Text(
                          '⭐ ${avgRating().toStringAsFixed(1)}',
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Place description
                    Text(
                      place['description'] ?? 'No description',
                    ),

                    const SizedBox(height: 14),

                    // Accessibility feature chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,

                      children: [
                        _chip(
                          'Ramp',
                          place['has_ramp'] == true,
                          Icons.accessible,
                        ),

                        _chip(
                          'Toilet',
                          place['has_toilet'] == true,
                          Icons.wc,
                        ),

                        _chip(
                          'Wide Door',
                          place['has_wide_door'] == true,
                          Icons.door_front_door,
                        ),

                        _chip(
                          'Elevator',
                          place['has_elevator'] == true,
                          Icons.elevator,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Photos section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    // Photos header
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,

                      children: [

                        const Text(
                          'Photos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        // Add photo button
                        IconButton.filledTonal(
                          onPressed: uploading ? null : addPhoto,

                          icon: uploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add_a_photo),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Loading indicator
                    if (loadingImages)
                      const Center(
                        child: CircularProgressIndicator(),
                      )

                    // Empty state
                    else if (images.isEmpty)
                      const Text(
                        'No uploaded photos yet. Add a real photo from this place.',
                      )

                    // Show images
                    else
                      SizedBox(
                        height: 150,

                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,

                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),

                          itemBuilder: (context, index) {

                            // Current image
                            final image = images[index];

                            return ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(18),

                              child: Image.network(
                                image['image_url'],
                                width: 170,
                                fit: BoxFit.cover,

                                // Show fallback image
                                errorBuilder: (_, __, ___) =>
                                    Container(
                                  width: 170,
                                  color: Colors.grey.shade200,
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Reviews section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    // Reviews title
                    Row(
                      children: [

                        const Text(
                          'Reviews',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const Spacer(),

                        // Add review button
                        TextButton.icon(
                          onPressed: () async {

                            // Open review screen
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddReviewScreen(
                                  placeId:
                                      place['id'].toString(),
                                ),
                              ),
                            );

                            // Refresh reviews
                            fetchReviews();
                          },

                          icon: const Icon(
                            Icons.rate_review_outlined,
                          ),

                          label: const Text('Add'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Loading reviews
                    if (loadingReviews)
                      const Center(
                        child: CircularProgressIndicator(),
                      )

                    // Empty reviews state
                    else if (reviews.isEmpty)
                      const Text('No reviews yet')

                    // Show reviews list
                    else
                      ...reviews.map(

                        (r) => ListTile(
                          contentPadding: EdgeInsets.zero,

                          leading: const CircleAvatar(
                            child: Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                          ),

                          title: Text(
                            '${r['rating']} / 5',
                          ),

                          subtitle: Text(
                            r['comment'] ?? '',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Floating review button
      floatingActionButton:
          FloatingActionButton.extended(

        icon: const Icon(Icons.star),
        label: const Text('Review'),

        onPressed: () async {

          // Open review screen
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddReviewScreen(
                placeId: place['id'].toString(),
              ),
            ),
          );

          // Refresh reviews
          fetchReviews();
        },
      ),
    );
  }

  // Accessibility feature chip widget
  Widget _chip(
    String label,
    bool enabled,
    IconData icon,
  ) {

    return Chip(

      // Chip icon
      avatar: Icon(
        icon,
        size: 18,
        color: enabled
            ? Colors.green.shade800
            : Colors.grey,
      ),

      // Chip label
      label: Text(label),

      // Background color
      backgroundColor: enabled
          ? Colors.green.shade50
          : Colors.grey.shade100,

      // Border style
      side: BorderSide(
        color: enabled
            ? Colors.green.shade200
            : Colors.grey.shade300,
      ),
    );
  }
}