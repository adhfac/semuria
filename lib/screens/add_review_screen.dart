import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

Color secondaryColor = Color(0xFFA80038); // Merah
Color accentColor = Color(0xFF2B2024); // Hitam

class AddReviewScreen extends StatefulWidget {
  final String productId;

  const AddReviewScreen({super.key, required this.productId});

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen>
    with TickerProviderStateMixin {
  final TextEditingController _komentarController = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final CollectionReference reviews = FirebaseFirestore.instance.collection(
    'reviews',
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _komentarController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      _showCustomSnackBar(
        'Silakan pilih rating bintang',
        Icons.star_border,
        Colors.orange,
      );
      return;
    }
    if (_komentarController.text.trim().isEmpty) {
      _showCustomSnackBar(
        'Komentar tidak boleh kosong',
        Icons.comment,
        Colors.orange,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      await Future.delayed(const Duration(milliseconds: 500));

      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final username = userDoc.data()?['username'] ?? 'Anonim';

      try {
        await reviews.add({
          'userId': uid,
          'fullName': username,
          'productId': widget.productId,
          'rating': _rating,
          'komentar': _komentarController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        HapticFeedback.mediumImpact();

        _showCustomSnackBar(
          'Review berhasil ditambahkan!',
          Icons.check_circle,
          Colors.green,
        );

        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context);
      } catch (e) {
        print('Gagal menambahkan review: $e');
        _showCustomSnackBar(
          'Gagal menambahkan review. Mohon coba lagi.',
          Icons.error_outline,
          secondaryColor,
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    } else {
      _showCustomSnackBar(
        'Anda harus login untuk memberikan review.',
        Icons.login,
        secondaryColor,
      );
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showCustomSnackBar(String message, IconData icon, Color color) {
    final theme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: theme.onPrimary, size: 20),
              ),
              const SizedBox(width: 16),
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
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        elevation: 8,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget buildStar(int index) {
    final isSelected = index < _rating;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _rating = index + 1;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.elasticOut,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: AnimatedScale(
            scale: isSelected ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                        : null,
              ),
              child: Icon(
                isSelected ? Icons.star : Icons.star_border,
                color: isSelected ? Colors.amber : Colors.grey[400],
                size: 32,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: theme.primary,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.primary,
        foregroundColor: accentColor,
        title: Text(
          'Tambah Review',
          style: TextStyle(
            fontFamily: 'playpen',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: theme.onPrimary,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: theme.onBackground,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: secondaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          Icons.rate_review,
                          size: 32,
                          color: secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bagaimana pengalaman Anda?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'playpen',
                          color: theme.onPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Berikan rating dan ulasan untuk membantu pengguna lain',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.onPrimary.withOpacity(0.7),
                          fontFamily: 'playpen',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Rating Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Rating Bintang',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'playpen',
                          color: theme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primary,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                _rating > 0
                                    ? Colors.amber.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(
                            5,
                            (index) => buildStar(index),
                          ),
                        ),
                      ),
                      if (_rating > 0) ...[
                        const SizedBox(height: 12),
                        AnimatedOpacity(
                          opacity: _rating > 0 ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _getRatingText(_rating),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: secondaryColor,
                              fontFamily: 'playpen',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Comment Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tulis Ulasan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'playpen',
                          color: theme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: _komentarController,
                          maxLines: 5,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'playpen',
                            color: theme.onPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Ceritakan pengalaman Anda dengan produk ini...',
                            hintStyle: TextStyle(
                              color: theme.onPrimary.withOpacity(0.5),
                              fontFamily: 'playpen',
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Submit Button
                Container(
                  height: 56,
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
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child:
                        _isSubmitting
                            ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Mengirim...',
                                  style: TextStyle(
                                    fontFamily: 'playpen',
                                    color: theme.onPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                            : Text(
                              'Kirim Review',
                              style: TextStyle(
                                fontFamily: 'playpen',
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Sangat Buruk';
      case 2:
        return 'Buruk';
      case 3:
        return 'Biasa';
      case 4:
        return 'Bagus';
      case 5:
        return 'Sangat Bagus';
      default:
        return '';
    }
  }
}
