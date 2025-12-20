import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';
  
  static User? _currentUser;
  
  static User? get currentUser => _currentUser;
  
  static bool get isLoggedIn => _currentUser != null;
  
  static bool get isAdmin => _currentUser?.isAdmin ?? false;
  
  static bool get isKasir => _currentUser?.isKasir ?? false;

  // Login user
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final result = await ApiService.login(username, password);
      
      if (result['success']) {
        final user = result['user'] as User;
        final token = result['token'] as String;
        
        await _saveUserData(user, token);
        _currentUser = user;
        ApiService.setToken(token);
        
        return {
          'success': true,
          'user': user,
        };
      } else {
        return result;
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Login error: $e',
      };
    }
  }

  // Register new user (admin only)
  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String nama,
    required String role,
    String? email,
    String? phone,
  }) async {
    try {
      if (!isAdmin) {
        return {
          'success': false,
          'message': 'Only admin can register new users',
        };
      }

      final userData = {
        'username': username,
        'password': password,
        'nama': nama,
        'role': role,
        'email': email,
        'phone': phone,
      };

      return await ApiService.register(userData);
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration error: $e',
      };
    }
  }

  // Auto login from saved credentials
  static Future<bool> autoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);
      final token = prefs.getString(_tokenKey);
      
      if (userData != null && token != null) {
        final userMap = Map<String, dynamic>.from(
          Uri.splitQueryString(userData)
        );
        
        _currentUser = User.fromJson(userMap);
        ApiService.setToken(token);
        
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Logout user
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_tokenKey);
      
      _currentUser = null;
      ApiService.setToken('');
    } catch (e) {
      // Handle error silently
    }
  }

  // Check if user has permission for specific action
  static bool hasPermission(String action) {
    if (_currentUser == null) return false;
    
    switch (action) {
      case 'kasir':
        return true; // Both admin and kasir can access kasir
      case 'kelola_produk':
        return isAdmin; // Only admin can manage products
      case 'riwayat_read':
        return true; // Both can read transaction history
      case 'riwayat_write':
        return isAdmin; // Only admin can modify transactions
      case 'pengaturan':
        return isAdmin; // Only admin can access settings
      default:
        return false;
    }
  }

  // Save user data to local storage
  static Future<void> _saveUserData(User user, String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = user.toJson();
      
      // Convert to query string format for simple storage
      final userData = userJson.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      
      await prefs.setString(_userKey, userData);
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      throw Exception('Failed to save user data: $e');
    }
  }

  // Update current user data
  static Future<void> updateUserData(User updatedUser) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey) ?? '';
      
      await _saveUserData(updatedUser, token);
      _currentUser = updatedUser;
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }
}