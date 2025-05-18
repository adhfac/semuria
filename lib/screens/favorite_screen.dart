import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:semuria/screens/detail_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  Future<List<Map<String, dynamic>>> getFavoriteProducts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final favoritesSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .get();

    final productIds = favoritesSnapshot.docs.map((doc) => doc.id).toList();

    List<Map<String, dynamic>> products = [];

    for (final id in productIds) {
      final productDoc =
          await FirebaseFirestore.instance.collection('products').doc(id).get();
      if (productDoc.exists) {
        final data = productDoc.data();
        if (data != null) {
          data['id'] = id; // simpan ID produk
          products.add(data);
        }
      }
    }

    return products;
  }

  String _formatPrice(dynamic price) {
    int intPrice;
    if (price is int) {
      intPrice = price;
    } else if (price is String) {
      intPrice = int.tryParse(price) ?? 0;
    } else {
      intPrice = 0;
    }
    return NumberFormat('#,###', 'id_ID').format(intPrice);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favorit Saya',
          style: TextStyle(fontFamily: 'playpen'),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getFavoriteProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final favorites = snapshot.data ?? [];

          if (favorites.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada produk favorit',
                style: TextStyle(fontFamily: 'playpen', fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final product = favorites[index];
              return Card(
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading:
                      product['posterImageBase64'] != null &&
                              product['posterImageBase64'].isNotEmpty
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(product['posterImageBase64']),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          )
                          : Icon(
                            Icons.image,
                            size: 60,
                            color: colorScheme.primary,
                          ),
                  title: Text(
                    product['name'] ?? 'Produk Tanpa Nama',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'playpen',
                    ),
                  ),
                  subtitle: Text(
                    'Rp ${_formatPrice(product['price'])}',
                    style: const TextStyle(
                      color: Colors.deepOrange,
                      fontFamily: 'playpen',
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => DetailScreen(
                              productId: product['id'],
                              heroTag: 'favorite-${product['id']}',
                            ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
