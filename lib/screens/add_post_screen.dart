import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  Uint8List? _posterImage;
  Uint8List? _backdropImage;
  String? _selectedCategory = 'LAPTOP/PC';
  int _selectedIndex = 0;
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
    final price = int.tryParse(_priceController.text.replaceAll('Rp. ', ''));
    if (price != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final uid = user.uid;

        try {
          // Ambil nama pengguna dari Firestore
          final userDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .get();
          final username = userDoc.data()?['username'] ?? 'Unknown';

          // Encode images to Base64
          final posterBase64 = await _encodeImage(_posterImage);
          final backdropBase64 = await _encodeImage(_backdropImage);

          // Simpan data produk ke Firestore
          await FirebaseFirestore.instance.collection('products').add({
            'name': _nameController.text.toUpperCase(),
            'description': _descController.text,
            'price': price,
            'posterImageBase64': posterBase64,
            'backdropImageBase64': backdropBase64,
            'createdAt': FieldValue.serverTimestamp(),
            'userId': uid,
            'category': categories[_selectedIndex],
            'fullName': username,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produk berhasil ditambahkan!'),
              backgroundColor: Color.fromARGB(255, 159, 255, 115),
            ),
          );

          await Future.delayed(const Duration(seconds: 2));

          Navigator.pop(context);
        } catch (e) {
          print('Gagal mengunggah produk: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menambahkan produk. Mohon coba lagi.'),
            ),
          );
        }
      } else {
        print("User Tidak Log In.");
      }
    } else {
      print("Harga Produk Tidak Valid.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.send, size: 48, color: colorScheme.onSurface),
            const SizedBox(width: 8),
            Text(
              "Tambah Produk",
              style: TextStyle(
                fontFamily: 'playpen',
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildLabel("Mohon isi Nama Produk."),
              _buildTextField(_nameController),
              const SizedBox(height: 16),
              _buildLabel("Mohon isi deskripsi produk."),
              _buildTextField(_descController, maxLines: 3),
              const SizedBox(height: 16),
              _buildLabel("Pilih Kategori Produk"),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
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
              const SizedBox(height: 16),
              _buildLabel("Masukkan Poster Produk."),
              _buildImageUploader(
                isPoster: true,
                image: _posterImage,
                label: "Unggah Poster",
              ),
              const SizedBox(height: 16),
              _buildLabel("Masukkan Backdrop Produk."),
              _buildImageUploader(
                isPoster: false,
                image: _backdropImage,
                label: "Unggah backdrop",
              ),
              const SizedBox(height: 16),
              _buildLabel("Mohon masukkan harga produk."),
              _buildPriceTextField(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.check, color: colorScheme.primary),
                  label: Text(
                    "Submit",
                    style: TextStyle(
                      fontFamily: 'playpen',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.primary,
                    ),
                  ),
                  onPressed: _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'playpen',
                      fontWeight: FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Widget _buildLabel(String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontFamily: 'playpen',
          fontSize: 14,
          color: colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: colorScheme.onPrimary, fontFamily: 'playpen'),
      decoration: InputDecoration(
        hintText: 'Ketik disini',
        border: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.onPrimary, width: 1),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildPriceTextField() {
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: _priceController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: colorScheme.onPrimary, fontFamily: 'playpen'),
      decoration: InputDecoration(
        hintText: '0',
        prefixText: 'Rp. ',
        border: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.onPrimary, width: 1),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
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
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          border: Border.all(color: colorScheme.onPrimary),
          borderRadius: BorderRadius.circular(12),
        ),
        child:
            image != null
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(image, fit: BoxFit.cover),
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 40,
                      color: colorScheme.onPrimary,
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontFamily: 'playpen',
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "seret dan lepas gambar di sini, atau klik untuk memilih",
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontFamily: 'playpen',
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
      ),
    );
  }
}
