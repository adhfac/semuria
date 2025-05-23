import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:semuria/screens/add_review_screen.dart';
import 'dart:convert';

class ReviewScreen extends StatefulWidget {
  final String productId;

  const ReviewScreen({super.key, required this.productId});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final reviewCollection = FirebaseFirestore.instance.collection('reviews');
  final userCollection = FirebaseFirestore.instance.collection('users');
  final productCollection = FirebaseFirestore.instance.collection('products');

  String? currentUserId;
  String? productOwnerId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadProductOwner();
  }

  Future<void> _loadProductOwner() async {
    final productDoc = await productCollection.doc(widget.productId).get();
    if (productDoc.exists) {
      final data = productDoc.data();
      setState(() {
        productOwnerId = data?['userId'];
      });
    }
  }

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    final doc = await userCollection.doc(userId).get();
    if (doc.exists) {
      return doc.data()!;
    }
    return {'displayName': 'fullName', 'photoURL': null};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    if (productOwnerId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ulasan Produk',
          style: TextStyle(fontFamily: 'playpen'),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.onBackground),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            reviewCollection
                .where('productId', isEqualTo: widget.productId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reviews = snapshot.data?.docs ?? [];

          if (reviews.isEmpty) {
            return const Center(
              child: Text('Belum ada ulasan untuk produk ini', style: TextStyle(fontFamily: 'playpen'),),
            );
          }

          return ListView.separated(
            itemCount: reviews.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final review = reviews[index].data() as Map<String, dynamic>;
              final String userId = review['userId'] ?? 'unknown';
              final int rating = review['rating'] ?? 0;
              final String komentar = review['komentar'] ?? '-';

              return FutureBuilder<Map<String, dynamic>>(
                future: _getUserData(userId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      leading: CircularProgressIndicator(),
                      title: Text('Loading...'),
                    );
                  }

                  final _userData = userSnapshot.data!;
                  final displayName = _userData['username'] ?? 'Anonymous';

                  return ListTile(
                    contentPadding: const EdgeInsets.only(
                      top: 16,
                      left: 24,
                      right: 24,
                    ),
                    leading: CircleAvatar(
                      radius: 27,
                      backgroundImage:
                          _userData['profileP'] != null &&
                                  _userData['profileP'].isNotEmpty
                              ? MemoryImage(base64Decode(_userData['profileP']))
                              : null,
                      child:
                          _userData['profileP'] == null ||
                                  _userData['profileP'].isEmpty
                              ? Icon(
                                Icons.person,
                                size: 60,
                                color: theme.secondary,
                              )
                              : null,
                    ),
                    title: Text(
                      displayName,
                      style: const TextStyle(fontFamily: 'playpen'),
                    ),
                    subtitle: Text(
                      komentar,
                      style: const TextStyle(fontFamily: 'playpen'),
                    ),
                    trailing: Text(
                      '⭐ $rating',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.amber,
                        fontFamily: 'playpen',
                      ),
                    ),
                    isThreeLine: true,
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton:
          currentUserId != productOwnerId
              ? FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              AddReviewScreen(productId: widget.productId),
                    ),
                  );
                  if (result == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Review berhasil ditambahkan',
                          style: TextStyle(fontFamily: 'playpen'),
                        ),
                      ),
                    );
                  }
                },
                child: const Icon(Icons.add),
                tooltip: 'Tambah Review',
              )
              : null,
    );
  }
}
