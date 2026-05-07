import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_review_screen.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final Map place;

  const PlaceDetailsScreen({super.key, required this.place});

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> reviews = [];
  List<Map<String, dynamic>> images = [];
  bool loadingImages = true;
  bool loadingReviews = true;
  bool uploading = false;

  @override
  void initState() {
    super.initState();
    fetchReviews();
    fetchImages();
  }

  Future<void> fetchReviews() async {
    try {
      final data = await supabase
          .from('reviews')
          .select()
          .eq('place_id', widget.place['id']);
      if (!mounted) return;
      setState(() => reviews = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('REVIEWS ERROR: $e');
    } finally {
      if (mounted) setState(() => loadingReviews = false);
    }
  }

  Future<void> fetchImages() async {
    try {
      final data = await supabase
          .from('place_images')
          .select()
          .eq('place_id', widget.place['id']);
      if (!mounted) return;
      setState(() => images = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('IMAGES ERROR: $e');
    } finally {
      if (mounted) setState(() => loadingImages = false);
    }
  }

  Future<void> addPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked == null) return;

    setState(() => uploading = true);

    try {
      final bytes = await picked.readAsBytes();
      final extension = picked.name.split('.').last.toLowerCase();
      final safeExtension = ['jpg', 'jpeg', 'png', 'webp'].contains(extension) ? extension : 'jpg';
      final fileName = '${widget.place['id']}/${DateTime.now().millisecondsSinceEpoch}.$safeExtension';

      await supabase.storage.from('place-images').uploadBinary(fileName, bytes);
      final imageUrl = supabase.storage.from('place-images').getPublicUrl(fileName);

      await supabase.from('place_images').insert({
        'place_id': widget.place['id'],
        'image_url': imageUrl,
      });

      await fetchImages();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo uploaded successfully ✅'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo upload failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  double avgRating() {
    if (reviews.isEmpty) return 0;
    final sum = reviews.fold<double>(0, (total, r) => total + (double.tryParse('${r['rating']}') ?? 0));
    return sum / reviews.length;
  }

  bool get isAccessible {
    final place = widget.place;
    return place['has_ramp'] == true ||
        place['has_toilet'] == true ||
        place['has_wide_door'] == true ||
        place['has_elevator'] == true;
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;

    return Scaffold(
      appBar: AppBar(title: Text(place['name'] ?? 'Details')),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([fetchReviews(), fetchImages()]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  Image.network(
                    images.isNotEmpty
                        ? images.first['image_url']
                        : 'https://images.unsplash.com/photo-1582719508461-905c673771fd?auto=format&fit=crop&w=1200&q=80',
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 220,
                      color: const Color(0xFF12372A),
                      child: const Icon(Icons.image_not_supported_outlined, color: Colors.white, size: 50),
                    ),
                  ),
                  Container(
                    height: 220,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.28)),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        place['name'] ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(isAccessible ? Icons.check_circle : Icons.info, color: isAccessible ? Colors.green : Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          isAccessible ? 'Accessible place' : 'Limited accessibility information',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const Spacer(),
                        Text('⭐ ${avgRating().toStringAsFixed(1)}'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(place['description'] ?? 'No description'),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip('Ramp', place['has_ramp'] == true, Icons.accessible),
                        _chip('Toilet', place['has_toilet'] == true, Icons.wc),
                        _chip('Wide Door', place['has_wide_door'] == true, Icons.door_front_door),
                        _chip('Elevator', place['has_elevator'] == true, Icons.elevator),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Photos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        IconButton.filledTonal(
                          onPressed: uploading ? null : addPhoto,
                          icon: uploading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.add_a_photo),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (loadingImages)
                      const Center(child: CircularProgressIndicator())
                    else if (images.isEmpty)
                      const Text('No uploaded photos yet. Add a real photo from this place.')
                    else
                      SizedBox(
                        height: 150,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final image = images[index];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(
                                image['image_url'],
                                width: 170,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 170,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.broken_image_outlined),
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => AddReviewScreen(placeId: place['id'].toString())),
                            );
                            fetchReviews();
                          },
                          icon: const Icon(Icons.rate_review_outlined),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (loadingReviews)
                      const Center(child: CircularProgressIndicator())
                    else if (reviews.isEmpty)
                      const Text('No reviews yet')
                    else
                      ...reviews.map(
                        (r) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(child: Icon(Icons.star, color: Colors.amber)),
                          title: Text('${r['rating']} / 5'),
                          subtitle: Text(r['comment'] ?? ''),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.star),
        label: const Text('Review'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddReviewScreen(placeId: place['id'].toString())),
          );
          fetchReviews();
        },
      ),
    );
  }

  Widget _chip(String label, bool enabled, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 18, color: enabled ? Colors.green.shade800 : Colors.grey),
      label: Text(label),
      backgroundColor: enabled ? Colors.green.shade50 : Colors.grey.shade100,
      side: BorderSide(color: enabled ? Colors.green.shade200 : Colors.grey.shade300),
    );
  }
}
