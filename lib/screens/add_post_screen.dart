import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/services.dart';

const Color primaryColor = Color(0xFFFBF9FA);
const Color secondaryColor = Color(0xFFA80038);
const Color accentColor = Color(0xFF2B2024);

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Uint8List? _posterImage;
  Uint8List? _backdropImage;
  String? _selectedCategory = 'LAPTOP/PC';
  int _selectedIndex = 0;
  bool _isSubmitting = false;
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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isPoster) async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final Uint8List bytes = await file.readAsBytes();
      setState(() {
        if (isPoster) {
          _posterImage = bytes;
        } else {
          _backdropImage = bytes;
        }
      });
    }
  }

  Future<String> _encodeImage(Uint8List? image) async {
    if (image == null) {
      throw Exception("No image selected.");
    }
    try {
      final base64Image = base64Encode(image);
      return base64Image;
    } catch (e) {
      print('Error encoding image: $e');
      throw Exception('Error encoding image.');
    }
  }

  Future<void> _submitPost() async {
    if (_nameController.text.isEmpty) {
      _showErrorSnackBar('Nama produk tidak boleh kosong');
      return;
    }

    if (_descController.text.isEmpty) {
      _showErrorSnackBar('Deskripsi produk tidak boleh kosong');
      return;
    }

    if (_posterImage == null || _backdropImage == null) {
      _showErrorSnackBar('Mohon unggah kedua gambar produk');
      return;
    }

    final price = int.tryParse(_priceController.text.replaceAll('Rp. ', ''));
    if (price == null || price <= 0 || price > 999999999) {
      _showErrorSnackBar('Harga produk tidak valid');
      return;
    }

    final stock = int.tryParse(_stockController.text.replaceAll('Rp. ', ''));
    if (stock == null || stock <= 0 || stock > 999) {
      _showErrorSnackBar('Stok produk tidak valid');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      try {
        // Add small delay to show the loading state
        await Future.delayed(const Duration(milliseconds: 500));

        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final username = userDoc.data()?['username'] ?? 'Unknown';

        final posterBase64 = await _encodeImage(_posterImage);
        final backdropBase64 = await _encodeImage(_backdropImage);

        await FirebaseFirestore.instance.collection('products').add({
          'name': _nameController.text,
          'description': _descController.text,
          'price': price,
          'posterImageBase64': posterBase64,
          'backdropImageBase64': backdropBase64,
          'createdAt': DateTime.now(),
          'userId': uid,
          'category': categories[_selectedIndex],
          'fullName': username,
          'stock': stock,
          'isAvailable': stock > 0,
        });

        // Success haptic feedback
        HapticFeedback.mediumImpact();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text(
                  'Produk berhasil ditambahkan!',
                  style: TextStyle(fontFamily: 'playpen'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(12),
          ),
        );

        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context);
      } catch (e) {
        print('Gagal mengunggah produk: $e');
        _showErrorSnackBar('Gagal menambahkan produk. Mohon coba lagi.');
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    } else {
      _showErrorSnackBar('User tidak login. Mohon login terlebih dahulu.');
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.back,
            color: theme.colorScheme.onBackground,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Hero(
              tag: 'add_icon',
              child: Icon(
                Icons.add_box_rounded,
                size: 32,
                color: secondaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Tambah Produk",
              style: TextStyle(
                fontFamily: 'playpen',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(top: 10, bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_buildFormSection()],
                  ),
                ),
              ),
            ),
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black45,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          color: secondaryColor,
                          strokeWidth: 4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Menambahkan produk...',
                        style: TextStyle(
                          fontFamily: 'playpen',
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 100 * (1 - _animationController.value)),
            child: child,
          );
        },
        child: Container(
          color: colorScheme.surface,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 20 + MediaQuery.of(context).padding.bottom,
            top: 12,
          ),
          child: _buildSubmitButton(),
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormField(
          label: "Nama Produk",
          hint: "Masukkan nama produk",
          controller: _nameController,
          icon: Icons.shopping_bag_outlined,
          required: true,
        ),
        const SizedBox(height: 24),
        _buildFormField(
          label: "Deskripsi Produk",
          hint: "Deskripsikan produk Anda dengan detail",
          controller: _descController,
          maxLines: 3,
          icon: Icons.description_outlined,
          required: true,
        ),
        const SizedBox(height: 24),
        _buildCategorySelector(),
        const SizedBox(height: 24),
        _buildImageSection(),
        const SizedBox(height: 24),
        _buildFormField(
          label: "Harga Produk",
          hint: "0",
          controller: _priceController,
          keyboardType: TextInputType.number,
          prefixText: 'Rp. ',
          icon: Icons.monetization_on_outlined,
          required: true,
        ),
        Builder(
          builder: (context) {
            final price =
                int.tryParse(
                  _priceController.text
                      .replaceAll('Rp. ', '')
                      .replaceAll('.', ''),
                ) ??
                0;
            if (price > 999999999) {
              return Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                child: Text(
                  "Harga maksimal Rp. 999.999.999",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontFamily: 'playpen',
                  ),
                ),
              );
            }
            return SizedBox.shrink();
          },
        ),
        const SizedBox(height: 16),
        _buildFormField(
          label: "Jumlah Stock",
          hint: "0",
          controller: _stockController,
          keyboardType: TextInputType.number,
          icon: Icons.addchart_outlined,
          required: true,
        ),
        Builder(
          builder: (context) {
            final stock =
                int.tryParse(_stockController.text.replaceAll('.', '')) ?? 0;
            if (stock > 999) {
              return Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                child: Text(
                  "Stock maksimal 999",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontFamily: 'playpen',
                  ),
                ),
              );
            }
            return SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    IconData? icon,
    String? prefixText,
    bool required = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: secondaryColor),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'playpen',
                fontSize: 16,
                color: colorScheme.onPrimary,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: secondaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontFamily: 'playpen',
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            filled: true,
            fillColor: accentColor.withOpacity(0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: secondaryColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            hintStyle: TextStyle(
              color: colorScheme.onPrimary.withOpacity(0.5),
              fontFamily: 'playpen',
            ),
          ),
          cursorColor: secondaryColor,
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category_outlined, size: 18, color: secondaryColor),
            const SizedBox(width: 8),
            Text(
              "Kategori Produk",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'playpen',
                fontSize: 16,
                color: colorScheme.onPrimary,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                color: secondaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            icon: Icon(Icons.arrow_drop_down, color: secondaryColor),
            elevation: 2,
            dropdownColor: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontFamily: 'playpen',
              fontSize: 15,
            ),
            items:
                categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
                _selectedIndex = categories.indexOf(value!);
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.image_outlined, size: 18, color: secondaryColor),
            const SizedBox(width: 8),
            Text(
              "Gambar Produk",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'playpen',
                fontSize: 16,
                color: colorScheme.onPrimary,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                color: secondaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildImageUploader(
                isPoster: true,
                image: _posterImage,
                label: "Poster",
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildImageUploader(
                isPoster: false,
                image: _backdropImage,
                label: "Backdrop",
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "* Poster akan digunakan sebagai thumbnail dan backdrop sebagai latar detail produk",
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontFamily: 'playpen',
            fontSize: 12,
            color: colorScheme.onPrimary.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploader({
    required bool isPoster,
    required Uint8List? image,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _pickImage(isPoster),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 170,
        decoration: BoxDecoration(
          color:
              image != null
                  ? Colors.transparent
                  : accentColor.withOpacity(0.04),
          border: Border.all(
            color:
                image != null
                    ? secondaryColor
                    : colorScheme.onPrimary.withOpacity(0.2),
            width: image != null ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child:
              image != null
                  ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(image, fit: BoxFit.cover),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                          child: Text(
                            'Ketuk untuk ubah',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'playpen',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  )
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 36,
                        color: secondaryColor.withOpacity(0.7),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        label,
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontFamily: 'playpen',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          "Ketuk untuk unggah",
                          style: TextStyle(
                            color: colorScheme.onPrimary.withOpacity(0.6),
                            fontFamily: 'playpen',
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final colorScheme = Theme.of(context).colorScheme;

    bool hasValidInput =
        _nameController.text.isNotEmpty &&
        _descController.text.isNotEmpty &&
        _priceController.text.isNotEmpty &&
        _posterImage != null &&
        _backdropImage != null;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.9, end: hasValidInput ? 1.0 : 0.9),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitPost,
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          disabledBackgroundColor: secondaryColor.withOpacity(0.5),
          foregroundColor: colorScheme.surface,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_rounded,
              color: colorScheme.surface,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              "Tambahkan Produk",
              style: TextStyle(
                fontFamily: 'playpen',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
