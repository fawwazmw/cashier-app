class Transaction {
  final String id;
  final String userId;
  final double total;
  final String status; // 'pending', 'paid', 'cancelled'
  final String paymentMethod; // 'cash', 'midtrans'
  final String? paymentToken;
  final String? customerName;
  final String? customerPhone;
  final DateTime createdAt;
  final List<TransactionItem> items;

  Transaction({
    required this.id,
    required this.userId,
    required this.total,
    required this.status,
    required this.paymentMethod,
    this.paymentToken,
    this.customerName,
    this.customerPhone,
    required this.createdAt,
    required this.items,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      total: double.parse(json['total'].toString()),
      status: json['status'],
      paymentMethod: json['payment_method'],
      paymentToken: json['payment_token'],
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      createdAt: DateTime.parse(json['created_at']),
      items: (json['items'] as List? ?? [])
          .map((item) => TransactionItem.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'total': total,
      'status': status,
      'payment_method': paymentMethod,
      'payment_token': paymentToken,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'created_at': createdAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  Transaction copyWith({
    String? id,
    String? userId,
    double? total,
    String? status,
    String? paymentMethod,
    String? paymentToken,
    String? customerName,
    String? customerPhone,
    DateTime? createdAt,
    List<TransactionItem>? items,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentToken: paymentToken ?? this.paymentToken,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}

class TransactionItem {
  final String id;
  final String transactionId;
  final String productId;
  final String productName;
  final int qty;
  final double harga;
  final double subtotal;

  TransactionItem({
    required this.id,
    required this.transactionId,
    required this.productId,
    required this.productName,
    required this.qty,
    required this.harga,
    required this.subtotal,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'].toString(),
      transactionId: json['transaction_id'].toString(),
      productId: json['product_id'].toString(),
      productName: json['product_name'],
      qty: int.parse(json['qty'].toString()),
      harga: double.parse(json['harga'].toString()),
      subtotal: double.parse(json['subtotal'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'product_id': productId,
      'product_name': productName,
      'qty': qty,
      'harga': harga,
      'subtotal': subtotal,
    };
  }
}

class CartItem {
  final String productId;
  final String productName;
  final double harga;
  int qty;
  
  CartItem({
    required this.productId,
    required this.productName,
    required this.harga,
    this.qty = 1,
  });

  double get subtotal => harga * qty;
}