import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/product.dart';
import '../models/transaction.dart';
import '../models/business.dart';
import '../config/api_config.dart';

class ApiService {
  // Menggunakan konfigurasi dari ApiConfig
  static String get baseUrl => ApiConfig.baseUrl;
  
  static String? _token;
  
  static void setToken(String token) {
    _token = token;
  }
  
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // AUTH ENDPOINTS
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        _token = data['token'];
        return {
          'success': true,
          'user': User.fromJson(data['user']),
          'token': data['token'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers,
        body: jsonEncode(userData),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // PRODUCT ENDPOINTS
  static Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map((product) => Product.fromJson(product))
            .toList();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> createProduct(Map<String, dynamic> productData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: _headers,
        body: jsonEncode(productData),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'product': Product.fromJson(data['product']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create product',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> productData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/products/$id'),
        headers: _headers,
        body: jsonEncode(productData),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'product': Product.fromJson(data['product']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update product',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> deleteProduct(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$id'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete product',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // TRANSACTION ENDPOINTS
  static Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> transactionData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: _headers,
        body: jsonEncode(transactionData),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'transaction': Transaction.fromJson(data['transaction']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create transaction',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  static Future<List<Transaction>> getTransactions({int? limit, String? status}) async {
    try {
      String url = '$baseUrl/transactions';
      Map<String, String> queryParams = {};
      
      if (limit != null) queryParams['limit'] = limit.toString();
      if (status != null) queryParams['status'] = status;
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map((transaction) => Transaction.fromJson(transaction))
            .toList();
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> updateTransactionStatus(String id, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/transactions/$id/status'),
        headers: _headers,
        body: jsonEncode({'status': status}),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'transaction': Transaction.fromJson(data['transaction']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update transaction',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // BUSINESS ENDPOINTS
  static Future<Business> getBusiness() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/business'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Business.fromJson(data['data']);
      } else {
        throw Exception('Failed to load business info');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> updateBusiness(Map<String, dynamic> businessData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/business'),
        headers: _headers,
        body: jsonEncode(businessData),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'business': Business.fromJson(data['business']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update business',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // USER PROFILE ENDPOINTS
  static Future<Map<String, dynamic>> updateProfile({
    required String nama,
    String? email,
    String? phone,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/auth/profile'),
        headers: _headers,
        body: jsonEncode({
          'nama': nama,
          'email': email,
          'phone': phone,
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'user': User.fromJson(data['user']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}