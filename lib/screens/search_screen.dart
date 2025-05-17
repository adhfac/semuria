import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // untuk base64 decode
import 'package:intl/intl.dart'; // untuk format angka

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String searchText = '';

  bool allWordsMatchPrefix(String text, String search) {
    final words = text.split(' ').where((w) => w.isNotEmpty).toList();
    final searchWords = search.split(' ').where((w) => w.isNotEmpty).toList();

    if (searchWords.length > words.length) return false;

    for (int i = 0; i < searchWords.length; i++) {
      if (!words[i].toLowerCase().startsWith(searchWords[i].toLowerCase())) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onPrimary;
    final iconColor = textColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search',
          style: TextStyle(
            fontFamily: 'playpen',
            fontWeight: FontWeight.bold,
            color: Color(0xFFA80038),
            shadows: <Shadow>[
              Shadow(
                offset: Offset(0, 1.0),
                blurRadius: 3.0,
                color: Color.fromARGB(255, 164, 164, 164),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              style: TextStyle(
                fontFamily: 'playpen',
                fontSize: 12,
                color: textColor,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.colorScheme.primary,
                hintText: 'Cari game...',
                hintStyle: TextStyle(color: textColor.withOpacity(0.7)),
                prefixIcon: Icon(Icons.search, color: iconColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50.0),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value.trim();
                });
              },
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                searchText.isEmpty ? 'Rekomendasi' : 'Sedang mencari',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontFamily: 'playpen',
                ),
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('products').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Tidak ada produk'));
                  }

                  final allProducts = snapshot.data!.docs;

                  final filteredProducts = searchText.isEmpty
                      ? (allProducts.toList()..shuffle()).take(4).toList()
                      : allProducts.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = (data['name'] ?? '').toString();
                          return allWordsMatchPrefix(name, searchText);
                        }).toList();

                  if (filteredProducts.isEmpty) {
                    return const Center(child: Text('Produk tidak ditemukan'));
                  }

                  return ListView.separated(
                    itemCount: filteredProducts.length,
                    separatorBuilder: (context, index) => Divider(
                      color: textColor.withOpacity(0.3),
                      thickness: 1,
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final data = product.data() as Map<String, dynamic>;

                      final posterImageBase64 = data['posterImageBase64'] ?? '';
                      final price = data['price'] ?? 0;
                      final fullName = data['fullName'] ?? 'Anonim';
                      final category = data['category'] ?? 'Lainnya';

                      final Timestamp timestamp = data['createdAt'];
                      final createdAt = timestamp.toDate();
                      final String heroTag =
                          'semuria-list-${createdAt.millisecondsSinceEpoch}';

                      ImageProvider? posterImage;
                      if (posterImageBase64.isNotEmpty) {
                        try {
                          posterImage = MemoryImage(base64Decode(posterImageBase64));
                        } catch (_) {
                          posterImage = null;
                        }
                      }

                      return ListTile(
                        leading: posterImage != null
                            ? Hero(
                                tag: heroTag,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image(
                                    image: posterImage,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.image_not_supported),
                              ),
                        title: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            data['name'] ?? 'Produk',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              fontFamily: 'playpen',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  category == 'WINDOWS' || category == 'LAPTOP/PC'
                                      ? Icons.computer
                                      : (category == 'PS4' ||
                                              category == 'PS5' ||
                                              category == 'PS3' ||
                                              category == 'PS2' ||
                                              category == 'PS1')
                                          ? Icons.videogame_asset
                                          : (category == 'MOBILE')
                                              ? Icons.smartphone
                                              : Icons.games,
                                  color: textColor,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 14,
                                  color: textColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    fullName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textColor,
                                      fontFamily: 'playpen',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Text(
                          'Rp${NumberFormat('#,###', 'id_ID').format(int.tryParse(price.toString()) ?? 0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                            fontFamily: 'playpen',
                          ),
                        ),
                        onTap: () {
                          // Navigasi ke detail page jika mau
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
