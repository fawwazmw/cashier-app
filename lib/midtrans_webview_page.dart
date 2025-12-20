import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/api_config.dart';

class MidtransWebViewPage extends StatefulWidget {
  final String snapUrl;
  final String transactionId;

  const MidtransWebViewPage({
    super.key,
    required this.snapUrl,
    required this.transactionId,
  });

  @override
  State<MidtransWebViewPage> createState() => _MidtransWebViewPageState();
}

class _MidtransWebViewPageState extends State<MidtransWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _statusCheckTimer;
  int _pollCount = 0;
  final int _maxPolls = 60; // Max 3 minutes (60 * 3 seconds)

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    // Start polling status after 10 seconds (give user time to start payment)
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _startStatusPolling();
      }
    });
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  // Start polling transaction status from backend
  void _startStatusPolling() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      _pollCount++;
      
      if (_pollCount >= _maxPolls) {
        timer.cancel();
        return;
      }

      final status = await _checkTransactionStatus();
      
      if (status != null) {
        print('🔄 Polling result: $status');
        
        if (status == 'paid') {
          timer.cancel();
          if (mounted) {
            Navigator.pop(context, 'success');
          }
        } else if (status == 'cancelled') {
          timer.cancel();
          if (mounted) {
            Navigator.pop(context, 'failed');
          }
        }
      }
    });
  }

  // Check transaction status from backend
  Future<String?> _checkTransactionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token');
      
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/payment/status/${widget.transactionId}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['status'] as String?;
        }
      }
    } catch (e) {
      // Silently fail, will retry on next poll
      print('⚠️ Status check error: $e');
    }
    return null;
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onPageStarted: (String url) {
            print('📄 Page started loading: $url');
            setState(() {
              _isLoading = true;
            });
            
            // Check URL immediately on page start (for redirects)
            _checkPaymentStatusInUrl(url);
          },
          onPageFinished: (String url) {
            print('✅ Page finished loading: $url');
            setState(() {
              _isLoading = false;
            });
            
            // Check if payment is finished
            _checkPaymentStatusInUrl(url);
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ Web resource error: ${error.description}');
            setState(() {
              _errorMessage = error.description;
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            print('🔗 Navigation request: $url');
            
            // Check for backend payment callbacks
            if (url.contains('/payment/finish') || url.contains('finish')) {
              print('✅ Payment finish detected in navigation');
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  Navigator.pop(context, 'success');
                }
              });
              return NavigationDecision.prevent;
            } else if (url.contains('/payment/error') || url.contains('error')) {
              print('❌ Payment error detected in navigation');
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  Navigator.pop(context, 'failed');
                }
              });
              return NavigationDecision.prevent;
            } else if (url.contains('/payment/pending')) {
              print('⏳ Payment pending detected in navigation');
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  Navigator.pop(context, 'pending');
                }
              });
              return NavigationDecision.prevent;
            }
            
            // Check Midtrans status parameters in URL
            if (url.contains('transaction_status=settlement') ||
                url.contains('status_code=200') ||
                url.contains('&order_id=') && url.contains('status_code')) {
              print('✅ Payment settlement detected in navigation');
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  Navigator.pop(context, 'success');
                }
              });
              return NavigationDecision.prevent;
            } else if (url.contains('transaction_status=pending')) {
              print('⏳ Payment pending in navigation URL');
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  Navigator.pop(context, 'pending');
                }
              });
              return NavigationDecision.prevent;
            } else if (url.contains('transaction_status=deny') ||
                       url.contains('transaction_status=expire') ||
                       url.contains('transaction_status=cancel')) {
              print('❌ Payment failed in navigation URL');
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  Navigator.pop(context, 'failed');
                }
              });
              return NavigationDecision.prevent;
            }
            
            // Allow navigation for normal pages
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.snapUrl));
  }

  void _checkPaymentStatusInUrl(String url) {
    // Check if URL indicates payment completion
    print('🔍 Checking URL on page load: $url');
    
    // Check for success indicators
    if (url.contains('status_code=200') || 
        url.contains('transaction_status=settlement') ||
        url.contains('transaction_status=capture')) {
      print('✅ Payment success detected in page URL!');
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          Navigator.pop(context, 'success');
        }
      });
    } 
    // Check for pending
    else if (url.contains('transaction_status=pending')) {
      print('⏳ Payment pending detected in page URL');
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          Navigator.pop(context, 'pending');
        }
      });
    }
    // Check for failure
    else if (url.contains('transaction_status=deny') ||
             url.contains('transaction_status=expire') ||
             url.contains('transaction_status=cancel') ||
             url.contains('transaction_status=failure')) {
      print('❌ Payment failed detected in page URL');
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          Navigator.pop(context, 'failed');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran Midtrans'),
        backgroundColor: Colors.blue.shade600,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _showExitConfirmation();
          },
        ),
        actions: [
          // Manual status check button
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: 'Cek Status Pembayaran',
            onPressed: () => _manualStatusCheck(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat Ulang',
            onPressed: () {
              _controller.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // WebView
          WebViewWidget(controller: _controller),
          
          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Memuat halaman pembayaran...',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          
          // Error message
          if (_errorMessage != null && !_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        'Gagal memuat halaman pembayaran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                          });
                          _controller.reload();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Manual status check
  Future<void> _manualStatusCheck() async {
    print('🔍 Manual status check initiated');
    
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Mengecek status pembayaran...'),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final status = await _checkTransactionStatus();
    
    if (!mounted) return;
    
    if (status == 'paid') {
      print('✅ Manual check: Payment SUCCESS!');
      _statusCheckTimer?.cancel();
      Navigator.pop(context, 'success');
    } else if (status == 'cancelled') {
      print('❌ Manual check: Payment FAILED!');
      _statusCheckTimer?.cancel();
      Navigator.pop(context, 'failed');
    } else if (status == 'pending') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('💳 Pembayaran masih pending. Silakan selesaikan pembayaran Anda.'),
          backgroundColor: Colors.orange.shade600,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gagal mengecek status. Coba lagi.'),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pembayaran?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apakah Anda yakin ingin membatalkan proses pembayaran?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tip: Jika sudah bayar, klik ikon ✓ di atas untuk cek status pembayaran',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () {
              _statusCheckTimer?.cancel();
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, 'cancelled'); // Close webview
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }
}
