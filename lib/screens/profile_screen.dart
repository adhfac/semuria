import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:semuria/screens/edit_profile_screen.dart';
import 'package:semuria/screens/setting_screen.dart';
import 'package:semuria/services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark, // untuk iOS
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
      // Handle error if needed
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
            ),
      ),
    );

    if (result == true) {
      _loadUserData(); // refresh data setelah edit
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // AppBar has been removed
      body: Stack(
        children: [
          // Main content
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: colorScheme.secondary),
              )
              : _userData == null
              ? Center(
                child: Text(
                  'No user data found',
                  style: TextStyle(
                    color: colorScheme.tertiary,
                    fontFamily: 'playpen',
                  ),
                ),
              )
              : _buildProfileContent(),

          // Settings button positioned in the top right corner with adaptive coloring
          Positioned(
            top:
                MediaQuery.of(context).padding.top +
                8, // Account for status bar
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.7),
                    Colors.black.withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder:
                          (context, animation, secondaryAnimation) =>
                              const SettingScreen(),
                      transitionsBuilder: (
                        context,
                        animation,
                        secondaryAnimation,
                        child,
                      ) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        var tween = Tween(
                          begin: begin,
                          end: end,
                        ).chain(CurveTween(curve: Curves.easeInOut));
                        var offsetAnimation = animation.drive(tween);
                        return SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        );
                      },
                    ),
                  );
                },
                icon: Icon(
                  Icons.settings_outlined,
                  color: Colors.white, // Light icon on dark backgrounds
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 3),
                  ],
                ),
                iconSize: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with backdrop image
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 180 + MediaQuery.of(context).padding.top,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                ),
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

              // Profile picture
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

          // Space for the overlapping profile picture
          const SizedBox(height: 70),

          // User information section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _userData!['username'] ?? 'No Username',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.tertiary,
                    fontFamily: 'playpen',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatAddress(_userData!['address'] ?? ''),
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.tertiary.withOpacity(0.7),
                        fontFamily: 'playpen',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Edit profile button
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _navigateToEditProfile,
                  icon: const Icon(Icons.edit),
                  label: Text(
                    'Edit Profile',
                    style: TextStyle(fontFamily: 'playpen'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: colorScheme.onSecondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    elevation: 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAddress(String fullAddress) {
    // Extract only the administrative area and country from the full address
    if (fullAddress.isEmpty) {
      return 'No location';
    }

    // Parse the address which is in format: street, subLocality, locality, administrativeArea, country
    final addressParts = fullAddress.split(', ');

    // If the address doesn't have enough parts, return what we have
    if (addressParts.length < 5) {
      return fullAddress;
    }

    // Extract administrative area and country (last two parts)
    final administrativeArea = addressParts[addressParts.length - 2];
    final country = addressParts[addressParts.length - 1];

    return '$administrativeArea, $country';
  }
}
