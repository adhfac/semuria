import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DetailScreen extends StatefulWidget {
  final String? productId;
  final String? heroTag;

  const DetailScreen({super.key, this.productId, this.heroTag});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _productData;
  Map<String, dynamic>? _sellerData;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadProductData();
  }

  Future<void> _loadProductData() async {
    try {
      if (widget.productId != null) {
        // Load from Firestore by ID
        final productDoc =
            await FirebaseFirestore.instance
                .collection('products')
                .doc(widget.productId)
                .get();

        if (productDoc.exists) {
          final data = productDoc.data() as Map<String, dynamic>;
          setState(() {
            _productData = data;
          });

          // Load seller data
          if (data['userId'] != null) {
            final sellerDoc =
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(data['userId'])
                    .get();

            if (sellerDoc.exists) {
              setState(() {
                _sellerData = sellerDoc.data() as Map<String, dynamic>;
              });
            }
          }

          // Check if product is in favorites
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            final favoriteDoc =
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser.uid)
                    .collection('favorites')
                    .doc(widget.productId)
                    .get();

            setState(() {
              _isFavorite = favoriteDoc.exists;
            });
          }
        }
      } else {
        // Use placeholder data for demo
        setState(() {
          _productData = {
            'name': 'PlayStation 5 Digital Edition',
            'price': '6500000',
            'category': 'PS5',
            'description':
                'PlayStation 5 Digital Edition dalam kondisi mulus. Bonus 2 kontroler dan 3 game digital: Spider-Man Miles Morales, Horizon Forbidden West, dan God of War Ragnarok.',
            'condition': 'Bekas (Mulus)',
            'location': 'Jakarta Selatan',
            'posterImageBase64': '', // Will be filled with dummy data
            'createdAt': Timestamp.now(),
            'fullName': 'Anonim',
            'whatsappNumber': '6281234567890',
          };

          _sellerData = {
            'username': 'user123',
            'profileP': '',
            'address': 'Jakarta Selatan, DKI Jakarta, Indonesia',
          };
        });
      }
    } catch (e) {
      print('Error loading product data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.productId == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan login terlebih dahulu',
            style: TextStyle(fontFamily: 'playpen'),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('favorites')
        .doc(widget.productId);

    try {
      if (_isFavorite) {
        // Remove from favorites
        await favRef.delete();
      } else {
        // Add to favorites
        await favRef.set({
          'productId': widget.productId,
          'addedAt': Timestamp.now(),
        });
      }

      setState(() {
        _isFavorite = !_isFavorite;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite ? 'Ditambahkan ke favorit' : 'Dihapus dari favorit',
            style: TextStyle(fontFamily: 'playpen'),
          ),
          backgroundColor: _isFavorite ? Colors.green : Colors.grey,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: $e', style: TextStyle(fontFamily: 'playpen')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareProduct() async {
    if (_productData == null) return;

    final String productName = _productData!['name'] ?? 'Produk';
    final String price = NumberFormat(
      '#,###',
      'id_ID',
    ).format(int.tryParse(_productData!['price']?.toString() ?? '0') ?? 0);

    final String shareText =
        'Lihat $productName dengan harga Rp $price di aplikasi Semuria!';

    try {
      await Share.share(shareText);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal membagikan: $e',
            style: TextStyle(fontFamily: 'playpen'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _contactSeller() async {
    if (_productData == null) return;

    final String? whatsappNumber = _productData!['whatsappNumber'];
    if (whatsappNumber == null || whatsappNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nomor WhatsApp tidak tersedia',
            style: TextStyle(fontFamily: 'playpen'),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final String productName = _productData!['name'] ?? 'Produk';
    final String message =
        'Halo, saya tertarik dengan $productName yang Anda jual di Semuria. Apakah masih tersedia?';
    final String encodedMessage = Uri.encodeComponent(message);
    final String whatsappUrl =
        'https://wa.me/$whatsappNumber?text=$encodedMessage';

    try {
      if (await canLaunch(whatsappUrl)) {
        await launch(whatsappUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tidak dapat membuka WhatsApp',
              style: TextStyle(fontFamily: 'playpen'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: TextStyle(fontFamily: 'playpen')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds} detik yang lalu';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit yang lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam yang lalu';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari yang lalu';
    } else {
      return DateFormat('dd MMMM yyyy', 'id_ID').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _productData == null
              ? const Center(child: Text('Produk tidak ditemukan'))
              : _buildProductDetail(colorScheme),
    );
  }

  Widget _buildProductDetail(ColorScheme colorScheme) {
    final Timestamp timestamp = _productData!['createdAt'] ?? Timestamp.now();
    final DateTime createdAt = timestamp.toDate();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background:
                _productData!['posterImageBase64'] != null &&
                        _productData!['posterImageBase64'].isNotEmpty
                    ? Hero(
                      tag: widget.heroTag ?? 'product-image',
                      child: Image.memory(
                        base64Decode(_productData!['posterImageBase64']),
                        fit: BoxFit.cover,
                      ),
                    )
                    : Container(
                      color: colorScheme.secondary.withOpacity(0.2),
                      child: Icon(
                        Icons.image_not_supported,
                        size: 80,
                        color: colorScheme.primary.withOpacity(0.5),
                      ),
                    ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.white,
              ),
              onPressed: _toggleFavorite,
            ),
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: _shareProduct,
            ),
          ],
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price and category
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Rp ${NumberFormat('#,###', 'id_ID').format(int.tryParse(_productData!['price']?.toString() ?? '0') ?? 0)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                            fontFamily: 'playpen',
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _productData!['category'] ?? 'Lainnya',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'playpen',
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Title
                  const SizedBox(height: 12),
                  Text(
                    _productData!['name'] ?? 'Produk Tanpa Nama',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.tertiary,
                      fontFamily: 'playpen',
                    ),
                  ),

                  // Posted time and condition
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatTime(createdAt),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'playpen',
                        ),
                      ),
                    ],
                  ),

                  // Divider
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey[300], thickness: 1),
                  const SizedBox(height: 16),

                  // Description section
                  const Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'playpen',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _productData!['description'] ??
                        'Tidak ada deskripsi untuk produk ini.',
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'playpen',
                      height: 1.5,
                    ),
                  ),

                  // Seller section
                  const SizedBox(height: 24),
                  Divider(color: Colors.grey[300], thickness: 1),
                  const SizedBox(height: 16),
                  const Text(
                    'Tentang Penjual',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'playpen',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Seller info card
                  _buildSellerCard(colorScheme),
                ],
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildSellerCard(ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: colorScheme.secondary.withOpacity(0.2),
              backgroundImage:
                  _sellerData != null &&
                          _sellerData!['profileP'] != null &&
                          _sellerData!['profileP'].isNotEmpty
                      ? MemoryImage(base64Decode(_sellerData!['profileP']))
                      : null,
              child:
                  _sellerData == null ||
                          _sellerData!['profileP'] == null ||
                          _sellerData!['profileP'].isEmpty
                      ? Icon(
                        Icons.person,
                        size: 30,
                        color: colorScheme.secondary,
                      )
                      : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _sellerData != null && _sellerData!['username'] != null
                        ? _sellerData!['username']
                        : _productData!['fullName'] ?? 'Anonim',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.tertiary,
                      fontFamily: 'playpen',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _sellerData != null && _sellerData!['address'] != null
                        ? _formatAddress(_sellerData!['address'])
                        : _productData!['location'] ??
                            'Lokasi tidak disebutkan',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'playpen',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAddress(String fullAddress) {
    if (fullAddress.isEmpty) return 'No location';
    final addressParts = fullAddress.split(', ');
    if (addressParts.length < 5) return fullAddress;
    final administrativeArea = addressParts[addressParts.length - 2];
    final country = addressParts.last;
    return '$administrativeArea, $country';
  }
}
