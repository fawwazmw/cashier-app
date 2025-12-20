import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  List<CartItem> _cartItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Transaction> get transactions => _transactions;
  List<CartItem> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  double get cartTotal => _cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
  int get cartItemCount => _cartItems.fold(0, (sum, item) => sum + item.qty);

  // CART MANAGEMENT
  
  // Add item to cart
  void addToCart(Product product, {int qty = 1}) {
    final existingIndex = _cartItems.indexWhere((item) => item.productId == product.id);
    
    if (existingIndex != -1) {
      _cartItems[existingIndex].qty += qty;
    } else {
      _cartItems.add(CartItem(
        productId: product.id,
        productName: product.nama,
        harga: product.harga,
        qty: qty,
      ));
    }
    notifyListeners();
  }

  // Remove item from cart
  void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  // Update cart item quantity
  void updateCartItemQty(String productId, int qty) {
    if (qty <= 0) {
      removeFromCart(productId);
      return;
    }

    final index = _cartItems.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      _cartItems[index].qty = qty;
      notifyListeners();
    }
  }

  // Clear cart
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  // TRANSACTION MANAGEMENT

  // Fetch transactions
  Future<void> fetchTransactions({int? limit, String? status}) async {
    _setLoading(true);
    _clearError();

    try {
      _transactions = await ApiService.getTransactions(limit: limit, status: status);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load transactions: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create transaction from cart
  Future<String?> createTransaction({
    String? customerName,
    String? customerPhone,
    String paymentMethod = 'cash',
  }) async {
    if (_cartItems.isEmpty) {
      _setError('Cart is empty');
      return null;
    }

    _setLoading(true);
    _clearError();

    try {
      final user = AuthService.currentUser;
      if (user == null) {
        _setError('User not logged in');
        return null;
      }

      final transactionData = {
        'total': cartTotal,
        'payment_method': paymentMethod,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'items': _cartItems.map((item) => {
          'product_id': int.parse(item.productId.toString()), // Ensure integer
          'qty': item.qty,
        }).toList(),
      };

      final result = await ApiService.createTransaction(transactionData);
      
      if (result['success']) {
        final transaction = result['transaction'] as Transaction;
        _transactions.insert(0, transaction);
        clearCart();
        notifyListeners();
        return transaction.id;
      } else {
        _setError(result['message']);
        return null;
      }
    } catch (e) {
      _setError('Failed to create transaction: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Update transaction status
  Future<bool> updateTransactionStatus(String transactionId, String status) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await ApiService.updateTransactionStatus(transactionId, status);
      
      if (result['success']) {
        final updatedTransaction = result['transaction'] as Transaction;
        final index = _transactions.indexWhere((t) => t.id == transactionId);
        if (index != -1) {
          _transactions[index] = updatedTransaction;
          notifyListeners();
        }
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to update transaction: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get transaction by ID
  Transaction? getTransactionById(String id) {
    try {
      return _transactions.firstWhere((transaction) => transaction.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get transactions by status
  List<Transaction> getTransactionsByStatus(String status) {
    return _transactions.where((transaction) => transaction.status == status).toList();
  }

  // Get today's transactions
  List<Transaction> getTodayTransactions() {
    final today = DateTime.now();
    return _transactions.where((transaction) {
      return transaction.createdAt.year == today.year &&
             transaction.createdAt.month == today.month &&
             transaction.createdAt.day == today.day;
    }).toList();
  }

  // Get sales summary
  Map<String, dynamic> getSalesSummary({DateTime? date}) {
    final targetDate = date ?? DateTime.now();
    final targetTransactions = _transactions.where((transaction) {
      return transaction.createdAt.year == targetDate.year &&
             transaction.createdAt.month == targetDate.month &&
             transaction.createdAt.day == targetDate.day &&
             transaction.status == 'paid';
    }).toList();

    double totalSales = 0;
    int totalTransactions = targetTransactions.length;
    Map<String, int> productSales = {};

    for (final transaction in targetTransactions) {
      totalSales += transaction.total;
      
      for (final item in transaction.items) {
        productSales[item.productName] = 
            (productSales[item.productName] ?? 0) + item.qty;
      }
    }

    return {
      'total_sales': totalSales,
      'total_transactions': totalTransactions,
      'product_sales': productSales,
      'date': targetDate,
    };
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