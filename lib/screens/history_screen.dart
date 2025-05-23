import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryScreen extends StatefulWidget {
  final String? currentUserId;

  const HistoryScreen({Key? key, required this.currentUserId})
    : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const Color secondaryColor = Color(0xFFFD0054); // Merah

  // Query pesanan masuk (user sebagai penjual, status diterima)
  Stream<QuerySnapshot> getTransaksiMasuk() {
    return FirebaseFirestore.instance
        .collection('transaksi')
        .where('idUser_penjual', isEqualTo: widget.currentUserId)
        .where('status', isEqualTo: 'diterima')
        .orderBy('tanggal', descending: true)
        .snapshots();
  }

  // Query pesanan keluar (user sebagai pembeli, tanpa filter status)
  Stream<QuerySnapshot> getTransaksiKeluar() {
    return FirebaseFirestore.instance
        .collection('transaksi')
        .where('idUser_pembeli', isEqualTo: widget.currentUserId)
        .orderBy('tanggal', descending: true)
        .snapshots();
  }

  String _formatCurrency(dynamic price) {
    if (price == null) return 'Rp 0';
    return 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'diterima':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'ditolak':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTransactionCard(Map<String, dynamic> data, bool isIncoming) {
    final theme = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.onPrimary.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: theme.onPrimary.withOpacity(0.1), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.primary,
                border: Border.all(
                  color: theme.onPrimary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    data['image_base64'] != null
                        ? Image.memory(
                          base64Decode(data['image_base64']),
                          fit: BoxFit.cover,
                        )
                        : Icon(
                          isIncoming ? Icons.shopping_bag : Icons.shopping_cart,
                          color: secondaryColor,
                          size: 24,
                        ),
              ),
            ),
            SizedBox(width: 16),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    data['nama_produk'] ?? 'Produk',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.onPrimary,
                      fontFamily: 'playpen',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),

                  // Transaction Details
                  _buildDetailRow(
                    icon: Icons.person,
                    label: isIncoming ? 'Pembeli' : 'Penjual',
                    value:
                        isIncoming
                            ? (data['nama_pembeli'] ?? '-')
                            : (data['penjual'] ?? '-'),
                  ),
                  SizedBox(height: 4),

                  _buildDetailRow(
                    icon: Icons.calendar_today,
                    label: 'Tanggal',
                    value: _formatDate(data['tanggal']),
                  ),
                  SizedBox(height: 8),

                  // Status and Price Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            data['status'],
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(data['status']),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          data['status']?.toUpperCase() ?? 'UNKNOWN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(data['status']),
                            fontFamily: 'playpen',
                          ),
                        ),
                      ),
                      Text(
                        _formatCurrency(data['harga']),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: secondaryColor,
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
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.onPrimary.withOpacity(0.6)),
        SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: theme.onPrimary.withOpacity(0.6),
            fontFamily: 'playpen',
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: theme.onPrimary,
              fontWeight: FontWeight.w500,
              fontFamily: 'playpen',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    final theme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.onPrimary.withOpacity(0.1),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, size: 48, color: secondaryColor.withOpacity(0.6)),
          ),
          SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: theme.onPrimary.withOpacity(0.6),
              fontWeight: FontWeight.w500,
              fontFamily: 'playpen',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.primary,
        appBar: AppBar(
          title: Text(
            'History Pesanan',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'playpen',
            ),
          ),
          backgroundColor: secondaryColor,
          elevation: 0,
          iconTheme: IconThemeData(color: theme.primary),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white, // warna teks tab aktif
            unselectedLabelColor:
                Colors
                    .white70, // warna teks tab tidak aktif, pakai white70 biar lebih soft
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'playpen',
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              fontFamily: 'playpen',
            ),
            tabs: [
              Tab(
                icon: Icon(
                  Icons.inbox,
                  size: 20,
                  color: Colors.white,
                ), // ganti warna icon aktif & tidak aktif jadi putih
                text: 'Pesanan Masuk',
              ),
              Tab(
                icon: Icon(Icons.outbox, size: 20, color: Colors.white),
                text: 'Pesanan Keluar',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab Pesanan Masuk
            StreamBuilder<QuerySnapshot>(
              stream: getTransaksiMasuk(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: secondaryColor,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Terjadi kesalahan',
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.onPrimary,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'playpen',
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.onPrimary.withOpacity(0.6),
                            fontFamily: 'playpen',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            secondaryColor,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Memuat pesanan masuk...',
                          style: TextStyle(
                            color: theme.onPrimary.withOpacity(0.6),
                            fontFamily: 'playpen',
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return _buildEmptyState(
                    'Tidak ada pesanan masuk.',
                    Icons.inbox,
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildTransactionCard(data, true);
                  },
                );
              },
            ),

            // Tab Pesanan Keluar
            StreamBuilder<QuerySnapshot>(
              stream: getTransaksiKeluar(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: secondaryColor,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Terjadi kesalahan',
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.onPrimary,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'playpen',
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.onPrimary.withOpacity(0.6),
                            fontFamily: 'playpen',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            secondaryColor,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Memuat pesanan keluar...',
                          style: TextStyle(
                            color: theme.onPrimary.withOpacity(0.6),
                            fontFamily: 'playpen',
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return _buildEmptyState(
                    'Tidak ada pesanan keluar.',
                    Icons.outbox,
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildTransactionCard(data, false);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
