import 'dart:io';
import 'dart:convert';
import 'package:semuria/screens/auth_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const ProfileScreen(),
  ];

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
                    color: theme.colorScheme.onBackground,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                content: Text(
                  'Kamu akan meninggalkan aplikasi ini, kamu serius? 😭🙏',
                  style: TextStyle(
                    fontFamily: 'playpen',
                    color: theme.colorScheme.onBackground,
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
                        color: theme.colorScheme.onBackground,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
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
          exit(0);
        }
      },
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: theme.colorScheme.secondary,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedItemColor: theme.colorScheme.onSecondary,
          unselectedItemColor: theme.colorScheme.onSecondary.withOpacity(0.6),
          showSelectedLabels: true,
          showUnselectedLabels: false,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'playpen',
            fontWeight: FontWeight.bold,
          ),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        title: Text(
          'Semuria',
          style: TextStyle(
            fontFamily: 'playpen',
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.secondary,
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
          onPressed: () {},
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: StreamBuilder(
          stream:
              FirebaseFirestore.instance
                  .collection('products')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.amber),
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
                          "Produk",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.filter_list,
                            color: Colors.white70,
                          ),
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
                        "Belum Ada Produk di Kategori ini.",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              );
            }

            // Group products by category
            Map<String, List<DocumentSnapshot>> productsByCategory = {};
            for (var product in products) {
              final data = product.data();
              final category = data['category'] ?? 'Lainnya';

              if (!productsByCategory.containsKey(category)) {
                productsByCategory[category] = [];
              }
              productsByCategory[category]!.add(product);
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...productsByCategory.entries.map((entry) {
                      return _buildProductCategory(entry.key, entry.value);
                    }).toList(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductCategory(String title, List<DocumentSnapshot> products) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final accentColor = theme.colorScheme.tertiary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
        ),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (BuildContext context, int index) {
              final data = products[index].data() as Map<String, dynamic>;
              final backdrpImageBase64 = data['backdrpImageBase64'];
              final description = data['description'];
              final price = data['price'] ?? 0;
              final posterImageBase64 = data['posterImageBase64'];
              final fullName = data['fullName'] ?? 'Anonim';
              final latitude = data['latitude'];
              final longitude = data['longitude'];
              final category = data['category'] ?? 'Lainnya';
              final Timestamp timestamp = data['createdAt'];
              final createdAt = timestamp.toDate();
              final String heroTag =
                  'semuria-posterImageBase64-${createdAt.millisecondsSinceEpoch}';

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => DetailScreen(
                              backdrpImageBase64: backdrpImageBase64,
                              posterImageBase64: posterImageBase64,
                              price: price,
                              description: description ?? '',
                              createdAt: createdAt,
                              fullName: fullName,
                              latitude: latitude,
                              longitude: longitude,
                              category: category,
                              heroTag: heroTag,
                            ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 125,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
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
                                          base64Decode(
                                            data['posterImageBase64'],
                                          ),
                                          fit: BoxFit.cover,
                                          width: 125,
                                          height: 200,
                                        ),
                                      )
                                      : Container(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.surface,
                                        child: Center(
                                          child: Icon(
                                            Icons.image_not_supported,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onBackground
                                                .withOpacity(0.5),
                                          ),
                                        ),
                                      ),
                            ),
                          ),

                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepOrange,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Rp ${NumberFormat('#,###', 'id_ID').format(int.tryParse(data['price']?.toString() ?? '0') ?? 0)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Container(
                        width: 125,
                        child: Center(
                          child: Text(
                            data['name']?.length > 14
                                ? '${data['name'].substring(0, 10)}...'
                                : (data['name'] ?? 'Produk'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
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
}
