import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'providers/transaction_provider.dart';
import 'providers/auth_provider.dart';
import 'models/transaction.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> with SingleTickerProviderStateMixin {
  String _selectedFilter = 'Semua';
  String _selectedPeriod = 'Hari Ini';
  final TextEditingController _searchController = TextEditingController();
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().fetchTransactions();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: Column(
            children: [
              // Filters Section
              _buildFiltersSection(),
              
              // Stats Summary
              _buildStatsSummary(),
              
              // Transactions List
              Expanded(
                child: _buildTransactionsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Riwayat Transaksi'),
      elevation: 0,
      backgroundColor: Colors.blue.shade600,
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterDialog,
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari ID transaksi atau customer...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
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
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          
          // Filter Chips
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Semua', Icons.list),
                      const SizedBox(width: 8),
                      _buildFilterChip('Lunas', Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pending', Icons.access_time, color: Colors.orange),
                      const SizedBox(width: 8),
                      _buildFilterChip('Batal', Icons.cancel, color: Colors.red),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, {Color? color}) {
    final isSelected = _selectedFilter == label;
    final chipColor = color ?? Colors.blue;
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? chipColor : Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: chipColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? chipColor : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? chipColor : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildStatsSummary() {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        final filteredTransactions = _getFilteredTransactions(transactionProvider.transactions);
        
        final totalRevenue = filteredTransactions
            .where((t) => t.status == 'paid')
            .fold<double>(0, (sum, t) => sum + t.total);
        
        final totalTransactions = filteredTransactions.length;
        
        final pendingCount = filteredTransactions
            .where((t) => t.status == 'pending')
            .length;

        final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total Pendapatan',
                      formatter.format(totalRevenue),
                      Icons.trending_up,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Transaksi',
                      '$totalTransactions',
                      Icons.receipt_long,
                    ),
                  ),
                ],
              ),
              if (pendingCount > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '$pendingCount transaksi menunggu pembayaran',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTransactionsList() {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        if (transactionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (transactionProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text('Error: ${transactionProvider.errorMessage}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshData,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        final transactions = _getFilteredTransactions(transactionProvider.transactions);

        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  _selectedFilter == 'Semua'
                      ? 'Belum ada transaksi'
                      : 'Tidak ada transaksi $_selectedFilter',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        // Group by date
        final groupedTransactions = _groupTransactionsByDate(transactions);

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: groupedTransactions.keys.length,
          itemBuilder: (context, index) {
            final date = groupedTransactions.keys.elementAt(index);
            final dayTransactions = groupedTransactions[date]!;
            
            return _buildDateGroup(date, dayTransactions);
          },
        );
      },
    );
  }

  Widget _buildDateGroup(String date, List<Transaction> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.grey.shade300,
                ),
              ),
            ],
          ),
        ),
        ...transactions.map((transaction) => _buildTransactionCard(transaction)).toList(),
      ],
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    
    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    
    switch (transaction.status) {
      case 'paid':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusLabel = 'Lunas';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        statusLabel = 'Pending';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusLabel = 'Batal';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusLabel = transaction.status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTransactionDetail(transaction),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Status Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    
                    // Transaction Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  transaction.id,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('HH:mm').format(transaction.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (transaction.customerName != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    transaction.customerName!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            transaction.paymentMethod == 'cash'
                                ? Icons.money
                                : Icons.credit_card,
                            size: 16,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            transaction.paymentMethod == 'cash' ? 'Tunai' : 'E-Wallet',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        formatter.format(transaction.total),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> transactions) {
    var filtered = transactions;

    // Filter by status
    if (_selectedFilter != 'Semua') {
      String status;
      switch (_selectedFilter) {
        case 'Lunas':
          status = 'paid';
          break;
        case 'Pending':
          status = 'pending';
          break;
        case 'Batal':
          status = 'cancelled';
          break;
        default:
          status = _selectedFilter.toLowerCase();
      }
      filtered = filtered.where((t) => t.status == status).toList();
    }

    // Filter by search
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((t) {
        return t.id.toLowerCase().contains(query) ||
               (t.customerName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }

  Map<String, List<Transaction>> _groupTransactionsByDate(List<Transaction> transactions) {
    final Map<String, List<Transaction>> grouped = {};
    final now = DateTime.now();
    
    for (var transaction in transactions) {
      final txDate = transaction.createdAt;
      String dateLabel;
      
      if (txDate.year == now.year && txDate.month == now.month && txDate.day == now.day) {
        dateLabel = 'Hari Ini';
      } else if (txDate.year == now.year && txDate.month == now.month && txDate.day == now.day - 1) {
        dateLabel = 'Kemarin';
      } else {
        dateLabel = DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(txDate);
      }
      
      if (!grouped.containsKey(dateLabel)) {
        grouped[dateLabel] = [];
      }
      grouped[dateLabel]!.add(transaction);
    }
    
    return grouped;
  }

  void _showTransactionDetail(Transaction transaction) {
    Navigator.pushNamed(
      context,
      '/transaksi',
      arguments: transaction,
    );
  }

  void _showFilterDialog() {
    // TODO: Implement advanced filter dialog (date range, payment method, etc)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filter lanjutan akan segera hadir'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _refreshData() async {
    await context.read<TransactionProvider>().fetchTransactions();
  }
}
