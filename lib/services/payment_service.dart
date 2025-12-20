import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/transaction.dart';

/// PaymentService - Handles Midtrans Snap payment integration
/// Uses WebView-based Snap method (no SDK required)
/// Based on: https://trongdth.medium.com/implement-midtrans-payment-gateway-in-flutter-by-using-snap-method-ac8545085989
class PaymentService {
  static String get _apiBase => ApiConfig.baseUrl;

  /// Get Snap payment URL from backend
  /// Returns a map containing success status, redirect_url, token, etc.
  static Future<Map<String, dynamic>> getSnapUrl({
    required Transaction transaction,
    required String customerName,
    String? customerEmail,
    String? customerPhone,
  }) async {
    try {
      final tokenResult = await _createTransactionToken(
        transaction: transaction,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
      );

      return tokenResult;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to get Snap URL: $e',
      };
    }
  }

  // Get auth token from SharedPreferences
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    // Try both keys for compatibility
    return prefs.getString('auth_token') ?? prefs.getString('token');
  }

  /// Create transaction token from backend
  /// Backend will communicate with Midtrans Snap API
  static Future<Map<String, dynamic>> _createTransactionToken({
    required Transaction transaction,
    required String customerName,
    String? customerEmail,
    String? customerPhone,
  }) async {
    try {
      final token = await _getAuthToken();
      
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Authentication required. Please login again.',
        };
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
      
      final requestData = {
        'transaction_id': transaction.id,
        'customer_details': {
          'first_name': customerName,
          'email': customerEmail ?? 'customer@griyopos.com',
          'phone': customerPhone ?? '08123456789',
        },
      };

      print('📤 Creating Snap token for: ${transaction.id}');
      
      final url = Uri.parse('$_apiBase/payment/create-token');
      final resp = await http.post(
        url, 
        headers: headers, 
        body: jsonEncode(requestData),
      );

      print('📡 Backend response: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['success'] == true && data['redirect_url'] != null) {
          return {
            'success': true,
            'token': data['token'],
            'redirect_url': data['redirect_url'],
            'transaction_id': data['transaction_id'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to create payment token',
          };
        }
      } else if (resp.statusCode == 401) {
        return {
          'success': false,
          'message': 'Unauthorized. Please login again.',
        };
      } else if (resp.statusCode == 404) {
        return {
          'success': false,
          'message': 'Transaction not found',
        };
      } else {
        final errorData = jsonDecode(resp.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to create payment token (HTTP ${resp.statusCode})',
        };
      }
      
    } catch (e) {
      print('❌ Error creating token: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Check payment status
  static Future<Map<String, dynamic>> checkPaymentStatus(String transactionId) async {
    try {
      final token = await _getAuthToken();
      final headers = {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final url = Uri.parse('$_apiBase/payment/status/$transactionId');
      final resp = await http.get(url, headers: headers);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return {
          'success': true,
          'status': data['status'] ?? 'pending',
          'payment_method': data['payment_method'],
          'transaction_id': data['transaction_id'] ?? transactionId,
          'midtrans_status': data['midtrans_status'],
        };
      } else if (resp.statusCode == 401) {
        return {
          'success': false,
          'message': 'Unauthorized. Please login again.',
        };
      } else if (resp.statusCode == 404) {
        return {
          'success': false,
          'message': 'Transaction not found',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to check payment status (HTTP ${resp.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to check payment status: $e',
      };
    }
  }

  // Handle payment notification (webhook) - untuk backend implementation
  static Map<String, dynamic> handlePaymentNotification(Map<String, dynamic> notification) {
    try {
      final transactionStatus = notification['transaction_status'];
      final orderId = notification['order_id'];
      
      return {
        'success': true,
        'order_id': orderId,
        'status': transactionStatus,
        'fraud_status': notification['fraud_status'],
        'payment_type': notification['payment_type'],
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Invalid notification format: $e',
      };
    }
  }
}

