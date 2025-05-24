import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:semuria/screens/detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';

// Color constants
const Color primaryColor = Color(0xFFFBF9FA); // Putih
const Color secondaryColor = Color(0xFFA80038); // Merah
const Color accentColor = Color(0xFF2B2024); // Hitam

class SellerProfileScreen extends StatefulWidget {
  final String sellerId;
  final Map<String, dynamic>? sellerData;

  const SellerProfileScreen({
    super.key,
    required this.sellerId,
    this.sellerData,
  });

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  String? selectedCategory;

  List<String> categories = [
    'LAPTOP/PC',
    'PS5',
    'PS4',
    'PS3',
    'PS2',
    'PS1',
    'XBOX',
    'SWITCH',
    'MOBILE',
    'LAINNYA',
  ];

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

  Future<void> openMap() async {
    if (_userData == null) return;

    final latitude = _userData!['latitude'];
    final longitude = _userData!['longitude'];

    if (latitude == null || longitude == null) {
      _showSnackBar('Koordinat lokasi tidak tersedia', Colors.orange);
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!success) {
      _showSnackBar('Tidak dapat membuka Google Maps', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.red ? Icons.error_outline : Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'playpen',
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCategoryFilter() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                ListTile(
                  leading: const Icon(Icons.clear),
                  title: Text(
                    'Semua Kategori',
                    style: TextStyle(fontFamily: 'playpen'),
                  ),
                  onTap: () => Navigator.pop(context, null),
                ),
                const Divider(),
                ...categories.map(
                  (category) => ListTile(
                    title: Text(category),
                    trailing:
                        selectedCategory == category
                            ? Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.primary,
                            )
                            : null,
                    onTap: () => Navigator.pop(context, category),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (result != null) {
      setState(() {
        selectedCategory = result;
      });
    } else {
      setState(() {
        selectedCategory = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Use provided seller data if available, otherwise fetch from Firestore
      if (widget.sellerData != null) {
        setState(() {
          _userData = widget.sellerData;
          _isLoading = false;
        });
      } else {
        // Fetch seller data from Firestore
        final sellerDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.sellerId)
                .get();

        if (sellerDoc.exists) {
          setState(() {
            _userData = sellerDoc.data() as Map<String, dynamic>;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          _showSnackBar('Data penjual tidak ditemukan', Colors.red);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error loading seller data: $e', Colors.red);
      print('Error loading seller data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profil Penjual',
          style: TextStyle(fontFamily: 'playpen', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadUserData,
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _userData == null
                    ? const Center(
                      child: Text(
                        'Data penjual tidak ditemukan',
                        style: TextStyle(fontFamily: 'playpen'),
                      ),
                    )
                    : _buildProfileWithPosts(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileWithPosts() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [_buildProfileHeader(), _buildPostsList()],
    );
  }

  Widget _buildProfileHeader() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: colorScheme.secondary.withOpacity(0.2),
                image:
                    _userData!['backdropP'] != null &&
                            _userData!['backdropP'].isNotEmpty
                        ? DecorationImage(
                          image: MemoryImage(
                            base64Decode(_userData!['backdropP']),
                          ),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
            ),
            Positioned(
              bottom: -60,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.primary, width: 4),
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: colorScheme.surface,
                  backgroundImage:
                      _userData!['profileP'] != null &&
                              _userData!['profileP'].isNotEmpty
                          ? MemoryImage(base64Decode(_userData!['profileP']))
                          : null,
                  child:
                      _userData!['profileP'] == null ||
                              _userData!['profileP'].isEmpty
                          ? Icon(
                            Icons.person,
                            size: 60,
                            color: colorScheme.secondary,
                          )
                          : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 55),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '@${_userData!['username'] ?? 'No Username'}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'playpen',
                      color: colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: openMap,
                borderRadius: BorderRadius.circular(20),
                highlightColor: colorScheme.secondary,
                splashColor: colorScheme.secondary,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: secondaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.location_on,
                          size: 20,
                          color: secondaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatAddress(_userData!['address'] ?? ''),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onBackground,
                                fontFamily: 'playpen',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostsList() {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('products')
              .where(
                'userId',
                isEqualTo: widget.sellerId,
              ) // Filter by seller ID
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final products =
            snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final category = data['category'] ?? 'Lainnya';
              return selectedCategory == null || selectedCategory == category;
            }).toList();

        if (products.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Text(
                      "Produk Toko Ini",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'playpen',
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: _showCategoryFilter,
                      tooltip: "Filter Kategori",
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    "Penjual ini belum menambahkan produk.",
                    style: TextStyle(fontFamily: 'playpen'),
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    "Produk Toko Ini",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'playpen',
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: _showCategoryFilter,
                    tooltip: "Filter Kategori",
                  ),
                ],
              ),
            ),
            ...products.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final Timestamp timestamp = data['createdAt'];
              final createdAt = timestamp.toDate();

              final heroTag =
                  'semuria-posterImageBase64-${createdAt.millisecondsSinceEpoch}';

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              DetailScreen(productId: doc.id, heroTag: heroTag),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.all(10),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['posterImageBase64'] != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: Hero(
                                tag: heroTag,
                                child: Image.memory(
                                  base64Decode(data['posterImageBase64']),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 180,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  data['category'] ?? 'Lainnya',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'playpen',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                'Rp ${NumberFormat('#,###', 'id_ID').format(int.tryParse(data['price']?.toString() ?? '0') ?? 0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'playpen',
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ),
                            Text(
                              data['name'] ?? 'Produk Tanpa Nama',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'playpen',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  formatTime(createdAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontFamily: 'playpen',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.inventory,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Stok: ${data['stock'] ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontFamily: 'playpen',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  String _formatAddress(String fullAddress) {
    if (fullAddress.isEmpty) return 'Lokasi tidak disebutkan';

    final addressParts = fullAddress.split(', ');

    // For addresses like "2QG7+GJ7, 9 Ilir, Ilir Timur II, South Sumatra, Indonesia"
    if (addressParts.length >= 2) {
      // Return the last two parts (province/state and country)
      final province = addressParts[addressParts.length - 2];
      final country = addressParts.last;
      return '$province, $country';
    }

    return fullAddress;
  }
}
