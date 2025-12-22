import 'package:flutter/foundation.dart';
import '../models/business.dart';
import '../services/api_service.dart';

class BusinessProvider with ChangeNotifier {
  Business? _business;
  bool _isLoading = false;
  String? _errorMessage;

  Business? get business => _business;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch business info
  Future<void> fetchBusiness() async {
    _setLoading(true);
    _clearError();

    try {
      _business = await ApiService.getBusiness();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load business info: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update business info
  Future<bool> updateBusiness({
    required String namaUsaha,
    required String pemilik,
    required String alamat,
    required String telepon,
    String? email,
    String? deskripsi,
    String? kategori,
    String? logo,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final businessData = {
        'nama_usaha': namaUsaha,
        'pemilik': pemilik,
        'alamat': alamat,
        'telepon': telepon,
        'email': email,
        'deskripsi': deskripsi,
        'kategori': kategori ?? 'Retail',
        'logo': logo,
      };

      final result = await ApiService.updateBusiness(businessData);
      
      if (result['success']) {
        _business = result['business'] as Business;
        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to update business: $e');
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
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}
