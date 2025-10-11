import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/customer_controller.dart';
import 'package:sample/src/screens/customer/customer_detail_sheet.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:sample/src/util/delete_confirmation_dialog.dart';

import 'customer_model.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen>
    with AutomaticKeepAliveClientMixin {
  // FIXED: Keep this screen alive to prevent data loss
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late CustomerController _controller;
  final TextEditingController _deleteReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // FIXED: Access controller in a safer way
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeController();
    });
  }

  // FIXED: Separate initialization method
  void _initializeController() {
    try {
      _controller = context.read<CustomerController>();

      _searchController.text = '';
      _controller.refresh();

      // Only load data if not already loaded
      if (!_controller.hasData && !_controller.isLoading) {
        _controller.getCustomerData();
      }

      _scrollController.addListener(_onScroll);
    } catch (e) {
      debugPrint("Error initializing controller: $e");
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _controller.loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _deleteReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.black87,
        title: const Text(
          'Customers',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ),
      body: Consumer<CustomerController>(
        builder: (context, controller, child) {
          // FIXED: Initialize controller if not done yet
          if (!mounted) return const SizedBox.shrink();

          return RefreshIndicator(
            onRefresh: () async {
              HapticFeedback.lightImpact();
              await controller.refresh();
            },
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Colors.white,
            child: Column(
              children: [
                // Search Bar - Fixed at top
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: SearchBar(
                    controller: _searchController,
                    hintText: 'Search customers...',
                    leading: const Icon(Icons.search),
                    trailing: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            _searchController.clear();
                            controller.clearSearch();
                          },
                          icon: const Icon(Icons.clear),
                        ),
                    ],
                    onChanged: (value) {
                      controller.searchCustomers(value);
                    },
                    backgroundColor: WidgetStateProperty.all(Colors.grey[100]),
                    elevation: WidgetStateProperty.all(0),
                  ),
                ),

                // Content Area - Expandable
                Expanded(
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [_buildContentSliver(controller)],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // FIXED: Properly handle navigation and refresh
          final result = await NavigationService().pushNavigation(
            Screenroutes.customerDataScreen,
          );

          // Clear search and refresh after returning
          _searchController.clear();
          _controller.clearSearch();

          // Only refresh if a customer was actually added
          if (result != null) {
            await _controller.refresh();
          }
        },

        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContentSliver(CustomerController controller) {
    // FIXED: Better loading state management
    if (controller.isLoading && controller.customers.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading customers...'),
            ],
          ),
        ),
      );
    }

    if (controller.errorMessage != null && controller.customers.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  controller.errorMessage!,
                  style: TextStyle(color: Colors.red[600], fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => controller.refresh(),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (controller.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                controller.searchQuery.isNotEmpty
                    ? 'No customers found for "${controller.searchQuery}"'
                    : 'No customers found',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                textAlign: TextAlign.center,
              ),
              if (controller.searchQuery.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Pull down to refresh or tap + to add a customer',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // FIXED: Show loading indicator for load more
            if (index == controller.customers.length) {
              if (controller.hasMore && controller.isLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (!controller.hasMore) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No more customers to load',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }

            if (index >= controller.customers.length) {
              return const SizedBox.shrink();
            }

            final customer = controller.customers[index];
            return CustomerCard(
              customer: customer,
              onTap: () => _showCustomerDetails(customer),
              onDelete: () => _showDeleteConfirmation(customer),
            );
          },
          childCount:
              controller.customers.length +
              (controller.hasMore || controller.isLoadingMore ? 1 : 0),
        ),
      ),
    );
  }

  void _showCustomerDetails(Customer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomerDetailsSheet(customer: customer),
    );
  }

  void _showDeleteConfirmation(Customer customer) async {
    await DeleteConfirmationDialog.show(
      context: context,
      title: 'Delete Customer Data',
      message: 'Are you sure you want to delete this customer data?',
      reasonLabel: 'Reason for deletion *',
      onDelete: (reason) async {
        await _controller.deleteCustomer(customer.id, reason);
      },
      getErrorMessage: () => _controller.errorMessage,
    );
  }
}

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const CustomerCard({
    super.key,
    required this.customer,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar with better fallback
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue[100],
                child: Text(
                  _getInitial(customer.name),
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Customer Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name.isEmpty
                          ? 'Unknown Customer'
                          : customer.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (customer.mobile.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              customer.mobile,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(customer.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Delete Button with confirmation
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red[400],
                    tooltip: 'Delete Customer',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  // Arrow Icon
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitial(String name) {
    if (name.isEmpty) return 'C';
    return name.trim()[0].toUpperCase();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return _formatFullDate(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

String _formatFullDate(DateTime date) {
  final months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
