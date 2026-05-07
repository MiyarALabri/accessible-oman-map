import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddReviewScreen extends StatefulWidget {
  final String placeId;

  const AddReviewScreen({super.key, required this.placeId});

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final commentController = TextEditingController();
  int? rating;
  bool loading = false;

  final supabase = Supabase.instance.client;

  bool get isFormValid => rating != null && commentController.text.trim().isNotEmpty;

  Future<void> submit() async {
    final comment = commentController.text.trim();

    if (rating == null || comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select rating and write a comment'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await supabase.from('reviews').insert({
        'place_id': widget.placeId,
        'rating': rating,
        'comment': comment,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review added successfully ✅'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Review')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('How accessible was this place?', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text('Your review helps disabled visitors choose better places.', style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 22),
                  const Text('Rating', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: List.generate(5, (index) {
                      final value = index + 1;
                      final selected = rating == value;
                      return ChoiceChip(
                        selected: selected,
                        label: Text('⭐ $value'),
                        onSelected: (_) => setState(() => rating = value),
                      );
                    }),
                  ),
                  const SizedBox(height: 22),
                  const Text('Comment', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: commentController,
                    maxLines: 5,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Write your experience...',
                      prefixIcon: Icon(Icons.comment_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isFormValid && !loading ? submit : null,
                      icon: loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send),
                      label: const Text('Submit Review'),
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
