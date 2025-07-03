import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/models/sales_model.dart';
import 'package:sample/src/providers/sales_controller.dart';
import 'package:sample/src/screens/sales/sales_detail_bottom_sheet.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({super.key});

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late SalesController _controller;
  final TextEditingController _deleteReasonController = TextEditingController();
  bool _showPdfViewer = false;
  String? _pdfUrl;

  @override
  void initState() {
    super.initState();

    // Initialize data loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller = context.read<SalesController>();
      _controller.getSalesData();
    });

    // Setup infinite scroll listener
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      context.read<SalesController>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showDeleteConfirmation(Sales sale) async {
    _deleteReasonController.clear();
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Purchase Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Are you sure you want to delete this purchase data?'),
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
      _controller.deleteSales(sale.id, _deleteReasonController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sale Data deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _viewSalesPdf(String salesId) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Loading PDF...'),
              ],
            ),
          );
        },
      );

      // Call the API to get PDF with sales ID
      await _controller.getSalesPdf(salesId);

      // Close loading dialog
      Navigator.of(context).pop();

      if (_controller.salesPdfUrl != null &&
          _controller.salesPdfUrl!.isNotEmpty) {
        setState(() {
          _pdfUrl = _controller.salesPdfUrl;
          _showPdfViewer = true;
        });
      } else {
        _showErrorSnackBar('PDF URL not available');
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showErrorSnackBar('Failed to load PDF: ${e.toString()}');
    }
  }

  void _hidePdfViewer() {
    if (_showPdfViewer) {
      setState(() {
        _showPdfViewer = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title:
            _showPdfViewer
                ? const Text('Sales PDF', style: TextStyle(color: Colors.white))
                : const Text(
                  'Sales',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        centerTitle: true,
        leading:
            _showPdfViewer
                ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: _hidePdfViewer,
                )
                : null,
      ),
      body:
          _showPdfViewer
              ? _buildPdfViewer()
              : Consumer<SalesController>(
                builder: (context, controller, child) {
                  return RefreshIndicator(
                    onRefresh: controller.refresh,
                    color: Colors.indigo[600],
                    child: CustomScrollView(
                      slivers: [
                        // Search Bar
                        SliverToBoxAdapter(child: _buildSearchBar(controller)),

                        // Main Content
                        SliverFillRemaining(child: _buildContent(controller)),
                      ],
                    ),
                  );
                },
              ),
      floatingActionButton:
          _showPdfViewer
              ? null
              : FloatingActionButton(
                onPressed: () {
                  NavigationService().pushNavigation(
                    Screenroutes.salesRegistration,
                  );
                },
                child: const Icon(Icons.add),
              ),
    );
  }

  Widget _buildPdfViewer() {
    return WillPopScope(
      onWillPop: () async {
        _hidePdfViewer();
        return false;
      },
      child: SfPdfViewer.network(
        _pdfUrl!,
        canShowPaginationDialog: true,
        onDocumentLoadFailed: (details) {
          _showErrorSnackBar('Failed to load PDF: ${details.description}');
          _hidePdfViewer();
        },
      ),
    );
  }

  Widget _buildSearchBar(SalesController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Invoice Number...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon:
                    controller.searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            controller.clearSearch();
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.indigo[600]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                controller.searchExpenses(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(SalesController controller) {
    // Error State
    if (controller.errorMessage != null && controller.sales.isEmpty) {
      return _buildErrorState(controller);
    }

    // Loading State (Initial)
    if (controller.isLoading && controller.sales.isEmpty) {
      return _buildLoadingState();
    }

    // Empty State
    if (controller.sales.isEmpty) {
      return _buildEmptyState(controller);
    }

    // Sales List
    return _buildSalesList(controller);
  }

  Widget _buildErrorState(SalesController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => controller.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading sales data...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(SalesController controller) {
    final isSearching = controller.searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'No sales found' : 'No sales yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try adjusting your search terms'
                  : 'Sales will appear here once you create them',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesList(SalesController controller) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: controller.sales.length + (controller.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator at the end
        if (index >= controller.sales.length) {
          return _buildLoadingIndicator();
        }

        final sale = controller.sales[index];
        return _buildSalesCard(sale);
      },
    );
  }

  Widget _buildSalesCard(Sales sale) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => SalesDetailBottomSheet(salesId: sale.id),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.indigo[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      sale.invoiceNumber,
                      style: TextStyle(
                        color: Colors.indigo[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(sale.saleDate),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Customer Info
              Row(
                children: [
                  Icon(Icons.business, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sale.customer.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Amount Row with Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Total Amount',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Text(
                      '${sale.totalAmount} ${sale.currency.name}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _viewSalesPdf(sale.id.toString()),
                        icon: const Icon(Icons.visibility),
                        color: Colors.blue[600],
                        tooltip: 'View PDF',
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          _showDeleteConfirmation(sale);
                        },
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red[400],
                        tooltip: 'Delete Sale data',
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
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
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
