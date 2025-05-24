import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetailTransactionScreen extends StatefulWidget {
  final String transactionId;
  final Map<String, dynamic> transactionData;

  const DetailTransactionScreen({
    Key? key,
    required this.transactionId,
    required this.transactionData,
  }) : super(key: key);

  @override
  State<DetailTransactionScreen> createState() =>
      _DetailTransactionScreenState();
}

class _DetailTransactionScreenState extends State<DetailTransactionScreen> {
  bool _isLoading = false;

  Future<void> _updateTransactionStatus(String newStatus) async {
    setState(() => _isLoading = true);
    final theme = Theme.of(context).colorScheme;

    try {
      final firestore = FirebaseFirestore.instance;
      final transaksiRef = firestore
          .collection('transaksi')
          .doc(widget.transactionId);

      await firestore.runTransaction((transaction) async {
        final transaksiSnapshot = await transaction.get(transaksiRef);
        if (!transaksiSnapshot.exists) {
          throw Exception("Transaksi tidak ditemukan");
        }

        final data = transaksiSnapshot.data()!;
        final produkId = data['id_produk'];
        final produkRef = firestore.collection('products').doc(produkId);
        final produkSnapshot = await transaction.get(produkRef);
        if (!produkSnapshot.exists) {
          throw Exception("Produk tidak ditemukan");
        }

        final produkData = produkSnapshot.data()!;
        final stokSaatIni = produkData['stock'] ?? 0;

        if (newStatus == 'diterima') {
          if (stokSaatIni <= 0) {
            throw Exception("Stok produk habis, tidak bisa menerima pesanan");
          }

          // Kurangi stock produk
          transaction.update(produkRef, {'stock': stokSaatIni - 1});
        }

        // Update status transaksi
        transaction.update(transaksiRef, {'status': newStatus});
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pesanan $newStatus!',
              style: const TextStyle(fontFamily: 'playpen'),
            ),
            backgroundColor: theme.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate status changed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal mengubah status: ${e.toString()}',
              style: const TextStyle(fontFamily: 'playpen'),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Tanggal tidak tersedia';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      date = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return 'Tanggal tidak valid';
    }

    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    final theme = Theme.of(context).colorScheme;
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'diterima':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      case 'selesai':
        return Colors.blue;
      default:
        return theme.tertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.transactionData;
    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: theme.primary,
      appBar: AppBar(
        title: Text(
          'Konfirmasi Pesanan',
          style: TextStyle(
            fontFamily: 'playpen',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: theme.tertiary,
          ),
        ),
        backgroundColor: theme.surface,
        foregroundColor: theme.tertiary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.onBackground),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.tertiary.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: theme.tertiary.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        data['status'] ?? 'pending',
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: _getStatusColor(data['status'] ?? 'pending'),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status Pesanan',
                          style: TextStyle(
                            fontFamily: 'playpen',
                            fontSize: 14,
                            color: theme.tertiary.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(data['status'] ?? 'pending'),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (data['status'] ?? 'pending').toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'playpen',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.surface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Product Information Card
            _buildInfoCard(
              title: 'Informasi Produk',
              icon: Icons.shopping_bag_outlined,
              children: [
                _buildInfoRow(
                  'Nama Produk',
                  data['nama_produk'] ?? 'Tidak tersedia',
                ),
                _buildInfoRow('Harga', 'Rp ${_formatCurrency(data['harga'])}'),
                _buildInfoRow('Jumlah', '${data['jumlah'] ?? 1} item'),
                _buildInfoRow(
                  'Total',
                  'Rp ${_formatCurrency((data['harga'] ?? 0) * (data['jumlah'] ?? 1))}',
                ),
                _buildInfoRow('Nama', data['nama_pembeli'] ?? 'Tidak tersedia'),
              ],
            ),

            const SizedBox(height: 16),

            // Transaction Details Card
            _buildInfoCard(
              title: 'Detail Transaksi',
              icon: Icons.receipt_outlined,
              children: [
                _buildInfoRow('ID Transaksi', widget.transactionId),
                _buildInfoRow('Tanggal Pesanan', _formatDate(data['tanggal'])),
                if (data['catatan'] != null &&
                    data['catatan'].toString().isNotEmpty)
                  _buildInfoRow('Catatan', data['catatan']),
                if (data['metode_pembayaran'] != null)
                  _buildInfoRow('Metode Pembayaran', data['metode_pembayaran']),
              ],
            ),

            const SizedBox(height: 32),

            // Action Buttons (only show if status is pending)
            if (data['status'] == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () => _updateTransactionStatus('ditolak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                'Tolak',
                                style: const TextStyle(
                                  fontFamily: 'playpen',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () => _updateTransactionStatus('diterima'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.secondary,
                        foregroundColor: theme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child:
                          _isLoading
                              ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.surface,
                                ),
                              )
                              : Text(
                                'Terima',
                                style: const TextStyle(
                                  fontFamily: 'playpen',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.tertiary.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: theme.tertiary.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: theme.secondary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'playpen',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'playpen',
                fontSize: 14,
                color: theme.tertiary.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(
              fontFamily: 'playpen',
              fontSize: 14,
              color: theme.tertiary.withOpacity(0.6),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'playpen',
                fontSize: 14,
                color: theme.tertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
