import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:semuria/services/user_service.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _picker = ImagePicker();
  File? _profileImage;
  String? _base64ProfileImage;
  String? _base64BackdropImage;
  double? _latitude;
  double? _longitude;
  String? _address;
  bool _isSubmitting = false;
  bool _isLoadingLocation = true;
  bool _locationError = false;

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _userService = UserService();

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Start fetching user location
    _getUserLocation();

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _showImageSourceModal({required bool isProfileImage}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isProfileImage ? "Pilih Foto Profil" : "Pilih Backdrop",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.secondary,
                      fontFamily: 'playpen',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.secondary.withOpacity(0.1),
                      child: Icon(
                        Icons.camera_alt,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    title: const Text("Ambil dari Kamera", style: TextStyle(fontFamily: 'playpen'),),
                    onTap: () {
                      Navigator.pop(context);
                      if (isProfileImage) {
                        _pickProfileImage(ImageSource.camera);
                      } else {
                        _pickBackdropImage(ImageSource.camera);
                      }
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.secondary.withOpacity(0.1),
                      child: Icon(
                        Icons.image,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    title: const Text(
                      "Pilih dari Galeri",
                      style: TextStyle(fontFamily: 'playpen'),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (isProfileImage) {
                        _pickProfileImage(ImageSource.gallery);
                      } else {
                        _pickBackdropImage(ImageSource.gallery);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked != null) {
        File imageFile = File(picked.path);
        final compressed = await FlutterImageCompress.compressWithFile(
          imageFile.path,
          quality: 50,
        );
        if (compressed != null) {
          setState(() {
            _profileImage = imageFile;
            _base64ProfileImage = base64Encode(compressed);
          });
        }
      }
    } catch (e) {
      _showErrorSnackbar("Gagal memilih foto: $e");
    }
  }

  Future<void> _pickBackdropImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked != null) {
        File imageFile = File(picked.path);
        final compressed = await FlutterImageCompress.compressWithFile(
          imageFile.path,
          quality: 50,
        );
        if (compressed != null) {
          setState(() {
            _base64BackdropImage = base64Encode(compressed);
          });
        }
      }
    } catch (e) {
      _showErrorSnackbar("Gagal memilih backdrop: $e");
    }
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location services are disabled.')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location permissions are denied.')),
          );
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10));

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String addressText = "Unknown";
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        addressText =
            '${p.street}, ${p.subLocality}, ${p.locality}, ${p.administrativeArea}, ${p.country}';
      }

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _address = addressText;
        _isLoadingLocation = false;
        _locationError = false;
      });
    } catch (e) {
      debugPrint('Failed to retrieve location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to retrieve location: $e')),
      );
      setState(() {
        _latitude = null;
        _longitude = null;
        _address = null;
        _isLoadingLocation = false;
        _locationError = true;
      });
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _submitRegistration() async {
    // Form validation
    if (_usernameController.text.isEmpty) {
      _showErrorSnackbar("Username tidak boleh kosong");
      return;
    }

    if (_latitude == null || _longitude == null || _address == null) {
      _showErrorSnackbar("Data lokasi belum tersedia");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _userService.createUser(
        username: _usernameController.text.trim(),
        latitude: _latitude!,
        longitude: _longitude!,
        address: _address!,
        profileP: _base64ProfileImage ?? '',
        backdropP: _base64BackdropImage ?? '',
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Registrasi berhasil!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to home
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomePage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint("Register failed: $e");
      _showErrorSnackbar("Gagal menyimpan data");
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildProfileImagePicker() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            Stack(
              children: [
                GestureDetector(
                  onTap: () => _showImageSourceModal(isProfileImage: true),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child:
                        _profileImage != null
                            ? CircleAvatar(
                              radius: 60,
                              backgroundImage: FileImage(_profileImage!),
                            )
                            : CircleAvatar(
                              radius: 60,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondary.withOpacity(0.1),
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Theme.of(context).colorScheme.onSecondary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Foto Profil",
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w500,
                fontFamily: 'playpen',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackdropImagePicker() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Backdrop Image",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.secondary,
                    fontFamily: 'playpen',
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showImageSourceModal(isProfileImage: false),
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text(
                    "Pilih",
                    style: TextStyle(fontFamily: 'playpen'),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showImageSourceModal(isProfileImage: false),
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color:
                      _base64BackdropImage == null
                          ? Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.1)
                          : null,
                  borderRadius: BorderRadius.circular(16),
                  image:
                      _base64BackdropImage != null
                          ? DecorationImage(
                            image: MemoryImage(
                              base64Decode(_base64BackdropImage!),
                            ),
                            fit: BoxFit.cover,
                          )
                          : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child:
                    _base64BackdropImage == null
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 40,
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondary.withOpacity(0.7),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Tambahkan Gambar Backdrop",
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary.withOpacity(0.7),
                                  fontFamily: 'playpen',
                                ),
                              ),
                            ],
                          ),
                        )
                        : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                _locationError
                    ? Colors.red.withOpacity(0.1)
                    : Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _locationError ? Icons.location_off : Icons.location_on,
                    color:
                        _locationError
                            ? Colors.red
                            : Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Lokasi",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'playpen',
                      color:
                          _locationError
                              ? Colors.red
                              : Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const Spacer(),
                  if (_locationError)
                    TextButton.icon(
                      onPressed: _getUserLocation,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text("Coba lagi"),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        foregroundColor: Colors.red,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              _isLoadingLocation
                  ? Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Mendapatkan lokasi...",
                        style: TextStyle(fontFamily: 'playpen'),
                      ),
                    ],
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _address ?? "Lokasi tidak tersedia",
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontFamily: 'playpen',
                        ),
                      ),
                      if (_latitude != null && _longitude != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "Koordinat: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}",
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'playpen',
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Lengkapi Profil",
          style: TextStyle(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.bold,
            fontFamily: 'playpen',
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildProfileImagePicker(),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: "Username",
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: theme.colorScheme.secondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.secondary.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.secondary,
                        width: 2,
                      ),
                    ),
                    labelStyle: TextStyle(
                      color: theme.colorScheme.secondary.withOpacity(0.8),
                      fontFamily: 'playpen',
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'playpen'),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildLocationInfo(),
            const SizedBox(height: 24),
            _buildBackdropImagePicker(),
            const SizedBox(height: 32),
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                      elevation: 2,
                      shadowColor: theme.colorScheme.secondary.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isSubmitting
                            ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: theme.colorScheme.onSecondary,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              "Simpan",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'playpen',
                              ),
                            ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
