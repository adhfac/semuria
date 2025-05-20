import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class AddReviewScreen extends StatefulWidget {
  final String productId;

  const AddReviewScreen({super.key, required this.productId});

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final TextEditingController _komentarController = TextEditingController();
  int _rating = 0; // mulai dari 0, harus pilih minimal 1
  bool _isSubmitting = false;

  final CollectionReference reviews = FirebaseFirestore.instance.collection(
    'reviews',
  );

  @override
  void dispose() {
    _komentarController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih rating bintang')),
      );
      return;
    }
    if (_komentarController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Komentar tidak boleh kosong')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Ambil userId dari FirebaseAuth
      final uid = user.uid;
      await Future.delayed(const Duration(milliseconds: 500));

      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final username = userDoc.data()?['username'] ?? 'Anonim';

      try {
        await reviews.add({
          'userId': uid,
          'fullName': username,
          'productId': widget.productId,
          'rating': _rating,
          'komentar': _komentarController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        HapticFeedback.mediumImpact();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Review berhasil ditambahkan!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(12),
          ),
        );

        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context);
      } catch (e) {
        print('Gagal menambahkan review: $e');
        _showErrorSnackBar('Gagal menambahkan review. Mohon coba lagi.');
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    } else {
      _showErrorSnackBar('Anda harus login untuk memberikan review.');
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  Widget buildStar(int index) {
    if (index < _rating) {
      return IconButton(
        icon: const Icon(Icons.star, color: Colors.amber, size: 40),
        onPressed: () {
          setState(() {
            _rating = index + 1;
          });
        },
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.star_border, color: Colors.grey, size: 40),
        onPressed: () {
          setState(() {
            _rating = index + 1;
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tambah Review',
          style: TextStyle(fontFamily: 'playpen', color: theme.onPrimary),
        ),
        backgroundColor: theme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Berikan rating bintang:',
              style: TextStyle(fontSize: 18, fontFamily: 'playpen'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => buildStar(index)),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _komentarController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Tulis ulasan Anda',
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitReview,
              child: Text(
                'Kirim Review',
                style: TextStyle(fontFamily: 'playpen', color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
