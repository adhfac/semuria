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
  final String userId;       // <-- ID Penjual ditambahkan
  final String imageBase64;

  const CheckoutScreen({
    Key? key,
    required this.productName,
    required this.platform,
    required this.price,
    required this.sellerName,
    required this.userId,     // <-- Parameter baru
    required this.imageBase64,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isCODSelected = false;

  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  Future<void> simpanTransaksiKeFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengguna belum login.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Generate doc ID agar bisa simpan juga sebagai field id_pembelian
      final transaksiRef = FirebaseFirestore.instance.collection('transaksi').doc();

      await transaksiRef.set({
        'id_pembelian': transaksiRef.id,
        'idUser_pembeli': user.uid,
        'idUser_penjual': widget.userId,
        'nama_produk': widget.productName,
        'platform': widget.platform,
        'harga': widget.price,
        'penjual': widget.sellerName,
        'metode_pembayaran': _isCODSelected ? 'Cash On Delivery' : 'Lainnya',
        'tanggal': Timestamp.now(),
        'image_base64': widget.imageBase64,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Checkout berhasil! Transaksi tersimpan.',
            style: TextStyle(fontFamily: 'playpen'),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menyimpan transaksi: $e',
            style: const TextStyle(fontFamily: 'playpen'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: widget.imageBase64.isNotEmpty
                  ? Image.memory(
                      base64Decode(widget.imageBase64),
                      width: 120,
                      height: 180,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 120,
                      height: 180,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 50),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.productName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'playpen',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Platform: ${widget.platform}',
              style: const TextStyle(fontSize: 16, fontFamily: 'playpen'),
            ),
            const SizedBox(height: 8),
            Text(
              'Harga: ${currencyFormat.format(widget.price)}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.deepOrange,
                fontWeight: FontWeight.bold,
                fontFamily: 'playpen',
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_outline, size: 24, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    widget.sellerName,
                    style: const TextStyle(fontSize: 16, fontFamily: 'playpen'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'Metode Pembayaran',
                    style: TextStyle(
                      fontSize: 18,
                      color: theme.colorScheme.onBackground,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'playpen',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.white),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Cash On Delivery',
                          style: TextStyle(
                            fontSize: 18,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'playpen',
                          ),
                        ),
                        const Spacer(),
                        Checkbox(
                          value: _isCODSelected,
                          activeColor: Colors.green,
                          shape: const CircleBorder(),
                          onChanged: (bool? value) {
                            setState(() {
                              _isCODSelected = value ?? false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  await simpanTransaksiKeFirestore();
                },
                child: const Text(
                  'Beli Sekarang',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'playpen',
                    color: Colors.white,
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
