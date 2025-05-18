import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddReviewScreen extends StatefulWidget {
  final String productId;

  const AddReviewScreen({super.key, required this.productId});

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final TextEditingController _komentarController = TextEditingController();
  int _rating = 0; // mulai dari 0, harus pilih minimal 1

  final CollectionReference reviews = FirebaseFirestore.instance.collection('reviews');

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

    try {
      await reviews.add({
        'userId': 'anonymous', // ganti sesuai user login nanti
        'productId': widget.productId,
        'rating': _rating,
        'komentar': _komentarController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan review: $e')),
      );
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Review'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Berikan rating bintang:',
              style: TextStyle(fontSize: 18),
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
                border: OutlineInputBorder(),
                
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitReview,
              child: const Text('Kirim Review'),
            ),
          ],
        ),
      ),
    );
  }
}
