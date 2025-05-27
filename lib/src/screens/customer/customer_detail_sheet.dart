import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/customer_controller.dart';
import 'package:url_launcher/url_launcher.dart';

import 'customer_model.dart';

class CustomerDetailsSheet extends StatefulWidget {
  final Customer customer;

  const CustomerDetailsSheet({super.key, required this.customer});

  @override
  State<CustomerDetailsSheet> createState() => _CustomerDetailsSheetState();
}

class _CustomerDetailsSheetState extends State<CustomerDetailsSheet>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late CustomerController _controller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _controller = context.read<CustomerController>();

    // Load detailed customer data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.getCustomerDetail(widget.customer.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header Section
              _buildHeader(),

              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: Theme.of(context).primaryColor,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Contact'),
                    Tab(text: 'Business'),
                  ],
                ),
              ),

              // Tab Content
              Expanded(
                child: Consumer<CustomerController>(
                  builder: (context, controller, child) {
                    if (controller.isDetailLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (controller.detailErrorMessage != null) {
                      return _buildErrorState(controller.detailErrorMessage!);
                    }

                    final customerData =
                        controller.customerDetail?.isNotEmpty == true
                            ? controller.customerDetail!.first
                            : null;

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(customerData, scrollController),
                        _buildContactTab(customerData, scrollController),
                        _buildBusinessTab(customerData, scrollController),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Enhanced Avatar with gradient
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.customer.name.isNotEmpty
                    ? widget.customer.name[0].toUpperCase()
                    : 'C',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Customer Basic Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.customer.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Consumer<CustomerController>(
                  builder: (context, controller, child) {
                    final customerData =
                        controller.customerDetail?.isNotEmpty == true
                            ? controller.customerDetail!.first
                            : null;

                    return Text(
                      customerData?['Representative'] ?? 'Loading...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: ${widget.customer.id}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Active',
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    Map<String, dynamic>? data,
    ScrollController scrollController,
  ) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        // Quick Stats Cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Opening Balance',
                data?['openingBalance'] ?? '0.00',
                Icons.account_balance_wallet,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Member Since',
                _formatYear(data?['registrationDate']),
                Icons.calendar_today,
                Colors.green,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Company Information
        _buildSectionHeader('Company Information'),
        const SizedBox(height: 12),
        _buildInfoCard([
          _buildInfoRow(
            Icons.business,
            'Company Type',
            data?['company_type']?['Name'] ?? 'N/A',
          ),
          _buildInfoRow(
            Icons.payment,
            'Payment Type',
            data?['payment_type']?['Name'] ?? 'N/A',
          ),
          _buildInfoRow(
            Icons.location_on,
            'Region',
            data?['region']?['Name'] ?? 'N/A',
          ),
          _buildInfoRow(
            Icons.calendar_today,
            'Registration Date',
            _formatDate(data?['registrationDate']),
          ),
        ]),

        const SizedBox(height: 24),

        // Recent Activity (Placeholder)
        _buildSectionHeader('Recent Activity'),
        const SizedBox(height: 12),
        _buildActivityCard(),

        const SizedBox(height: 100), // Bottom padding for actions
      ],
    );
  }

  Widget _buildContactTab(
    Map<String, dynamic>? data,
    ScrollController scrollController,
  ) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        // Contact Methods
        _buildSectionHeader('Contact Information'),
        const SizedBox(height: 12),
        _buildContactCard([
          _buildContactRow(
            Icons.phone_android,
            'Mobile',
            data?['Mobile'] ?? widget.customer.mobile,
            () => _makeCall(data?['Mobile'] ?? widget.customer.mobile),
          ),
          _buildContactRow(
            Icons.phone,
            'Phone',
            data?['Phone'] ?? 'N/A',
            data?['Phone'] != null ? () => _makeCall(data!['Phone']) : null,
          ),
          _buildContactRow(
            Icons.email,
            'Email',
            data?['Email'] ?? 'N/A',
            data?['Email'] != null ? () => _sendEmail(data!['Email']) : null,
          ),
        ]),

        const SizedBox(height: 24),

        // Address Information
        _buildSectionHeader('Address'),
        const SizedBox(height: 12),
        _buildAddressCard(data),

        const SizedBox(height: 24),

        // Representative Information
        if (data?['Representative'] != null) ...[
          _buildSectionHeader('Representative'),
          const SizedBox(height: 12),
          _buildRepresentativeCard(data!),
        ],

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildBusinessTab(
    Map<String, dynamic>? data,
    ScrollController scrollController,
  ) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        // Business Details
        _buildSectionHeader('Business Details'),
        const SizedBox(height: 12),
        _buildInfoCard([
          _buildInfoRow(
            Icons.business_center,
            'Company Type',
            data?['company_type']?['Name'] ?? 'N/A',
          ),
          _buildInfoRow(
            Icons.payment,
            'Payment Method',
            data?['payment_type']?['Name'] ?? 'N/A',
          ),
          _buildInfoRow(
            Icons.account_balance,
            'Opening Balance',
            '\$${data?['openingBalance'] ?? '0.00'}',
          ),
          _buildInfoRow(
            Icons.date_range,
            'Balance As Of',
            _formatDate(data?['openingBalanceAsOfDate']),
          ),
        ]),

        const SizedBox(height: 24),

        // Location Details
        _buildSectionHeader('Location Details'),
        const SizedBox(height: 12),
        _buildInfoCard([
          _buildInfoRow(
            Icons.location_city,
            'Region',
            data?['region']?['Name'] ?? 'N/A',
          ),
          _buildInfoRow(Icons.mail, 'Postal Code', data?['postCode'] ?? 'N/A'),
          _buildInfoRow(
            Icons.gps_fixed,
            'Coordinates',
            data?['latitude'] != null && data?['longitude'] != null
                ? '${data!['latitude']}, ${data!['longitude']}'
                : 'Not available',
          ),
        ]),

        const SizedBox(height: 24),

        // Account Manager
        if (data?['user'] != null) ...[
          _buildSectionHeader('Account Manager'),
          const SizedBox(height: 12),
          _buildAccountManagerCard(data!['user']),
        ],

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildContactRow(
    IconData icon,
    String title,
    String value,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.launch, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic>? data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Full Address',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data?['Address'] ?? 'Address not available',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          if (data?['postCode'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'Postal Code: ${data!['postCode']}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRepresentativeCard(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.orange[100],
            child: Icon(Icons.person, color: Colors.orange[700]),
          ),
          const SizedBox(width: 12),
          Text(
            data['Representative'],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountManagerCard(Map<String, dynamic> user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.purple[100],
            child: Icon(Icons.support_agent, color: Colors.purple[700]),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user['name'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Account Manager',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'No recent activity',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            error,
            style: TextStyle(color: Colors.red[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _controller.getCustomerDetail(widget.customer.id),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatYear(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return date.year.toString();
    } catch (e) {
      return dateStr;
    }
  }

  void _makeCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _sendEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }
}

// Add this to your FloatingActionButton or similar
Widget _buildFloatingActions(BuildContext context) {
  return Positioned(
    bottom: 20,
    left: 20,
    right: 20,
    child: Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Handle call action
            },
            icon: const Icon(Icons.call),
            label: const Text('Call'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Handle edit action
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
