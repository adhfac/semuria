import 'dart:typed_data';
import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:semuria/screens/profile_screen.dart';

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

  int _selectedIndex = 0;

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
        final fullName = user.displayName ?? 'Unknown';

        try {
          // Encode images to Base64
          final posterBase64 = await _encodeImage(_posterImage);
          final backdropBase64 = await _encodeImage(_backdropImage);

          // Simpan data produk ke Firestore
          await FirebaseFirestore.instance.collection('products').add({
            'name': _nameController.text,
            'description': _descController.text,
            'price': price,
            'posterImageBase64': posterBase64,
            'backdropImageBase64': backdropBase64,
            'createdAt': FieldValue.serverTimestamp(),
            'userId': uid,
            'fullName': fullName,
          });

          ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text(
      'Product added successfully!',
    ),
    backgroundColor: Color.fromARGB(255, 159, 255, 115),
  ),
);


await Future.delayed(const Duration(seconds: 2));

Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => const ProfileScreen()),
);

        } catch (e) {
          print('Error uploading product: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to add product. Please try again.')),
          );
        }
      } else {
        print("User is not logged in.");
      }
    } else {
      print("Invalid price input.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Add Produk",
          style: TextStyle(
            fontFamily: 'playpen',
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.send, size: 48),
              const SizedBox(height: 12),
              _buildLabel("Please enter the product name."),
              _buildTextField(_nameController),
              const SizedBox(height: 16),
              _buildLabel("Please enter the product Description."),
              _buildTextField(_descController, maxLines: 3),
              const SizedBox(height: 16),
              _buildLabel("Insert product poster."),
              _buildImageUploader(isPoster: true, image: _posterImage, label: "Upload a poster"),
              const SizedBox(height: 16),
              _buildLabel("Insert product backdrop."),
              _buildImageUploader(isPoster: false, image: _backdropImage, label: "Upload a backdrop"),
              const SizedBox(height: 16),
              _buildLabel("Please enter the price"),
              _buildPriceTextField(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text("Submit"),
                  onPressed: _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
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
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: colorScheme.secondary,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: colorScheme.onSecondary,
        unselectedItemColor: colorScheme.onSecondary.withOpacity(0.6),
        showSelectedLabels: true,
        showUnselectedLabels: false,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'playpen',
          fontWeight: FontWeight.bold,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontFamily: 'playpen',
          fontSize: 14,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black),
      decoration: const InputDecoration(
        hintText: 'Type here',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildPriceTextField() {
    return TextField(
      controller: _priceController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.black),
      decoration: const InputDecoration(
        hintText: '0',
        prefixText: 'Rp. ',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildImageUploader({
    required bool isPoster,
    required Uint8List? image,
    required String label,
  }) {
    return GestureDetector(
      onTap: () => _pickImage(isPoster),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(image, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const Text(
                    "Drag and drop file here",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }
}
