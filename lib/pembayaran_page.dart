import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'providers/transaction_provider.dart';
import 'services/payment_service.dart';
import 'models/transaction.dart';
import 'midtrans_webview_page.dart';

class PembayaranPage extends StatefulWidget {
  const PembayaranPage({super.key});

  @override
  State<PembayaranPage> createState() => _PembayaranPageState();
}

class _PembayaranPageState extends State<PembayaranPage> {
  bool _isProcessing = false;
  Transaction? _transaction;
  String? _customerName;
  String? _customerPhone;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get arguments passed from kasir page
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      _transaction = arguments['transaction'] as Transaction?;
      _customerName = arguments['customerName'] as String?;
      _customerPhone = arguments['customerPhone'] as String?;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
    
    if (_transaction == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Pembayaran")),
        body: const Center(
          child: Text('Data transaksi tidak ditemukan'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pembayaran"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Detail Transaksi
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Detail Transaksi",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildDetailRow("ID Transaksi", _transaction!.id),
                    _buildDetailRow("Total", formatter.format(_transaction!.total)),
                    if (_customerName != null && _customerName!.isNotEmpty)
                      _buildDetailRow("Customer", _customerName!),
                    if (_customerPhone != null && _customerPhone!.isNotEmpty)
                      _buildDetailRow("No. HP", _customerPhone!),
                    _buildDetailRow("Status", _getStatusText(_transaction!.status)),
                    
                    const SizedBox(height: 12),
                    const Text(
                      "Item Transaksi:",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    
                    ..._transaction!.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "${item.productName} (${item.qty}x)",
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            formatter.format(item.subtotal),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Payment Status
            if (_transaction!.status == 'pending')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.pending, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Transaksi menunggu pembayaran",
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              )
            else if (_transaction!.status == 'paid')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Pembayaran sudah berhasil",
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Payment Methods
            if (_transaction!.status == 'pending') ...[
              const Text(
                "Metode Pembayaran",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // MIDTRANS Payment Button
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : () => _processMidtransPayment(),
                icon: _isProcessing 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.credit_card),
                label: Text(_isProcessing ? "Memproses..." : "Bayar dengan MIDTRANS"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Manual Payment Verification (for admin)
              Consumer<TransactionProvider>(
                builder: (context, transactionProvider, child) {
                  return ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _markAsPaid(transactionProvider),
                    icon: const Icon(Icons.verified),
                    label: const Text("Tandai Sudah Dibayar (Manual)"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  );
                },
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Payment Status Check
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : () => _checkPaymentStatus(),
                    icon: const Icon(Icons.refresh),
                    label: const Text("Cek Status Pembayaran"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : () => _cancelTransaction(),
                    icon: const Icon(Icons.cancel),
                    label: const Text("Batalkan Transaksi"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Info about MIDTRANS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        "Tentang MIDTRANS",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    "• Mendukung kartu kredit/debit\n"
                    "• Transfer bank (BCA, BNI, BRI, Mandiri)\n"
                    "• E-wallet (GoPay, OVO, Dana)\n"
                    "• Virtual Account\n"
                    "• Convenience Store (Indomaret, Alfamart)",
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const Text(": "),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Berhasil';
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Future<void> _processMidtransPayment() async {
    if (_transaction == null) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      print('💳 Starting Midtrans Snap payment...');
      
      // Get Snap URL using PaymentService
      final result = await PaymentService.getSnapUrl(
        transaction: _transaction!,
        customerName: _customerName ?? 'Customer',
        customerEmail: 'customer@griyopos.com',
        customerPhone: _customerPhone ?? '081234567890',
      );

      if (result['success'] && result['redirect_url'] != null) {
        final snapUrl = result['redirect_url'] as String;
        print('✅ Got Snap URL, opening WebView...');
        
        // Open WebView with Snap URL
        final paymentResult = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => MidtransWebViewPage(
              snapUrl: snapUrl,
              transactionId: _transaction!.id,
            ),
          ),
        );
        
        // Handle payment result
        if (paymentResult == 'success') {
          await _updateTransactionStatus('paid');
          _showPaymentSuccess();
        } else if (paymentResult == 'pending') {
          _showPaymentPending();
        } else if (paymentResult == 'cancelled') {
          _showPaymentError('Pembayaran dibatalkan');
        } else {
          _showPaymentError('Pembayaran gagal atau tidak selesai');
        }
      } else {
        // Failed to get Snap URL
        final errorMsg = result['message'] ?? 'Gagal mendapatkan URL pembayaran';
        print('❌ Failed to get Snap URL: $errorMsg');
        _showPaymentError(errorMsg);
      }
    } catch (e) {
      print('❌ Midtrans payment error: $e');
      _showPaymentError('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (_transaction == null) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await PaymentService.checkPaymentStatus(_transaction!.id);
      
      if (result['success']) {
        final status = result['status'];
        await _updateTransactionStatus(status);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status pembayaran: ${_getStatusText(status)}'),
            backgroundColor: status == 'paid' ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _showPaymentError(result['message'] ?? 'Failed to check payment status');
      }
    } catch (e) {
      _showPaymentError('Error checking status: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _markAsPaid(TransactionProvider transactionProvider) async {
    if (_transaction == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Pembayaran'),
        content: const Text('Apakah Anda yakin transaksi ini sudah dibayar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Sudah Dibayar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isProcessing = true;
      });

      final success = await transactionProvider.updateTransactionStatus(_transaction!.id, 'paid');
      
      if (success) {
        setState(() {
          _transaction = _transaction!.copyWith(status: 'paid') as Transaction;
        });
        _showPaymentSuccess();
      } else {
        _showPaymentError(transactionProvider.errorMessage ?? 'Failed to update status');
      }

      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _cancelTransaction() async {
    if (_transaction == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Transaksi'),
        content: const Text('Apakah Anda yakin ingin membatalkan transaksi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isProcessing = true;
      });

      final transactionProvider = context.read<TransactionProvider>();
      final success = await transactionProvider.updateTransactionStatus(_transaction!.id, 'cancelled');
      
      if (success) {
        Navigator.pop(context, false); // Return to kasir page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi berhasil dibatalkan'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _showPaymentError(transactionProvider.errorMessage ?? 'Failed to cancel transaction');
      }

      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _updateTransactionStatus(String status) async {
    if (!mounted) return;
    
    final transactionProvider = context.read<TransactionProvider>();
    await transactionProvider.updateTransactionStatus(_transaction!.id, status);
    
    if (mounted) {
      setState(() {
        _transaction = _transaction!.copyWith(status: status) as Transaction;
      });
    }
  }

  void _showPaymentSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text("Pembayaran Berhasil"),
          ],
        ),
        content: const Text("Transaksi telah berhasil diproses!"),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Return to kasir page with success
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showPaymentPending() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.pending, color: Colors.orange),
            SizedBox(width: 8),
            Text("Pembayaran Pending"),
          ],
        ),
        content: const Text("Pembayaran sedang diproses. Silakan cek status secara berkala."),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showPaymentError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text("Pembayaran Gagal"),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}