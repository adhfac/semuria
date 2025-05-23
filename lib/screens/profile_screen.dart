import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:semuria/screens/edit_profile_screen.dart';
import 'package:semuria/screens/history_screen.dart';
import 'package:semuria/screens/inbox_screen.dart';
import 'package:semuria/screens/setting_screen.dart';
import 'package:semuria/screens/add_post_screen.dart';
import 'package:semuria/services/user_service.dart';
import 'package:semuria/screens/detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';

// Color constants
const Color primaryColor = Color(0xFFFBF9FA); // Putih
const Color secondaryColor = Color(0xFFA80038); // Merah
const Color accentColor = Color(0xFF2B2024); // Hitam

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
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
      return '${diff.inSeconds} secs ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} mins ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hrs ago';
    } else if (diff.inHours < 48) {
      return '1 day ago';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
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
                  onTap:
                      () => Navigator.pop(
                        context,
                        null,
                      ), // Null untuk memilih semua kategori
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
                    onTap:
                        () => Navigator.pop(
                          context,
                          category,
                        ), // Kategori yang dipilih
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
        selectedCategory =
            result; // Set kategori yang dipilih atau null untuk Semua Kategori
      });
    } else {
      // Jika result adalah null, berarti memilih Semua Kategori
      setState(() {
        selectedCategory =
            null; // Reset ke null untuk menampilkan semua kategori
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
      final userData = await _userService.getUserData();
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading user data: $e');
    }
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditProfileScreen(
              currentUsername: _userData!['username'],
              backdropP: _userData!['backdropP'],
              profileP: _userData!['profileP'],
              latitude: _userData!['latitude'],
              longitude: _userData!['longitude'],
            ),
      ),
    );

    if (result == true) {
      _loadUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPostScreen()),
          );
        },
        backgroundColor: colorScheme.secondary,
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadUserData,
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _userData == null
                    ? const Center(child: Text('No user data found'))
                    : _buildProfileWithPosts(),
          ),

          // Tombol History
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8, // dipindahkan ke kiri agar tidak menumpuk
            child: _buildCircleButton(
              icon: Icons.history_rounded,
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder:
                        (context, animation, secondaryAnimation) =>
                            HistoryScreen(currentUserId: FirebaseAuth.instance.currentUser?.uid),
                    transitionsBuilder: (context, animation, _, child) {
                      return SlideTransition(
                        position: animation.drive(
                          Tween(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).chain(CurveTween(curve: Curves.easeInOut)),
                        ),
                        child: child,
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Tombol Setting
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: _buildCircleButton(
              icon: Icons.settings_outlined,
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder:
                        (context, animation, secondaryAnimation) =>
                            const SettingScreen(),
                    transitionsBuilder: (context, animation, _, child) {
                      return SlideTransition(
                        position: animation.drive(
                          Tween(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).chain(CurveTween(curve: Curves.easeInOut)),
                        ),
                        child: child,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.7),
            Colors.black.withOpacity(0.3),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
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
              height: 180 + MediaQuery.of(context).padding.top,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
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
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.mail),
                    color: colorScheme.onBackground,
                    tooltip: 'Kirim Pesan',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => InboxScreen(
                                userIdPenjual:
                                    FirebaseAuth.instance.currentUser!.uid,
                              ),
                        ),
                      );
                    },
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

              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [secondaryColor, secondaryColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: secondaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _navigateToEditProfile,
                  icon: const Icon(Icons.edit, size: 20),
                  label: const Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontFamily: 'playpen',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
    final currentUser = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('products')
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
              final userId = data['userId'] ?? '';
              return (selectedCategory == null ||
                      selectedCategory == category) &&
                  userId == currentUser?.uid;
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
                      "Produk Saya",
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
                    "Anda Belum Pernah Menambahkan Produk.",
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
                    "Produk Saya",
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

                            Positioned(
                              top: 12,
                              left: 12,
                              child: InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text(
                                          'Konfirmasi Penghapusan',
                                          style: TextStyle(
                                            fontFamily: 'playpen',
                                          ),
                                        ),
                                        content: const Text(
                                          'Apakah Anda yakin ingin menghapus produk ini? Tindakan ini tidak dapat dibatalkan.',
                                          style: TextStyle(
                                            fontFamily: 'playpen',
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () =>
                                                    Navigator.of(context).pop(),
                                            child: Text(
                                              'Batal',
                                              style: TextStyle(
                                                fontFamily: 'playpen',
                                                color: colorScheme.onPrimary,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              FirebaseFirestore.instance
                                                  .collection('products')
                                                  .doc(doc.id)
                                                  .delete()
                                                  .then((_) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Produk berhasil dihapus!',
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'playpen',
                                                          ),
                                                        ),
                                                        backgroundColor:
                                                            Colors.green,
                                                      ),
                                                    );
                                                    Navigator.of(context).pop();
                                                  })
                                                  .catchError((error) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Gagal menghapus produk: $error',
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'playpen',
                                                          ),
                                                        ),
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                    );
                                                    Navigator.of(
                                                      context,
                                                    ).pop(); // Tutup dialog setelah gagal
                                                  });
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  colorScheme.secondary,
                                              foregroundColor:
                                                  colorScheme.onSecondary,
                                              elevation: 2,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              'Hapus',
                                              style: TextStyle(
                                                color: colorScheme.onPrimary,
                                                fontFamily: 'playpen',
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20,
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
                                  Icons.person_outline,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    data['fullName'] ?? 'Anonim',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
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
    if (fullAddress.isEmpty) return 'No location';
    final addressParts = fullAddress.split(', ');
    if (addressParts.length < 5) return fullAddress;
    final administrativeArea = addressParts[addressParts.length - 2];
    final country = addressParts.last;
    return '$administrativeArea, $country';
  }
}
