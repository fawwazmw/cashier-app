import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get all products
  Future<void> fetchProducts() async {
    _setLoading(true);
    _clearError();

    try {
      _products = await ApiService.getProducts();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load products: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add new product
  Future<bool> addProduct({
    required String nama,
    required double harga,
    required int stok,
    required String kategori,
    String? deskripsi,
    String? gambar,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final productData = {
        'nama': nama,
        'harga': harga,
        'stok': stok,
        'kategori': kategori,
        'deskripsi': deskripsi,
        'gambar': gambar,
      };

      final result = await ApiService.createProduct(productData);
      
      if (result['success']) {
        final newProduct = result['product'] as Product;
        _products.add(newProduct);
        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to add product: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update product
  Future<bool> updateProduct({
    required String id,
    required String nama,
    required double harga,
    required int stok,
    required String kategori,
    String? deskripsi,
    String? gambar,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final productData = {
        'nama': nama,
        'harga': harga,
        'stok': stok,
        'kategori': kategori,
        'deskripsi': deskripsi,
        'gambar': gambar,
      };

      final result = await ApiService.updateProduct(id, productData);
      
      if (result['success']) {
        final updatedProduct = result['product'] as Product;
        final index = _products.indexWhere((p) => p.id == id);
        if (index != -1) {
          _products[index] = updatedProduct;
          notifyListeners();
        }
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to update product: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete product
  Future<bool> deleteProduct(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await ApiService.deleteProduct(id);
      
      if (result['success']) {
        _products.removeWhere((p) => p.id == id);
        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to delete product: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Search products
  List<Product> searchProducts(String query) {
    if (query.isEmpty) return _products;
    
    return _products.where((product) {
      return product.nama.toLowerCase().contains(query.toLowerCase()) ||
             product.kategori.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Get products by category
  List<Product> getProductsByCategory(String kategori) {
    return _products.where((product) => product.kategori == kategori).toList();
  }

  // Get product by ID
  Product? getProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get low stock products
  List<Product> getLowStockProducts({int threshold = 10}) {
    return _products.where((product) => product.stok <= threshold).toList();
  }

  // Get categories
  List<String> getCategories() {
    return _products.map((product) => product.kategori).toSet().toList()..sort();
  }

  // Update product stock
  Future<bool> updateProductStock(String id, int newStock) async {
    try {
      final product = getProductById(id);
      if (product == null) return false;

      return await updateProduct(
        id: id,
        nama: product.nama,
        harga: product.harga,
        stok: newStock,
        kategori: product.kategori,
        deskripsi: product.deskripsi,
        gambar: product.gambar,
      );
    } catch (e) {
      _setError('Failed to update stock: $e');
      return false;
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