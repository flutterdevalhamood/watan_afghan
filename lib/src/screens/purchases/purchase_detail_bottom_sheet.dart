// purchase_detail_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/models/purchase_model.dart';
import 'package:sample/src/providers/purchase_controller.dart';

class PurchaseDetailBottomSheet extends StatefulWidget {
  final int purchaseId;

  const PurchaseDetailBottomSheet({super.key, required this.purchaseId});

  @override
  State<PurchaseDetailBottomSheet> createState() =>
      _PurchaseDetailBottomSheetState();
}

class _PurchaseDetailBottomSheetState extends State<PurchaseDetailBottomSheet> {
  late PurchaseController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller = context.read<PurchaseController>();
      _controller.getPurchaseDetail(widget.purchaseId);
    });
  }

  @override
  void dispose() {
    _controller.clearPurchaseDetail();
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
                  'Purchase Details',
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
            child: Consumer<PurchaseController>(
              builder: (context, controller, child) {
                return _buildContent(controller);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(PurchaseController controller) {
    // Loading State
    if (controller.isDetailLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading purchase details...',
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
                onPressed:
                    () => controller.getPurchaseDetail(widget.purchaseId),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // Success State
    if (controller.purchaseDetail == null) {
      return const Center(
        child: Text(
          'No details available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return _buildDetailContent(controller.purchaseDetail!);
  }

  Widget _buildDetailContent(PurchaseDetail detail) {
    final purchase = detail.purchase;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Purchase Info Card
          _buildInfoCard(
            title: 'Purchase Information',
            children: [
              _buildInfoRow('Invoice Number', purchase.invoiceNumber),
              _buildInfoRow(
                'Purchase Date',
                _formatDate(purchase.purchaseDate),
              ),
              _buildInfoRow('Supplier', purchase.supplier?.name ?? 'Unknown'),
              _buildInfoRow('Currency', purchase.currency?.name ?? 'USD'),
              if (purchase.description != null)
                _buildInfoRow('Description', purchase.description ?? ''),
            ],
          ),

          const SizedBox(height: 16),

          // Amount Summary Card
          _buildAmountSummaryCard(purchase),

          const SizedBox(height: 16),

          // Invoice Images Section (NEW)
          if (purchase.purchaseInvoiceImages != null &&
              purchase.purchaseInvoiceImages!.isNotEmpty)
            _buildInvoiceImagesSection(purchase.purchaseInvoiceImages!),

          const SizedBox(height: 16),

          // Purchase Items
          _buildItemsSection(detail.purchaseDetail),
        ],
      ),
    );
  }

  // NEW: Invoice Images Section
  Widget _buildInvoiceImagesSection(List<PurchaseInvoiceImage> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Invoice Images (${images.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, index) {
              final image = images[index];
              return _buildImageThumbnail(image, index);
            },
          ),
        ),
      ],
    );
  }

  // NEW: Image Thumbnail Widget
  Widget _buildImageThumbnail(PurchaseInvoiceImage image, int index) {
    return Container(
      width: 120,
      height: 120,
      margin: EdgeInsets.only(
        right: index < 2 ? 12 : 0,
      ), // Adjust based on your needs
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            Image.network(
              image.fullUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[100],
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                      ),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[100],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        color: Colors.grey[400],
                        size: 32,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Failed to load',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
            // Tap overlay for full screen view
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showImageFullScreen(image),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: const Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.zoom_in, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NEW: Full Screen Image Viewer
  void _showImageFullScreen(PurchaseInvoiceImage image) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              // Full screen image
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    image.fullUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.white,
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Loading image...',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              color: Colors.white,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Close button
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
              // Image title (optional)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    image.title ?? 'Invoice Image',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

  Widget _buildAmountSummaryCard(Purchase purchase) {
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
                  '${purchase.currency?.name ?? 'USD'} ${_formatAmount(purchase.totalAmount)}',
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
                  'Paid Balance',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  '${purchase.currency?.name ?? 'USD'} ${_formatAmount(purchase.paidBalance)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.green[600],
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
                  '${purchase.currency?.name ?? 'USD'} ${_formatAmount(purchase.remainingBalance)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection(List<PurchaseDetailItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Purchase Items (${items.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _buildItemCard(item)).toList(),
      ],
    );
  }

  Widget _buildItemCard(PurchaseDetailItem item) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Name
            Text(
              item.product?.name ?? 'Unknown Product',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Product Details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildItemDetail(
                        'Quantity',
                        '${item.qty} ${item.unit?.name ?? ''}',
                      ),
                      _buildItemDetail('Unit Cost', _formatAmount(item.cost)),
                      _buildItemDetail(
                        'Tax',
                        '${item.taxPer}% (${_formatAmount(item.taxAmount)})',
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        _formatAmount(item.amount),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 12)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
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
