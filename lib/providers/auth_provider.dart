import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isKasir => _user?.isKasir ?? false;

  // Auto login when app starts
  Future<void> autoLogin() async {
    _setLoading(true);
    try {
      final success = await AuthService.autoLogin();
      if (success) {
        _user = AuthService.currentUser;
      }
    } catch (e) {
      _setError('Auto login failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Login user
  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await AuthService.login(username, password);
      
      if (result['success']) {
        _user = result['user'];
        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Login failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register new user
  Future<bool> register({
    required String username,
    required String password,
    required String nama,
    required String role,
    String? email,
    String? phone,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await AuthService.register(
        username: username,
        password: password,
        nama: nama,
        role: role,
        email: email,
        phone: phone,
      );
      
      if (result['success']) {
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Registration failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout user
  Future<void> logout() async {
    _setLoading(true);
    try {
      await AuthService.logout();
      _user = null;
      notifyListeners();
    } catch (e) {
      _setError('Logout failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Check permission
  bool hasPermission(String action) {
    return AuthService.hasPermission(action);
  }

  // Update user data
  Future<bool> updateUser({
    required String nama,
    String? email,
    String? phone,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await ApiService.updateProfile(
        nama: nama,
        email: email,
        phone: phone,
      );

      if (result['success']) {
        _user = result['user'] as User;
        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to update profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}