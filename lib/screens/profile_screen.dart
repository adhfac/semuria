import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
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
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body:
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
                Text(
                  _userData!['email'] ?? 'No Email',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.tertiary.withOpacity(0.7),
                    fontFamily: 'playpen',
                  ),
                ),
                const SizedBox(height: 24),

                // Address section
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: colorScheme.surface,
                  shadowColor: colorScheme.secondary.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Address',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'playpen',
                                color: colorScheme.tertiary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _userData!['address'] ?? 'No Address',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'playpen',
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Account info section
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: colorScheme.surface,
                  shadowColor: colorScheme.secondary.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Account Info',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'playpen',
                                color: colorScheme.tertiary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _userData!['createdAt'] != null
                            ? Text(
                              'Member since: ${_formatDate(_userData!['createdAt'])}',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'playpen',
                                color: colorScheme.onSurface,
                              ),
                            )
                            : Text(
                              'Member since: Unknown',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'playpen',
                                color: colorScheme.onSurface,
                              ),
                            ),
                      ],
                    ),
                  ),
                ),

                // Edit profile button
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {},
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

  String _formatDate(dynamic timestamp) {
    // Handle different types of timestamps from Firestore
    if (timestamp is DateTime) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (timestamp.runtimeType.toString().contains('Timestamp')) {
      // Convert Firestore Timestamp to DateTime
      final DateTime dateTime = timestamp.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    return 'Unknown date';
  }
}
