import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:semuria/screens/detail_transaction_screen.dart';

class InboxScreen extends StatelessWidget {
  final String userIdPenjual;

  const InboxScreen({Key? key, required this.userIdPenjual}) : super(key: key);

  Stream<QuerySnapshot> getPendingTransaksi() {
    return FirebaseFirestore.instance
        .collection('transaksi')
        .where('idUser_penjual', isEqualTo: userIdPenjual)
        .where('status', isEqualTo: 'pending')
        .orderBy('tanggal', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      appBar: AppBar(
        title: Text(
          'Inbox Pesanan Masuk',
          style: TextStyle(
            fontFamily: 'playpen',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.tertiary,
          ),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.tertiary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: colorScheme.onBackground,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getPendingTransaksi(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: colorScheme.secondary,
                strokeWidth: 3,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 80,
                    color: colorScheme.tertiary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada pesanan masuk',
                    style: TextStyle(
                      fontFamily: 'playpen',
                      fontSize: 18,
                      color: colorScheme.tertiary.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pesanan akan muncul di sini',
                    style: TextStyle(
                      fontFamily: 'playpen',
                      fontSize: 14,
                      color: colorScheme.tertiary.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            );
          }

          final transaksiList = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ListView.builder(
              itemCount: transaksiList.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final data =
                    transaksiList[index].data() as Map<String, dynamic>;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.tertiary.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.tertiary.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        color: colorScheme.secondary,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      data['nama_produk'] ?? 'Produk',
                      style: TextStyle(
                        fontFamily: 'playpen',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.tertiary,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Dari: ${data['nama_pembeli'] ?? 'Pembeli'}',
                        style: TextStyle(
                          fontFamily: 'playpen',
                          fontSize: 14,
                          color: colorScheme.tertiary.withOpacity(0.6),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Rp ${_formatCurrency(data['harga'])}',
                        style: TextStyle(
                          fontFamily: 'playpen',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSecondary,
                        ),
                      ),
                    ),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => DetailTransactionScreen(
                                transactionId: transaksiList[index].id,
                                transactionData: data,
                              ),
                        ),
                      );

                      // Refresh if status was changed
                      if (result == true) {
                        // Refresh your data
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatCurrency(dynamic price) {
    if (price == null) return '0';

    String priceStr = price.toString().replaceAll(RegExp(r'[^\d]'), '');

    if (priceStr.isEmpty) return '0';

    int priceInt = int.tryParse(priceStr) ?? 0;
    return priceInt.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
