import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CheckoutScreen extends StatefulWidget {
  final String productName;
  final String platform;
  final int price;
  final String sellerName;
  final String imageBase64;

  const CheckoutScreen({
    Key? key,
    required this.productName,
    required this.platform,
    required this.price,
    required this.sellerName,
    required this.imageBase64, required imageUrl,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Gambar produk
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

            // Nama produk
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

            // Platform / Kategori
            Text(
              'Platform: ${widget.platform}',
              style: const TextStyle(fontSize: 16, fontFamily: 'playpen'),
            ),
            const SizedBox(height: 8),

            // Harga
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
    mainAxisSize: MainAxisSize.min, // biar Row sesuaikan lebar isinya saja
    children: [
      const Icon(
        Icons.person_outline,
        size: 24,
        color: Colors.grey,
      ),
      const SizedBox(width: 8),
      Text(
        widget.sellerName,
        style: const TextStyle(fontSize: 16, fontFamily: 'playpen'),
      ),
    ],
  ),
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
                onPressed: () {
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Checkout berhasil! Terima kasih sudah membeli.',
                        style: TextStyle(fontFamily: 'playpen'),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
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
