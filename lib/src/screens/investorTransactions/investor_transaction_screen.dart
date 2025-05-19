import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/investor_transaction_controller.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';

class InvestorTransactionScreen extends StatefulWidget {
  const InvestorTransactionScreen({super.key});

  @override
  State<InvestorTransactionScreen> createState() =>
      _InvestorTransactionScreenState();
}

class _InvestorTransactionScreenState extends State<InvestorTransactionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _deleteReasonController = TextEditingController();
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  late InvestorTransactionController _controller =
      InvestorTransactionController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller = Provider.of<InvestorTransactionController>(
        context,
        listen: false,
      );
      _controller.getInvestorTransaction();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final controller = Provider.of<InvestorTransactionController>(
        context,
        listen: false,
      );
      if (!controller.isLoading && controller.hasMore) {
        controller.loadMore();
      }
    }
  }

  String _getTransactionTypeText(String type) {
    switch (type) {
      case '1':
        return 'Deposit';
      case '2':
        return 'Withdrawal';
      default:
        return 'Unknown';
    }
  }

  Color _getTransactionTypeColor(String type) {
    switch (type) {
      case '1':
        return Colors.green;
      case '2':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _navigateToTransactionDetail(Map<String, dynamic> transaction) {
    NavigationService().pushNavigation(
      Screenroutes.investorTransactionDetailScreen,
      arguments: transaction,
    );
  }

  void _navigateToReportsScreen() {
    NavigationService().pushNavigation(
      Screenroutes.investorTransactionReportsScreen,
    );
  }

  Future<void> _confirmDelete(int id) async {
    _deleteReasonController.clear();
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Are you sure you want to delete this transaction?'),
              const SizedBox(height: 16),
              TextField(
                controller: _deleteReasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for deletion',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed:
                  () => NavigationService().popNavigation(arguments: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed:
                  () => NavigationService().popNavigation(arguments: true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (result == true) {
      _controller.deleteInvestorTransaction(id, _deleteReasonController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Investor Transactions'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.summarize),
            tooltip: 'Reports',
            onPressed: _navigateToReportsScreen,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Consumer<InvestorTransactionController>(
              builder: (context, controller, _) {
                if (controller.isLoading &&
                    controller.investorTransactionData == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.investorTransactionData == null ||
                    controller.investorTransactionData!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No transactions found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                final filteredData =
                    controller.investorTransactionData!.where((transaction) {
                      final reference =
                          transaction['referenceNumber']
                              .toString()
                              .toLowerCase();
                      final query = _searchQuery.toLowerCase();

                      return reference.contains(query);
                    }).toList();

                if (filteredData.isEmpty) {
                  return const Center(
                    child: Text(
                      'No matching transactions found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    controller.currentPage = 1;
                    await controller.getInvestorTransaction();
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        filteredData.length + (controller.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == filteredData.length) {
                        return Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: const CircularProgressIndicator(),
                          ),
                        );
                      }

                      final transaction = filteredData[index];
                      final transactionType =
                          transaction['transaction_type'] as String;
                      final amount = double.parse(transaction['totalAmount']);
                      final formattedAmount = NumberFormat.currency(
                        symbol: transaction['currency']['Name'],
                      ).format(amount);

                      return _buildTransactionCard(
                        transaction,
                        transactionType,
                        formattedAmount,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          NavigationService().pushNavigation(
            Screenroutes.investorTransactionDataScreen,
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create New'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextFormField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search by reference number',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF8F9BB3)),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear, color: Color(0xFF8F9BB3)),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                  : null,
          filled: true,
          fillColor: const Color(0xFFF7F9FC),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    Map<String, dynamic> transaction,
    String transactionType,
    String formattedAmount,
  ) {
    final typeText = _getTransactionTypeText(transactionType);
    final typeColor = _getTransactionTypeColor(transactionType);
    final investor = transaction['investor']['Name'];
    final reference = transaction['referenceNumber'];
    final id = transaction['id'];

    return GestureDetector(
      onTap: () => _navigateToTransactionDetail(transaction),

      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      investor,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      typeText,
                      style: TextStyle(
                        color: typeColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.receipt_long,
                    size: 16,
                    color: Color(0xFF8F9BB3),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Reference: $reference',
                    style: const TextStyle(
                      color: Color(0xFF8F9BB3),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Color(0xFF8F9BB3),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'ID: ',
                        style: TextStyle(
                          color: Color(0xFF8F9BB3),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${transaction['id']}',
                        style: const TextStyle(
                          color: Color(0xFF8F9BB3),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    formattedAmount,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: typeText == 'Deposit' ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _confirmDelete(id),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
