import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'providers/auth_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/product_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();

    // Load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
      context.read<TransactionProvider>().fetchTransactions();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Gradient
                  _buildHeader(),
                  
                  // Stats Cards
                  _buildStatsSection(),
                  
                  // Quick Actions
                  _buildQuickActions(),
                  
                  // Recent Transactions
                  _buildRecentTransactions(),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade600, Colors.blue.shade400],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final now = DateTime.now();
            final hour = now.hour;
            String greeting = 'Selamat Pagi';
            if (hour >= 12 && hour < 15) {
              greeting = 'Selamat Siang';
            } else if (hour >= 15 && hour < 18) {
              greeting = 'Selamat Sore';
            } else if (hour >= 18) {
              greeting = 'Selamat Malam';
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "LAUNDRY ",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                          TextSpan(
                            text: "POS",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4CAF50),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fitur notifikasi akan segera hadir'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  authProvider.user?.nama ?? 'User',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    authProvider.user?.isAdmin == true ? 'Administrator' : 'Kasir',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, child) {
          final todayTransactions = transactionProvider.transactions.where((t) {
            final today = DateTime.now();
            final txDate = t.createdAt;
            return txDate.year == today.year &&
                   txDate.month == today.month &&
                   txDate.day == today.day &&
                   t.status == 'paid';
          }).toList();

          final todayTotal = todayTransactions.fold<double>(
            0,
            (sum, t) => sum + t.total,
          );

          final todayCount = todayTransactions.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ringkasan Hari Ini',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.now()),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.trending_up,
                      title: 'Total Penjualan',
                      value: formatter.format(todayTotal),
                      color: Colors.green,
                      gradient: [Colors.green.shade400, Colors.green.shade600],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.receipt_long,
                      title: 'Transaksi',
                      value: '$todayCount',
                      color: Colors.blue,
                      gradient: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  final lowStockProducts = productProvider.products
                      .where((p) => p.stok < 10)
                      .length;
                  
                  final totalProducts = productProvider.products.length;

                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.inventory_2,
                          title: 'Total Layanan',
                          value: '$totalProducts',
                          color: Colors.purple,
                          gradient: [Colors.purple.shade400, Colors.purple.shade600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.warning_amber,
                          title: 'Stok Rendah',
                          value: '$lowStockProducts',
                          color: Colors.orange,
                          gradient: [Colors.orange.shade400, Colors.orange.shade600],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isAdmin = authProvider.user?.role == 'admin';
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Aksi Cepat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.point_of_sale,
                      label: 'Kasir',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pushNamed(context, '/kasir');
                      },
                    ),
                  ),
                  // Produk hanya untuk admin
                  if (isAdmin) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.inventory,
                        label: 'Layanan',
                        color: Colors.purple,
                        onTap: () {
                          Navigator.pushNamed(context, '/kelola-produk');
                        },
                      ),
                    ),
                  ],
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.receipt_long,
                      label: 'Riwayat',
                      color: Colors.orange,
                      onTap: () {
                        // Navigate to Riwayat tab in MainNavigationPage
                        Navigator.pushReplacementNamed(context, '/riwayat');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transaksi Terbaru',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/riwayat');
                },
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Consumer<TransactionProvider>(
            builder: (context, transactionProvider, child) {
              if (transactionProvider.isLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final recentTransactions = transactionProvider.transactions
                  .take(5)
                  .toList();

              if (recentTransactions.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada transaksi',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: recentTransactions.map((transaction) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: transaction.status == 'paid'
                                ? Colors.green.shade50
                                : transaction.status == 'pending'
                                    ? Colors.orange.shade50
                                    : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            transaction.status == 'paid'
                                ? Icons.check_circle
                                : transaction.status == 'pending'
                                    ? Icons.access_time
                                    : Icons.cancel,
                            color: transaction.status == 'paid'
                                ? Colors.green
                                : transaction.status == 'pending'
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction.id,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd MMM yyyy, HH:mm').format(transaction.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatter.format(transaction.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: transaction.status == 'paid'
                                    ? Colors.green.shade100
                                    : transaction.status == 'pending'
                                        ? Colors.orange.shade100
                                        : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                transaction.status == 'paid'
                                    ? 'Lunas'
                                    : transaction.status == 'pending'
                                        ? 'Pending'
                                        : 'Batal',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: transaction.status == 'paid'
                                      ? Colors.green.shade900
                                      : transaction.status == 'pending'
                                          ? Colors.orange.shade900
                                          : Colors.red.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _refreshData() async {
    await Future.wait([
      context.read<ProductProvider>().fetchProducts(),
      context.read<TransactionProvider>().fetchTransactions(),
    ]);
  }
}
