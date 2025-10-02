import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/models/supplier_payment_model.dart';
import 'package:sample/src/providers/supplier_payment_controller.dart';
import 'package:sample/src/screens/supplierPayment/supplier_payment_bottom_sheet.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:sample/src/util/delete_confirmation_dialog.dart';

class SupplierPaymentListScreen extends StatefulWidget {
  const SupplierPaymentListScreen({super.key});

  @override
  State<SupplierPaymentListScreen> createState() =>
      _SupplierPaymentListScreenState();
}

class _SupplierPaymentListScreenState extends State<SupplierPaymentListScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pushReasonController = TextEditingController();
  late SupplierPaymentController _controller;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
    _setupBlinkAnimation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
      _searchController.text = '';
      _controller.refresh();
    });
  }

  void _setupBlinkAnimation() {
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _blinkAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
    _blinkController.repeat(reverse: true);
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _controller = Provider.of<SupplierPaymentController>(
          context,
          listen: false,
        );
        if (_controller.hasMore && !_controller.isLoading) {
          _controller.getSupplierPayment(loadMore: true);
        }
      }
    });
  }

  void _loadInitialData() {
    _controller = Provider.of<SupplierPaymentController>(
      context,
      listen: false,
    );
    _searchController.text = _controller.searchQuery;
    if (!_controller.hasData) {
      _controller.getSupplierPayment();
    }
  }

  Future<void> _handleRefresh() async {
    _searchController.clear();
    final provider = Provider.of<SupplierPaymentController>(
      context,
      listen: false,
    );
    await provider.refresh();
  }

  Future<void> _handlePushPayment(SupplierPayment payment) async {
    final bool? shouldPush = await _showPushConfirmation(payment);

    if (shouldPush != true) return;

    final provider = Provider.of<SupplierPaymentController>(
      context,
      listen: false,
    );

    try {
      await provider.getSupplierPaymentPush(payment.id);

      if (provider.pushErrorMessage == null) {
        await provider.getSupplierPayment();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Supplier payment pushed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.pushErrorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to push payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool?> _showPushConfirmation(SupplierPayment payment) async {
    _pushReasonController.clear();
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Push Supplier Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to push "${payment.referenceNumber}" to the server?',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pushReasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for pushing (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Push', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _blinkController.dispose();
    _pushReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Supplier Payments',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<SupplierPaymentController>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildSearchBar(provider),
              Expanded(child: _buildContent(provider)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          NavigationService().pushNavigation(
            Screenroutes.supplierPaymentDataScreen,
          );
          _searchController.clear();
          _controller.clearSearch();
          _controller.refresh();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar(SupplierPaymentController provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by reference number...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      provider.searchExpenses('');
                    },
                  )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[700]!),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
        ),
        onChanged: (value) {
          provider.searchExpenses(value);
          setState(() {});
        },
      ),
    );
  }

  Widget _buildContent(SupplierPaymentController provider) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (provider.isLoading && provider.filteredSupplierPayments.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text(
                      'Loading supplier payments...',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else if (provider.filteredSupplierPayments.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.payment_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Supplier Payments',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchController.text.isNotEmpty
                          ? 'No payments found matching your search'
                          : 'No supplier payments available',
                      style: TextStyle(color: Colors.grey[500], fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == provider.filteredSupplierPayments.length) {
                      return _buildLoadMoreIndicator(provider);
                    }
                    final payment = provider.filteredSupplierPayments[index];
                    return _buildPaymentCard(payment, provider);
                  },
                  childCount:
                      provider.filteredSupplierPayments.length +
                      (provider.hasMore ? 1 : 0),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(
    SupplierPayment payment,
    SupplierPaymentController provider,
  ) {
    final isPushed = payment.isPushed == "1";

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to detail screen or show bottom sheet
          _showPaymentDetails(payment);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.supplier.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          payment.referenceNumber,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${payment.currency.name} ${payment.paidAmount}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isPushed ? Colors.green[100] : Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isPushed ? 'Synced' : 'Pending',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                isPushed
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(payment.transferDate),
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.monetization_on,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    payment.currency.name,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  if (!isPushed) ...[
                    AnimatedBuilder(
                      animation: _blinkAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _blinkAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue[600]!, Colors.blue[800]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap:
                                    provider.isPushLoading
                                        ? null
                                        : () => _handlePushPayment(payment),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (provider.isPushLoading)
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      else
                                        const Icon(
                                          Icons.cloud_upload,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      const SizedBox(width: 6),
                                      Text(
                                        provider.isPushLoading
                                            ? 'Pushing...'
                                            : 'Push',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],

                  IconButton(
                    onPressed: () {
                      _showDeleteConfirmation(payment);
                    },
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red[400],
                    tooltip: 'Delete Payment data',
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
        ),
      ),
    );
  }

  void _showDeleteConfirmation(SupplierPayment payment) async {
    await DeleteConfirmationDialog.show(
      context: context,
      title: 'Delete Supplier Payment Data',
      message: 'Are you sure you want to delete this supplier payment data?',
      reasonLabel: 'Reason for deletion *',
      onDelete: (reason) async {
        await _controller.deleteSupplierPayment(payment.id, reason);
      },
      getErrorMessage: () => _controller.errorMessage,
    );
  }

  void _showPaymentDetails(SupplierPayment payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) =>
                    SupplierPaymentBottomSheet(id: payment.id),
          ),
    );
  }

  Widget _buildLoadMoreIndicator(SupplierPaymentController provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child:
          provider.isLoading
              ? const CircularProgressIndicator()
              : const SizedBox.shrink(),
    );
  }

  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
    } catch (e) {
      return date;
    }
  }
}
