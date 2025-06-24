// supplier_advance_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/models/supplier_advance_model.dart';
import 'package:sample/src/providers/supplier_advance_controller.dart';

class SupplierAdvanceBottomSheet extends StatefulWidget {
  final int id;

  const SupplierAdvanceBottomSheet({super.key, required this.id});

  @override
  State<SupplierAdvanceBottomSheet> createState() =>
      _SupplierAdvanceBottomSheetState();
}

class _SupplierAdvanceBottomSheetState
    extends State<SupplierAdvanceBottomSheet> {
  late SupplierAdvanceController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller = context.read<SupplierAdvanceController>();
      _controller.getSupplierAdvanceDetail(widget.id);
    });
  }

  @override
  void dispose() {
    _controller.clearSupplierAdvanceDetail();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Supplier Advance Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: Consumer<SupplierAdvanceController>(
              builder: (context, controller, child) {
                return _buildContent(controller);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(SupplierAdvanceController controller) {
    // Loading State
    if (controller.isDetailLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading supplier advance details...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Error State
    if (controller.detailErrorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Failed to load details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                controller.detailErrorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => controller.getSupplierAdvanceDetail(widget.id),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // Success State
    if (controller.supplierAdvanceDetail == null) {
      return const Center(
        child: Text(
          'No details available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return _buildDetailContent(controller.supplierAdvanceDetail!);
  }

  Widget _buildDetailContent(SupplierAdvanceWithDetails detail) {
    final supplierAdvance = detail.supplierAdvance;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Supplier Info Card
          _buildInfoCard(
            title: 'Supplier Information',
            children: [
              _buildInfoRow(
                'Supplier Name',
                supplierAdvance.supplier?.Name ?? 'Unknown',
              ),
              _buildInfoRow('Receipt Number', supplierAdvance.receiptNumber),
              _buildInfoRow('Transfer Date', supplierAdvance.formattedDate),
              _buildInfoRow(
                'Payment Type',
                supplierAdvance.paymentType.toUpperCase(),
              ),
              _buildInfoRow(
                'Currency',
                supplierAdvance.currency?.Name ?? 'USD',
              ),
              if (supplierAdvance.receiverName != null)
                _buildInfoRow('Receiver Name', supplierAdvance.receiverName!),
              if (supplierAdvance.description != null &&
                  supplierAdvance.description!.isNotEmpty)
                _buildInfoRow('Description', supplierAdvance.description!),
            ],
          ),

          const SizedBox(height: 16),

          // Amount Summary Card
          _buildAmountSummaryCard(supplierAdvance),

          const SizedBox(height: 16),

          // Advance Details Section
          if (detail.details.isNotEmpty)
            _buildAdvanceDetailsSection(detail.details),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSummaryCard(SupplierAdvance supplierAdvance) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Amount Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '${supplierAdvance.currency?.Name ?? 'USD'} ${_formatAmount(supplierAdvance.amount)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent Balance',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  '${supplierAdvance.currency?.Name ?? 'USD'} ${_formatAmount(supplierAdvance.spentBalance)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.red[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remaining Balance',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  '${supplierAdvance.currency?.Name ?? 'USD'} ${_formatAmount(supplierAdvance.remainingBalance)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color:
                    supplierAdvance.isPushedBool
                        ? Colors.green[50]
                        : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      supplierAdvance.isPushedBool
                          ? Colors.green[200]!
                          : Colors.orange[200]!,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    supplierAdvance.isPushedBool
                        ? Icons.check_circle
                        : Icons.pending,
                    size: 16,
                    color:
                        supplierAdvance.isPushedBool
                            ? Colors.green[600]
                            : Colors.orange[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    supplierAdvance.isPushedBool ? 'Synced' : 'Pending Sync',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color:
                          supplierAdvance.isPushedBool
                              ? Colors.green[700]
                              : Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvanceDetailsSection(List<SupplierAdvanceDetail> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advance Details (${details.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...details.map((detail) => _buildAdvanceDetailCard(detail)).toList(),
      ],
    );
  }

  Widget _buildAdvanceDetailCard(SupplierAdvanceDetail detail) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detail #${detail.id}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatAmount(detail.amount),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (detail.description.isNotEmpty)
              Text(
                detail.description,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (detail.referenceNumber != null) ...[
                  Text(
                    'Ref: ${detail.referenceNumber}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                ],
                Text(
                  _formatDate(detail.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(String amount) {
    try {
      final double value = double.parse(amount);
      return value.toStringAsFixed(2);
    } catch (e) {
      return amount;
    }
  }

  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
