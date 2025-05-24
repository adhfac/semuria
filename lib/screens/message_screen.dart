import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const Color secondaryColor = Color(0xFFfd0054); // Merah

class MessageScreen extends StatefulWidget {
  final String userIdPenjual;

  const MessageScreen({super.key, required this.userIdPenjual});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  // Ambil ID semua produk milik penjual
  Future<List<String>> _getMyProductIds() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('products')
            .where('userId', isEqualTo: widget.userIdPenjual)
            .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  // Stream review untuk produk milik penjual
  Stream<List<QueryDocumentSnapshot>> _getReviewNotificationsStream() async* {
    final productIds = await _getMyProductIds();
    if (productIds.isEmpty) yield [];

    yield* FirebaseFirestore.instance
        .collection('reviews')
        .where('productId', whereIn: productIds.take(10).toList())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  // Ambil nama produk berdasarkan productId
  Future<String> _getProductName(String productId) async {
    final doc =
        await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();
    if (doc.exists) {
      return doc.data()?['name'] ?? 'Nama tidak ditemukan';
    }
    return 'Produk tidak ditemukan';
  }

  // Format timestamp
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}h yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}j yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  // Build star rating display
  Widget _buildStarRating(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  // Build empty state
  Widget _buildEmptyState(String message, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.onPrimary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, size: 48, color: secondaryColor.withOpacity(0.6)),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontFamily: 'playpen',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Ulasan akan muncul di sini ketika pelanggan memberikan feedback',
            style: TextStyle(
              fontFamily: 'playpen',
              fontSize: 14,
              color: colorScheme.onPrimary.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Build loading indicator
  Widget _buildLoadingIndicator() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Memuat ulasan...',
            style: TextStyle(
              fontFamily: 'playpen',
              color: colorScheme.onPrimary.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.primary,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: const Text(
          'Notifikasi Ulasan',
          style: TextStyle(
            fontFamily: 'playpen',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<String>>(
        future: _getMyProductIds(),
        builder: (context, productSnapshot) {
          if (productSnapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingIndicator();
          }

          if (!productSnapshot.hasData || productSnapshot.data!.isEmpty) {
            return _buildEmptyState(
              'Belum ada produk',
              Icons.inventory_2_outlined,
            );
          }

          return StreamBuilder<List<QueryDocumentSnapshot>>(
            stream: _getReviewNotificationsStream(),
            builder: (context, reviewSnapshot) {
              if (reviewSnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingIndicator();
              }

              final reviews = reviewSnapshot.data ?? [];

              if (reviews.isEmpty) {
                return _buildEmptyState(
                  'Belum ada ulasan masuk',
                  Icons.rate_review_outlined,
                );
              }

              return RefreshIndicator(
                color: secondaryColor,
                backgroundColor: colorScheme.primary,
                onRefresh: () async {
                  // Trigger rebuild by returning future
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review =
                        reviews[index].data() as Map<String, dynamic>;
                    final productId = review['productId'] ?? '';
                    final timestamp = review['createdAt'] as Timestamp?;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.onPrimary.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with user info and timestamp
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: secondaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: secondaryColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        review['fullName'] ?? 'Pengguna',
                                        style: TextStyle(
                                          fontFamily: 'playpen',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: colorScheme.onPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatTimestamp(timestamp),
                                        style: TextStyle(
                                          fontFamily: 'playpen',
                                          fontSize: 12,
                                          color: colorScheme.onPrimary
                                              .withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Rating stars
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildStarRating(review['rating'] ?? 0),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${review['rating'] ?? 0}',
                                        style: const TextStyle(
                                          fontFamily: 'playpen',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Review comment
                            if (review['komentar'] != null &&
                                review['komentar'].toString().isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colorScheme.onPrimary.withOpacity(
                                      0.1,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  review['komentar'],
                                  style: TextStyle(
                                    fontFamily: 'playpen',
                                    fontSize: 14,
                                    color: colorScheme.onPrimary,
                                    height: 1.4,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 12),

                            // Product info
                            FutureBuilder<String>(
                              future: _getProductName(productId),
                              builder: (context, productSnapshot) {
                                final productName =
                                    productSnapshot.data ?? 'Memuat...';

                                return Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: secondaryColor.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: secondaryColor.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.shopping_bag_outlined,
                                        size: 16,
                                        color: secondaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          productName,
                                          style: TextStyle(
                                            fontFamily: 'playpen',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: secondaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
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
