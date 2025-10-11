import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/models/supplier_advance_model.dart';
import 'package:sample/src/providers/supplier_advance_controller.dart';
import 'package:sample/src/screens/supplierAdvance/supplier_advance_bottom_sheet.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:sample/src/util/delete_confirmation_dialog.dart';

class SupplierAdvanceListScreen extends StatefulWidget {
  const SupplierAdvanceListScreen({super.key});

  @override
  State<SupplierAdvanceListScreen> createState() =>
      _SupplierAdvanceListScreenState();
}

class _SupplierAdvanceListScreenState extends State<SupplierAdvanceListScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _deleteReasonController = TextEditingController();
  late SupplierAdvanceController _controller;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  final TextEditingController _pushReasonController = TextEditingController();

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
        _controller = Provider.of<SupplierAdvanceController>(
          context,
          listen: false,
        );
        if (_controller.hasMore && !_controller.isLoading) {
          _controller.getSupplierAdvance(loadMore: true);
        }
      }
    });
  }

  void _loadInitialData() {
    _controller = Provider.of<SupplierAdvanceController>(
      context,
      listen: false,
    );
    _searchController.text = _controller.searchQuery;
    if (!_controller.hasData) {
      _controller.getSupplierAdvance();
    }
  }

  Future<void> _handleRefresh() async {
    _searchController.clear();
    final provider = Provider.of<SupplierAdvanceController>(
      context,
      listen: false,
    );
    await provider.getSupplierAdvance();
  }

  Future<void> _handlePushAdvance(SupplierAdvance advance) async {
    // Show confirmation dialog first
    final bool? shouldPush = await _showPushConfirmation(advance);

    if (shouldPush != true) return;

    final provider = Provider.of<SupplierAdvanceController>(
      context,
      listen: false,
    );

    try {
      await provider.getSupplierAdvancePush(advance.id);

      if (provider.pushErrorMessage == null) {
        // Success - refresh the list to update the status
        await provider.getSupplierAdvance();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Supplier advance pushed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Error occurred
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
            content: Text('Failed to push advance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool?> _showPushConfirmation(SupplierAdvance advance) async {
    _pushReasonController.clear();
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Push Supplier Advance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to push "${advance.receiptNumber}" to the server?',
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
              onPressed:
                  () => NavigationService().popNavigation(arguments: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed:
                  () => NavigationService().popNavigation(arguments: true),
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
          'Supplier Advances',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<SupplierAdvanceController>(
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
            Screenroutes.supplierAdvanceDataScreen,
          );
          _searchController.clear();
          _controller.clearSearch();
          _controller.refresh();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar(SupplierAdvanceController provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by receipt number...',
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

  Widget _buildContent(SupplierAdvanceController provider) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (provider.isLoading && provider.filteredSupplierAdvances.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text(
                      'Loading supplier advances...',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else if (provider.filteredSupplierAdvances.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Supplier Advances',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchController.text.isNotEmpty
                          ? 'No advances found matching your search'
                          : 'No supplier advances available',
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
                    if (index == provider.filteredSupplierAdvances.length) {
                      return _buildLoadMoreIndicator(provider);
                    }
                    final advance = provider.filteredSupplierAdvances[index];
                    return _buildAdvanceCard(advance, provider);
                  },
                  childCount:
                      provider.filteredSupplierAdvances.length +
                      (provider.hasMore ? 1 : 0),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdvanceCard(
    SupplierAdvance advance,
    SupplierAdvanceController provider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showAdvanceDetails(advance);
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
                          advance.supplier?.name ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          advance.receiptNumber,
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
                        advance.formattedAmount,
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
                              advance.isPushedBool
                                  ? Colors.green[100]
                                  : Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          advance.isPushedBool ? 'Synced' : 'Pending',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                advance.isPushedBool
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
                    advance.formattedDate,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  // Push Button - Only show if not already pushed
                  if (!advance.isPushedBool) ...[
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
                                        : () => _handlePushAdvance(advance),
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
                      _showDeleteConfirmation(advance);
                    },
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red[400],
                    tooltip: 'Delete Expense data',
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

  void _showDeleteConfirmation(SupplierAdvance advance) async {
    await DeleteConfirmationDialog.show(
      context: context,
      title: 'Delete Supplier Advance Data',
      message: 'Are you sure you want to delete this supplier advance data?',
      reasonLabel: 'Reason for deletion *',
      onDelete: (reason) async {
        await _controller.deleteSupplierAdvance(advance.id, reason);
      },
      getErrorMessage: () => _controller.errorMessage,
    );
  }

  Widget _buildLoadMoreIndicator(SupplierAdvanceController provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child:
          provider.isLoading
              ? const CircularProgressIndicator()
              : const SizedBox.shrink(),
    );
  }

  void _showAdvanceDetails(SupplierAdvance advance) {
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
                    SupplierAdvanceBottomSheet(id: advance.id),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
