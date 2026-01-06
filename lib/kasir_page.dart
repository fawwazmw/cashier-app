import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/transaction_provider.dart';
import 'models/product.dart';
import 'utils/snackbar_utils.dart';

class KasirPage extends StatefulWidget {
  const KasirPage({super.key});

  @override
  State<KasirPage> createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  String _selectedCategory = 'Semua';
  List<Product> _filteredProducts = [];
  bool _showCartSheet = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  void _loadProducts() {
    final productProvider = context.read<ProductProvider>();
    productProvider.fetchProducts();
  }

  void _filterProducts(List<Product> products) {
    String query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredProducts = products.where((product) {
        bool matchesSearch = product.nama.toLowerCase().contains(query);
        bool matchesCategory = _selectedCategory == 'Semua' || 
                              product.kategori == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Main Content - Products
          Column(
            children: [
              // Search and Filter
              _buildSearchAndFilter(),
              
              // Products Grid
              Expanded(
                child: _buildProductsGrid(formatter),
              ),
            ],
          ),
          
          // Cart Summary Bar at Bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildCartSummaryBar(formatter),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Kasir Laundry'),
      elevation: 0,
      backgroundColor: Colors.blue.shade600,
      actions: [
        Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    authProvider.user?.nama ?? 'User',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari layanan...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (value) {
              final products = context.read<ProductProvider>().products;
              _filterProducts(products);
            },
          ),
          const SizedBox(height: 12),
          
          // Category Filter
          Consumer<ProductProvider>(
            builder: (context, productProvider, child) {
              final categories = ['Semua', ...productProvider.getCategories()];
              return SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                          _filterProducts(productProvider.products);
                        },
                        backgroundColor: Colors.white,
                        selectedColor: Colors.blue.shade100,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected ? Colors.blue.shade400 : Colors.grey.shade300,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(NumberFormat formatter) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (productProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (productProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text('Error: ${productProvider.errorMessage}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadProducts,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        final products = _filteredProducts.isEmpty && _searchController.text.isEmpty
            ? productProvider.products
            : _filteredProducts;

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('Tidak ada layanan ditemukan'),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16).copyWith(bottom: 160), // Space for cart bar + bottom nav
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildProductCard(product, formatter);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Product product, NumberFormat formatter) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (product.stok > 0) {
            context.read<TransactionProvider>().addToCart(product);
            SnackbarUtils.showSuccess(context, '${product.nama} ditambahkan');
          } else {
            SnackbarUtils.showWarning(context, 'Stok habis');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: product.gambar != null
                          ? Image.network(
                              product.gambar!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.image_not_supported, size: 40, color: Colors.grey.shade400);
                              },
                            )
                          : Icon(Icons.inventory_2, size: 40, color: Colors.grey.shade400),
                    ),
                    if (product.stok == 0)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          ),
                          child: const Center(
                            child: Text(
                              'HABIS',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.nama,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatter.format(product.harga),
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2,
                              size: 12,
                              color: product.stok > 0 ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Stok: ${product.stok}',
                              style: TextStyle(
                                fontSize: 11,
                                color: product.stok > 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummaryBar(NumberFormat formatter) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        final cartItems = transactionProvider.cartItems;
        final total = transactionProvider.cartTotal;
        final itemCount = cartItems.fold<int>(0, (sum, item) => sum + item.qty);

        if (cartItems.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Cart Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$itemCount Item',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatter.format(total),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // View Cart Button
                  ElevatedButton.icon(
                    onPressed: () {
                      _showCartBottomSheet(context, formatter);
                    },
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Lihat Keranjang'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCartBottomSheet(BuildContext context, NumberFormat formatter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Keranjang Belanja',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Consumer<TransactionProvider>(
                        builder: (context, transactionProvider, child) {
                          if (transactionProvider.cartItems.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return TextButton.icon(
                            onPressed: () {
                              transactionProvider.clearCart();
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Hapus Semua'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),
                
                // Cart Items
                Expanded(
                  child: Consumer<TransactionProvider>(
                    builder: (context, transactionProvider, child) {
                      final cartItems = transactionProvider.cartItems;
                      
                      if (cartItems.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                'Keranjang kosong',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          return _buildCartItem(item, formatter, transactionProvider);
                        },
                      );
                    },
                  ),
                ),
                
                // Checkout Section
                _buildCheckoutSection(formatter),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCartItem(dynamic item, NumberFormat formatter, TransactionProvider transactionProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  formatter.format(item.harga),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  transactionProvider.updateCartItemQty(item.productId, item.qty - 1);
                },
                icon: Icon(Icons.remove_circle_outline, color: Colors.blue.shade600),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  '${item.qty}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  transactionProvider.updateCartItemQty(item.productId, item.qty + 1);
                },
                icon: Icon(Icons.add_circle_outline, color: Colors.blue.shade600),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  transactionProvider.removeFromCart(item.productId);
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection(NumberFormat formatter) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        final total = transactionProvider.cartTotal;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Customer Info
                TextField(
                  controller: _customerNameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Customer (Opsional)',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _customerPhoneController,
                  decoration: InputDecoration(
                    labelText: 'No. HP (Opsional)',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                
                // Total
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Pembayaran:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        formatter.format(total),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Payment Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: transactionProvider.isLoading
                            ? null
                            : () => _processCheckout(context, transactionProvider, 'cash'),
                        icon: const Icon(Icons.money),
                        label: const Text('Tunai'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: transactionProvider.isLoading
                            ? null
                            : () => _processCheckout(context, transactionProvider, 'midtrans'),
                        icon: const Icon(Icons.credit_card),
                        label: const Text('E-Wallet'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _processCheckout(BuildContext context, TransactionProvider transactionProvider, String paymentMethod) async {
    if (transactionProvider.isLoading) return;

    final customerName = _customerNameController.text.trim();
    final customerPhone = _customerPhoneController.text.trim();

    if (paymentMethod == 'cash') {
      final transactionId = await transactionProvider.createTransaction(
        customerName: customerName.isEmpty ? null : customerName,
        customerPhone: customerPhone.isEmpty ? null : customerPhone,
        paymentMethod: 'cash',
      );

      if (transactionId != null && mounted) {
        await transactionProvider.updateTransactionStatus(transactionId, 'paid');
        
        _customerNameController.clear();
        _customerPhoneController.clear();
        
        Navigator.pop(context); // Close bottom sheet
        
        SnackbarUtils.showSuccess(context, 'Pembayaran tunai berhasil!');
      } else if (mounted) {
        SnackbarUtils.showError(context, transactionProvider.errorMessage ?? 'Gagal memproses transaksi');
      }
    } else {
      final transactionId = await transactionProvider.createTransaction(
        customerName: customerName.isEmpty ? null : customerName,
        customerPhone: customerPhone.isEmpty ? null : customerPhone,
        paymentMethod: 'midtrans',
      );

      if (transactionId != null && mounted) {
        final transaction = transactionProvider.getTransactionById(transactionId);
        if (transaction != null) {
          Navigator.pop(context); // Close bottom sheet
          Navigator.pushNamed(
            context,
            '/pembayaran',
            arguments: {
              'transaction': transaction,
              'customerName': customerName.isEmpty ? 'Customer' : customerName,
              'customerPhone': customerPhone,
            },
          ).then((result) {
            if (result == true) {
              _customerNameController.clear();
              _customerPhoneController.clear();
            }
          });
        }
      } else if (mounted) {
        SnackbarUtils.showError(context, transactionProvider.errorMessage ?? 'Gagal membuat transaksi');
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }
}
