import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CheckoutScreen extends StatefulWidget {
  final String productName;
  final String platform;
  final int price;
  final String sellerName;
  final String userId;
  final String imageBase64;
  final String? idProduk;

  const CheckoutScreen({
    Key? key,
    required this.productName,
    required this.platform,
    required this.price,
    required this.sellerName,
    required this.userId,
    required this.imageBase64,
    required this.idProduk,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with TickerProviderStateMixin {
  bool _isCODSelected = false;
  bool _isTransferSelected = false;
  bool _isLoading = false;
  static const Color secondaryColor = Color(0xFFA80038); // Merah

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
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
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String get selectedPaymentMethod {
    if (_isCODSelected) return 'Cash On Delivery';
    if (_isTransferSelected) return 'Bank Transfer';
    return '';
  }

  bool get isPaymentMethodSelected => _isCODSelected || _isTransferSelected;

  Future<void> _showConfirmationDialog() async {
    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.shopping_cart_checkout, color: secondaryColor),
                SizedBox(width: 8),
                Text(
                  'Konfirmasi Pembelian',
                  style: TextStyle(
                    fontFamily: 'playpen',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Produk: ${widget.productName}',
                  style: TextStyle(
                    fontFamily: 'playpen',
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Harga: ${currencyFormat.format(widget.price)}',
                  style: TextStyle(
                    fontFamily: 'playpen',
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Metode: $selectedPaymentMethod',
                  style: TextStyle(
                    fontFamily: 'playpen',
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Apakah Anda yakin ingin melanjutkan pembelian?',
                  style: TextStyle(
                    fontFamily: 'playpen',
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Batal',
                  style: TextStyle(
                    fontFamily: 'playpen',
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Ya, Beli',
                  style: TextStyle(
                    fontFamily: 'playpen',
                    color: theme.colorScheme.onSecondary,
                  ),
                ),
              ),
            ],
          ),
    );

    if (result == true) {
      await simpanTransaksiKeFirestore();
    }
  }

  Future<String?> getUsername() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return null;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    if (doc.exists) {
      final data = doc.data();
      return data?['username'];
    }

    return null;
  }

  Future<void> simpanTransaksiKeFirestore() async {
    if (!isPaymentMethodSelected) {
      _showErrorSnackBar('Silakan pilih metode pembayaran terlebih dahulu.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _showErrorSnackBar('Pengguna belum login.');
        return;
      }

      final username = await getUsername();

      final transaksiRef =
          FirebaseFirestore.instance.collection('transaksi').doc();

      await transaksiRef.set({
        'id_pembelian': transaksiRef.id,
        'idUser_pembeli': user.uid,
        'idUser_penjual': widget.userId,
        'nama_produk': widget.productName,
        'platform': widget.platform,
        'harga': widget.price,
        'penjual': widget.sellerName,
        'nama_pembeli': username,
        'metode_pembayaran': selectedPaymentMethod,
        'tanggal': Timestamp.now(),
        'status': 'pending',
        'id_produk' : widget.idProduk,
        'image_base64': widget.imageBase64,
      });

      _showSuccessSnackBar('Checkout berhasil! Transaksi tersimpan.');

      // Navigate back after successful transaction
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorSnackBar('Gagal menyimpan transaksi: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontFamily: 'playpen'),
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontFamily: 'playpen'),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:
            isSelected
                ? theme.colorScheme.secondary.withOpacity(0.1)
                : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isSelected ? theme.colorScheme.secondary : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? theme.colorScheme.secondary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor ?? theme.colorScheme.secondary,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'playpen',
            fontWeight: FontWeight.w600,
            color:
                isSelected
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'playpen',
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  isSelected
                      ? theme.colorScheme.secondary
                      : Colors.grey.shade400,
              width: 2,
            ),
            color:
                isSelected ? theme.colorScheme.secondary : Colors.transparent,
          ),
          child:
              isSelected
                  ? Icon(
                    Icons.check,
                    color: theme.colorScheme.onSecondary,
                    size: 16,
                  )
                  : null,
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: TextStyle(
            fontFamily: 'playpen',
            color: theme.colorScheme.onBackground,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.onSurface.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child:
                          widget.imageBase64.isNotEmpty
                              ? Image.memory(
                                base64Decode(widget.imageBase64),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                              : Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 30,
                                ),
                              ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.productName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'playpen',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.platform,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                fontFamily: 'playpen',
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currencyFormat.format(widget.price),
                            style: TextStyle(
                              fontSize: 18,
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'playpen',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.store,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.sellerName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontFamily: 'playpen',
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

              const SizedBox(height: 24),

              // Payment Methods Section
              Text(
                'Metode Pembayaran',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'playpen',
                  color: theme.colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 16),

              _buildPaymentOption(
                title: 'Cash On Delivery',
                subtitle: 'Bayar saat barang diterima',
                icon: Icons.local_shipping,
                isSelected: _isCODSelected,
                onTap: () {
                  setState(() {
                    _isCODSelected = !_isCODSelected;
                    if (_isCODSelected) _isTransferSelected = false;
                  });
                },
              ),

              // Order Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ringkasan Pesanan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'playpen',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Harga Produk',
                          style: TextStyle(fontFamily: 'playpen'),
                        ),
                        Text(
                          currencyFormat.format(widget.price),
                          style: const TextStyle(fontFamily: 'playpen'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Biaya Admin',
                          style: TextStyle(fontFamily: 'playpen'),
                        ),
                        Text(
                          'Gratis',
                          style: TextStyle(
                            fontFamily: 'playpen',
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'playpen',
                          ),
                        ),
                        Text(
                          currencyFormat.format(widget.price),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                            fontFamily: 'playpen',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isPaymentMethodSelected
                        ? theme.colorScheme.secondary
                        : Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: isPaymentMethodSelected ? 2 : 0,
              ),
              onPressed:
                  _isLoading
                      ? null
                      : isPaymentMethodSelected
                      ? _showConfirmationDialog
                      : null,
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
                        'Bayar Sekarang',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'playpen',
                          color: theme.colorScheme.onSecondary,
                        ),
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
