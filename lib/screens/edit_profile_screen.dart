import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:semuria/services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String? currentUsername;
  final String? backdropP;
  final String? profileP;

  const EditProfileScreen({
    super.key,
    required this.currentUsername,
    required this.backdropP,
    required this.profileP,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _usernameController;
  bool _isSaving = false;

  String? _newProfileBase64;
  String? _newBackdropBase64;
  File? _profileImage;

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.currentUsername);
    _newProfileBase64 = widget.profileP;
    _newBackdropBase64 = widget.backdropP;

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
                    title: const Text(
                      "Ambil dari Kamera",
                      style: TextStyle(fontFamily: 'playpen'),
                    ),
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
            _newProfileBase64 = base64Encode(compressed);
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
            _newBackdropBase64 = base64Encode(compressed);
          });
        }
      }
    } catch (e) {
      _showErrorSnackbar("Gagal memilih backdrop: $e");
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _userService.updateProfile(
        username: _usernameController.text.trim(),
        profileP: _newProfileBase64,
        backdropP: _newBackdropBase64,
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Profil berhasil diperbarui!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar("Gagal menyimpan perubahan: $e");
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage:
                          _newProfileBase64 != null
                              ? MemoryImage(base64Decode(_newProfileBase64!))
                              : null,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.secondary.withOpacity(0.1),
                      child:
                          _newProfileBase64 == null
                              ? Icon(
                                Icons.person,
                                size: 50,
                                color: Theme.of(context).colorScheme.secondary,
                              )
                              : null,
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
                color: Theme.of(context).colorScheme.onBackground,
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
                    color: Theme.of(context).colorScheme.onBackground,
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
                    foregroundColor: Theme.of(context).colorScheme.onBackground,
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
                      _newBackdropBase64 == null
                          ? Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.1)
                          : null,
                  borderRadius: BorderRadius.circular(16),
                  image:
                      _newBackdropBase64 != null
                          ? DecorationImage(
                            image: MemoryImage(
                              base64Decode(_newBackdropBase64!),
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
                    _newBackdropBase64 == null
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.back,
            color: theme.colorScheme.onBackground,
          ),
          onPressed: () {
            Navigator.of(context).pop(); 
          },
        ),
        title: Text(
          "Edit Profil",
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildProfileImagePicker(),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: TextFormField(
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
                          color: theme.colorScheme.onBackground,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.onBackground.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.onBackground,
                          width: 2,
                        ),
                      ),
                      labelStyle: TextStyle(
                        color: theme.colorScheme.onBackground,
                        fontFamily: 'playpen',
                      ),
                    ),
                    style: const TextStyle(fontFamily: 'playpen'),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Username wajib diisi'
                                : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: theme.colorScheme.onSecondary,
                        elevation: 2,
                        shadowColor: theme.colorScheme.secondary.withOpacity(
                          0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          _isSaving
                              ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: theme.colorScheme.onSecondary,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                "Simpan Perubahan",
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
      ),
    );
  }
}
