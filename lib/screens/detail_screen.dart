import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:semuria/screens/checkout_screen.dart';
import 'package:semuria/screens/review_screen.dart';
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
  bool _isOwner = false;
  double _averageRating = 0.0;
  int _reviewCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProductData();
    _loadReviewsData();
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
          final currentUser = FirebaseAuth.instance.currentUser;
          setState(() {
            _productData = data;
            _isOwner = currentUser != null && currentUser.uid == data['userId'];
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

  Future<void> _loadReviewsData() async {
    if (widget.productId != null) {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('reviews')
              .where('productId', isEqualTo: widget.productId)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        double totalRating = 0.0;

        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          totalRating += data['rating'] ?? 0.0;
        }

        setState(() {
          _reviewCount = querySnapshot.size;
          _averageRating = totalRating / _reviewCount;
        });
      }
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
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _productData == null
              ? const Center(child: Text('Produk tidak ditemukan'))
              : _buildProductDetail(colorScheme),
          if (!_isLoading && _productData != null && !_isOwner)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_productData != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => CheckoutScreen(
                                  productName:
                                      _productData!['name'] ??
                                      'Unknown Product',
                                  platform:
                                      _productData!['category'] ??
                                      'Unknown Platform',
                                  price:
                                      int.tryParse(
                                        _productData!['price'].toString(),
                                      ) ??
                                      0,
                                  sellerName:
                                      _sellerData != null
                                          ? _sellerData!['username'] ??
                                              'Unknown Seller'
                                          : 'Unknown Seller',
                                  imageBase64:
                                      _productData!['posterImageBase64'] ?? '',
                                  imageUrl: null,
                                ),
                          ),
                        );
                      }
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Checkout Sekarang',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'playpen',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    // Maksimal 5 bintang
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;
    int emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    List<Widget> stars = [];

    for (int i = 0; i < fullStars; i++) {
      stars.add(const Icon(Icons.star, color: Colors.amber, size: 20));
    }
    if (hasHalfStar) {
      stars.add(const Icon(Icons.star_half, color: Colors.amber, size: 20));
    }
    for (int i = 0; i < emptyStars; i++) {
      stars.add(const Icon(Icons.star_border, color: Colors.amber, size: 20));
    }

    return Row(children: stars);
  }

  Widget _buildProductDetail(ColorScheme colorScheme) {
    final Timestamp timestamp = _productData!['createdAt'] ?? Timestamp.now();
    final DateTime createdAt = timestamp.toDate();
    final int reviewCount = _productData!['reviewCount'] ?? 0;
    double rating = 0.0;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              children: [
                _productData!['backdropImageBase64'] != null &&
                        _productData!['backdropImageBase64'].isNotEmpty
                    ? Image.memory(
                      base64Decode(_productData!['backdropImageBase64']),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                    : Container(
                      color: colorScheme.secondary.withOpacity(0.2),
                      child: Icon(
                        Icons.image_not_supported,
                        size: 80,
                        color: colorScheme.primary.withOpacity(0.5),
                      ),
                    ),

                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.4),
                        Colors.black,
                      ],
                    ),
                  ),
                ),

                // Poster kecil dengan Hero tag
                if (_productData!['posterImageBase64'] != null &&
                    _productData!['posterImageBase64'].isNotEmpty)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Hero(
                      tag: widget.heroTag ?? 'product-image',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(_productData!['posterImageBase64']),
                          width: 100,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
              ],
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Rp ${NumberFormat('#,###', 'id_ID').format(int.tryParse(_productData!['price']?.toString() ?? '0') ?? 0)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.secondary,
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
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  ReviewScreen(productId: widget.productId!),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          _averageRating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '($_reviewCount reviews)',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),

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
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey[300], thickness: 1),
                  const SizedBox(height: 16),
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
