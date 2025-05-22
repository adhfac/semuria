import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:semuria/screens/auth_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:semuria/screens/favorite_screen.dart';
import 'package:semuria/screens/profile_screen.dart';
import 'package:semuria/screens/search_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:semuria/screens/detail_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController(initialPage: 0);

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const ProfileScreen(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final shouldExit = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                title: Text(
                  'Keluar Aplikasi?',
                  style: TextStyle(
                    fontFamily: 'playpen',
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                content: Text(
                  'Kamu akan meninggalkan aplikasi ini, kamu serius? 😭🙏',
                  style: TextStyle(
                    fontFamily: 'playpen',
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        fontFamily: 'playpen',
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => SystemNavigator.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Keluar',
                      style: TextStyle(
                        fontFamily: 'playpen',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
        );

        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: _screens,
          physics: const ClampingScrollPhysics(),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(70),
              topRight: Radius.circular(70),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 5,
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(70),
              topRight: Radius.circular(70),
            ),
            child: BottomNavigationBar(
              backgroundColor: theme.colorScheme.secondary,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: theme.colorScheme.onSecondary,
              unselectedItemColor: theme.colorScheme.onSecondary.withOpacity(
                0.6,
              ),
              showSelectedLabels: true,
              showUnselectedLabels: false,
              selectedLabelStyle: const TextStyle(
                fontFamily: 'playpen',
                fontWeight: FontWeight.bold,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search_rounded),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
              type: BottomNavigationBarType.fixed,
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
                  title: const Text('Semua Kategori'),
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

  Future<void> signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const StartScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  getTopRatedProductDocs() async {
    final firestore = FirebaseFirestore.instance;

    final productSnapshot = await firestore.collection('products').get();
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> productDocs =
        productSnapshot.docs;

    Map<String, double> ratingMap = {};

    for (final product in productDocs) {
      final productId = product.id;

      final reviewSnapshot =
          await firestore
              .collection('reviews')
              .where('productId', isEqualTo: productId)
              .get();

      final reviews = reviewSnapshot.docs;

      double avgRating = 0;
      if (reviews.isNotEmpty) {
        final totalRating = reviews
            .map((r) => (r.data()['rating'] ?? 0) as num)
            .reduce((a, b) => a + b);
        avgRating = totalRating / reviews.length;
      }

      ratingMap[productId] = avgRating;
    }

    productDocs.sort((a, b) {
      final ratingA = ratingMap[a.id] ?? 0;
      final ratingB = ratingMap[b.id] ?? 0;
      return ratingB.compareTo(ratingA);
    });

    return productDocs;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        title: Text(
          'Semuria',
          style: TextStyle(
            fontFamily: 'playpen',
            fontWeight: FontWeight.bold,
            color: Color(0xFFfd0054),
            shadows: const <Shadow>[
              Shadow(
                offset: Offset(0, 1.0),
                blurRadius: 3.0,
                color: Color.fromARGB(255, 164, 164, 164),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showCategoryFilter,
            icon: Icon(Icons.filter_list, color: theme.colorScheme.onPrimary),
            tooltip: 'Filter Kategori',
          ),
        ],
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.pink,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite_outline,
              color: Color(0xFFfbf9fa),
              shadows: [
                Shadow(
                  color: Colors.black45,
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FavoriteScreen()),
            );
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Featured Products FutureBuilder
              FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                future: getTopRatedProductDocs(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        "Tidak ada produk unggulan.",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    );
                  }

                  final featuredProducts = snapshot.data!.take(3).toList();
                  return _buildFeaturedCarousel(context, featuredProducts);
                },
              ),

              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 4.0,
                ),
                child: Divider(color: Theme.of(context).colorScheme.primary),
              ),

              // All Products (filtered by category)
              StreamBuilder(
                stream:
                    FirebaseFirestore.instance
                        .collection('products')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    );
                  }

                  final products =
                      snapshot.data!.docs.where((doc) {
                        final data = doc.data();
                        final category = data['category'] ?? 'Lainnya';
                        return (selectedCategory == null ||
                            selectedCategory == category);
                      }).toList();

                  if (products.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          "Belum Ada Produk di Kategori ini.",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Produk Lainnya",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontFamily: 'playpen',
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...products.map(
                          (product) => _buildProductListItem(context, product),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildFeaturedCarousel(
  BuildContext context,
  List<DocumentSnapshot> products,
) {
  if (products.isEmpty) return const SizedBox();
  final theme = Theme.of(context);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          "Produk Unggulan",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
      Container(
        height: 300,
        margin: const EdgeInsets.only(left: 0),
        child: PageView.builder(
          itemCount: products.length,
          controller: PageController(viewportFraction: 0.9),
          itemBuilder: (context, index) {
            final data = products[index].data() as Map<String, dynamic>;
            final Timestamp timestamp = data['createdAt'];
            final createdAt = timestamp.toDate();
            final String heroTag =
                'semuria-featured-${createdAt.millisecondsSinceEpoch}';

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => DetailScreen(
                          productId: products[index].id,
                          heroTag: heroTag,
                        ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7.0,
                  vertical: 9.0,
                ),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black87.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            data['backdrpImageBase64'] != null
                                ? Hero(
                                  tag: heroTag,
                                  child: Image.memory(
                                    base64Decode(data['backdrpImageBase64']),
                                    height: 300,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : data['posterImageBase64'] != null
                                ? Hero(
                                  tag: heroTag,
                                  child: Image.memory(
                                    base64Decode(data['posterImageBase64']),
                                    height: 300,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : Container(
                                  height: 300,
                                  width: double.infinity,
                                  color: theme.colorScheme.primary,
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: theme.colorScheme.onPrimary,
                                    size: 50,
                                  ),
                                ),
                            Container(
                              height: 300,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.center,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.4),
                                    Colors.black.withOpacity(0.55),
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 16,
                              left: 20,
                              right: 20,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          data['name'] ?? 'Produk',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontFamily: 'playpen',
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.person_outline,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            data['fullName'] ?? 'Anonim',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontFamily: 'playpen',
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  theme.colorScheme.secondary,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Rp${NumberFormat('#,###', 'id_ID').format(int.tryParse(data['price']?.toString() ?? '0') ?? 0)}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontFamily: 'playpen',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.onPrimary,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              data['category'] == 'WINDOWS' ||
                                                      data['category'] ==
                                                          'LAPTOP/PC'
                                                  ? Icons.computer
                                                  : (data['category'] ==
                                                          'PS4' ||
                                                      data['category'] ==
                                                          'PS5' ||
                                                      data['category'] ==
                                                          'PS3' ||
                                                      data['category'] ==
                                                          'PS2' ||
                                                      data['category'] == 'PS1')
                                                  ? Icons.videogame_asset
                                                  : (data['category'] ==
                                                      'MOBILE')
                                                  ? Icons.smartphone
                                                  : Icons.games,
                                              color: theme.colorScheme.primary,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              data['category'] ?? 'Lainnya',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    theme.colorScheme.primary,
                                                fontFamily: 'playpen',
                                              ),
                                            ),
                                          ],
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
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

Widget _buildProductListItem(BuildContext context, DocumentSnapshot product) {
  final data = product.data() as Map<String, dynamic>;
  final Timestamp timestamp = data['createdAt'];
  final createdAt = timestamp.toDate();
  final String heroTag = 'semuria-list-${createdAt.millisecondsSinceEpoch}';
  final theme = Theme.of(context);

  return InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  DetailScreen(productId: product.id, heroTag: heroTag),
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 0),
      height: 120,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.onPrimary, width: 1),
        ),
      ),
      child: Expanded(
        child: Row(
          children: [
            // Image Section
            Container(
              width: 130,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black87.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child:
                    data['posterImageBase64'] != null
                        ? Hero(
                          tag: heroTag,
                          child: Image.memory(
                            base64Decode(data['posterImageBase64']),
                            fit: BoxFit.cover,
                          ),
                        )
                        : Container(
                          color: theme.colorScheme.primary,
                          child: Icon(
                            Icons.image_not_supported,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
              ),
            ),
            SizedBox(width: 10),

            // Content Section
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data['name'] ?? 'Produk',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                      fontFamily: 'playpen',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        data['category'] == 'WINDOWS' ||
                                data['category'] == 'LAPTOP/PC'
                            ? Icons.computer
                            : (data['category'] == 'PS4' ||
                                data['category'] == 'PS5' ||
                                data['category'] == 'PS3' ||
                                data['category'] == 'PS2' ||
                                data['category'] == 'PS1')
                            ? Icons.videogame_asset
                            : (data['category'] == 'MOBILE')
                            ? Icons.smartphone
                            : Icons.games,
                        color: theme.colorScheme.onPrimary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data['category'] ?? 'Lainnya',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onPrimary,
                          fontFamily: 'playpen',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: theme.colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data['fullName'] ?? 'Anonim',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onPrimary,
                          fontFamily: 'playpen',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 4),
            // Price Section
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 4.0, left: 4.0),
                  child: Text(
                    'Rp ${NumberFormat('#,###', 'id_ID').format(int.tryParse(data['price']?.toString() ?? '0') ?? 0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                      fontFamily: 'playpen',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
