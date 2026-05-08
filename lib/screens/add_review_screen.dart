// Import Flutter material package
import 'package:flutter/material.dart';

// Import Supabase package
import 'package:supabase_flutter/supabase_flutter.dart';

// Add Review screen widget
class AddReviewScreen extends StatefulWidget {

  // Store place ID
  final String placeId;

  const AddReviewScreen({
    super.key,
    required this.placeId,
  });

  @override
  State<AddReviewScreen> createState() =>
      _AddReviewScreenState();
}

// State class for AddReviewScreen
class _AddReviewScreenState
    extends State<AddReviewScreen> {

  // Controller for comment input
  final commentController =
      TextEditingController();

  // Selected rating value
  int? rating;

  // Loading state
  bool loading = false;

  // Supabase client instance
  final supabase = Supabase.instance.client;

  // Check if form is valid
  bool get isFormValid =>

      rating != null &&
      commentController.text.trim().isNotEmpty;

  // Submit review to database
  Future<void> submit() async {

    // Get trimmed comment text
    final comment =
        commentController.text.trim();

    // Validate form inputs
    if (rating == null || comment.isEmpty) {

      // Show validation error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select rating and write a comment',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    // Enable loading state
    setState(() => loading = true);

    try {

      // Insert review into Supabase table
      await supabase.from('reviews').insert({

        'place_id': widget.placeId,
        'rating': rating,
        'comment': comment,
      });

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Review added successfully ✅',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Close screen and return success
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
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {

    // Dispose text controller
    commentController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      // Screen app bar
      appBar: AppBar(
        title: const Text('Add Review'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [

          // Main review card
          Card(

            child: Padding(
              padding: const EdgeInsets.all(18),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  // Screen title
                  const Text(
                    'How accessible was this place?',

                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Description text
                  Text(
                    'Your review helps disabled visitors choose better places.',

                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Rating title
                  const Text(
                    'Rating',

                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Rating chips
                  Wrap(
                    spacing: 8,

                    children:
                        List.generate(5, (index) {

                      // Rating value
                      final value = index + 1;

                      // Check selected state
                      final selected =
                          rating == value;

                      return ChoiceChip(

                        selected: selected,

                        label: Text('⭐ $value'),

                        // Update selected rating
                        onSelected: (_) =>
                            setState(() =>
                                rating = value),
                      );
                    }),
                  ),

                  const SizedBox(height: 22),

                  // Comment title
                  const Text(
                    'Comment',

                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Comment text field
                  TextField(

                    controller:
                        commentController,

                    maxLines: 5,

                    // Refresh form validation
                    onChanged: (_) =>
                        setState(() {}),

                    decoration:
                        const InputDecoration(

                      hintText:
                          'Write your experience...',

                      prefixIcon:
                          Icon(Icons.comment_outlined),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton.icon(

                      // Disable button if form invalid
                      onPressed:
                          isFormValid && !loading
                              ? submit
                              : null,

                      // Show loading spinner
                      icon: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,

                              child:
                                  CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send),

                      label:
                          const Text('Submit Review'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}