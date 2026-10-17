import 'package:flutter/material.dart';

class ReviewDialog extends StatefulWidget {
  final String title;
  final Future<void> Function(int rating, String comment) onSubmit;

  const ReviewDialog({
    super.key,
    required this.title,
    required this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required Future<void> Function(int rating, String comment) onSubmit,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ReviewDialog(title: title, onSubmit: onSubmit),
    );
  }

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  int _selectedRating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Lütfen 1 ile 5 arasında bir puan verin:',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return IconButton(
                  icon: Icon(
                    starIndex <= _selectedRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedRating = starIndex;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              maxLines: 3,
              maxLength: 250,
              decoration: InputDecoration(
                hintText: 'İsteğe bağlı yorum yazın...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        _isSubmitting
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A49A6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final nav = Navigator.of(context);
                  setState(() => _isSubmitting = true);
                  await widget.onSubmit(_selectedRating, _commentController.text.trim());
                  if (mounted) {
                    nav.pop();
                  }
                },
                child: const Text('Kaydet'),
              ),
      ],
    );
  }
}
