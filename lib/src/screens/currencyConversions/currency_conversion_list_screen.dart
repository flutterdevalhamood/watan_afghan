import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/currency_conversion_controller.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';

class CurrencyConversionListScreen extends StatefulWidget {
  const CurrencyConversionListScreen({super.key});

  @override
  State<CurrencyConversionListScreen> createState() =>
      _CurrencyConversionListScreenState();
}

class _CurrencyConversionListScreenState
    extends State<CurrencyConversionListScreen> {
  final ScrollController _scrollController = ScrollController();
  late CurrencyConversionController _controller;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _deleteReasonController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    _controller = Provider.of<CurrencyConversionController>(
      context,
      listen: false,
    );
    _loadData();
    _searchQuery = '';
    _searchController.text = '';

    // Setup scroll listener for pagination
    _scrollController.addListener(_scrollListener);

    // Setup search controller listener
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _controller.getCurrencyConversion();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _controller.loadMore();
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
      _filterTransactions();
    });
  }

  void _filterTransactions() {
    if (_searchQuery.isEmpty) {
      _filteredTransactions = [];
      return;
    }

    final transactions = _controller.currencyConversionData;
    if (transactions == null) return;

    _filteredTransactions =
        transactions.where((transaction) {
          final referenceNumber =
              transaction['referenceNumber']?.toString().toLowerCase() ?? '';
          return referenceNumber.contains(_searchQuery);
        }).toList();
  }

  void _onTransactionTap(int id) {
    _controller.id = id;

    NavigationService().pushNavigation(
      Screenroutes.currencyConversionDetailScreen,
      arguments: id,
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by reference number...',
            prefixIcon: const Icon(Icons.search, color: Colors.blue),
            suffixIcon:
                _searchQuery.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        FocusScope.of(context).unfocus();
                      },
                    )
                    : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (value) {
            // Hide keyboard on submit
            FocusScope.of(context).unfocus();
          },
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final String referenceNumber = transaction['referenceNumber'] ?? 'N/A';
    final String date = transaction['transaction_date'] ?? 'N/A';
    final String description = transaction['Description'] ?? 'No description';
    final int id = transaction['id'] ?? 0;

    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(date);
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }

    final formattedDate =
        parsedDate != null
            ? DateFormat('MMM dd, yyyy').format(parsedDate)
            : date;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        referenceNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => _onTransactionTap(id),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('VIEW DETAILS'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
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

  Widget _buildNoSearchResultsMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No transactions match "$_searchQuery"',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 70, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to refresh or add a new transaction',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 70, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('TRY AGAIN'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(int id) async {
    _deleteReasonController.clear();
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Currency Conversion Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Are you sure you want to delete this conversion data?',
              ),
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
      _controller.deleteCurrencyConversion(id, _deleteReasonController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conversion data deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text(
          'Currency Conversions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filtering
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filtering coming soon')),
              );
            },
          ),
        ],
      ),
      body: Consumer<CurrencyConversionController>(
        builder: (context, controller, child) {
          if (controller.isLoading &&
              controller.currencyConversionData == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null) {
            return _buildErrorState(controller.errorMessage!);
          }

          final transactions = controller.currencyConversionData;

          if (transactions == null || transactions.isEmpty) {
            return _buildEmptyState();
          }

          // Use filtered list when searching, otherwise use full list
          final displayedTransactions =
              _searchQuery.isNotEmpty ? _filteredTransactions : transactions;

          return Column(
            children: [
              // Search box at the top of the screen
              _buildSearchBox(),

              // Show search results message when searching with no results
              if (_searchQuery.isNotEmpty && displayedTransactions.isEmpty)
                _buildNoSearchResultsMessage(),

              // Main list of transactions
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    controller.currentPage = 1;
                    await controller.getCurrencyConversion();
                    // Re-apply search filter after refresh
                    if (_searchQuery.isNotEmpty) {
                      _filterTransactions();
                    }
                  },
                  child: Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount:
                            displayedTransactions.length +
                            (_searchQuery.isEmpty && controller.hasMore
                                ? 1
                                : 0),
                        itemBuilder: (context, index) {
                          if (index < displayedTransactions.length) {
                            return _buildTransactionCard(
                              displayedTransactions[index],
                            );
                          } else {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                        },
                      ),
                      if (controller.isLoading &&
                          transactions.isNotEmpty &&
                          !controller.hasMore &&
                          _searchQuery.isEmpty)
                        const Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          NavigationService().pushNavigation(
            Screenroutes.currencyConversionDataScreen,
          );
          _searchController.clear();
          _searchQuery = '';
          _controller.getCurrencyConversion();
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
