import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/purchase_controller.dart';
import 'package:sample/src/providers/reports_controller.dart';
import 'package:sample/src/widgets/pdf_download_widget.dart';

class PurchaseReportScreen extends StatefulWidget {
  const PurchaseReportScreen({super.key});

  @override
  State<PurchaseReportScreen> createState() => _PurchaseReportScreenState();
}

class _PurchaseReportScreenState extends State<PurchaseReportScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  int? _selectedCurrencyId;
  dynamic _selectedSupplierId;
  String? _selectedSupplierName;
  bool _isLoading = false;
  String? _pdfPath;
  bool _isGeneratingReport = false;

  // Search controllers
  final TextEditingController _supplierSearchController =
      TextEditingController();
  List<Map<String, dynamic>> _filteredSuppliers = [];
  bool _isSupplierDropdownOpen = false;

  late ReportsController _controller;
  late PurchaseController _purchaseController;

  @override
  void initState() {
    super.initState();
    _controller = Provider.of<ReportsController>(context, listen: false);
    _purchaseController = Provider.of<PurchaseController>(
      context,
      listen: false,
    );

    // Set default date range to last 30 days
    _toDate = DateTime.now();
    _fromDate = DateTime.now().subtract(const Duration(days: 30));

    // Load investors and currencies data
    _loadFormData();

    // Initialize search controller listener
    _supplierSearchController.addListener(_filterSuppliers);
  }

  @override
  void dispose() {
    _supplierSearchController.removeListener(_filterSuppliers);
    _supplierSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get investors and currencies data
      await _purchaseController.getPurchaseBaseData();
      _initializeFilteredSuppliers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Always set isLoading to false when done, even if there's an error
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _initializeFilteredSuppliers() {
    if (_purchaseController.supplier != null) {
      _filteredSuppliers = List<Map<String, dynamic>>.from(
        _purchaseController.supplier!,
      );
    }
  }

  void _filterSuppliers() {
    final query = _supplierSearchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSuppliers =
            _purchaseController.supplier != null
                ? List<Map<String, dynamic>>.from(_purchaseController.supplier!)
                : [];
      } else {
        _filteredSuppliers =
            _purchaseController.supplier
                ?.where(
                  (supplier) =>
                      supplier['Name'].toString().toLowerCase().contains(query),
                )
                .toList() ??
            [];
      }
    });
  }

  void _selectSupplier(dynamic supplierId, String supplierName) {
    setState(() {
      _selectedSupplierId = supplierId;
      _selectedSupplierName = supplierName;
      _supplierSearchController.text = supplierName;
      _isSupplierDropdownOpen = false;
    });
  }

  void _clearSupplierSelection() {
    setState(() {
      _selectedSupplierId = null;
      _selectedSupplierName = null;
      _supplierSearchController.clear();
      _isSupplierDropdownOpen = false;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime initialDate =
        isFromDate
            ? (_fromDate ?? DateTime.now())
            : (_toDate ?? DateTime.now());
    final DateTime firstDate = DateTime(2000);
    final DateTime lastDate = DateTime.now().add(const Duration(days: 365));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Future<void> _generateReport() async {
    if (_fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date range'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isGeneratingReport = true; // Use a separate flag for report generation
    });

    try {
      final String fromDateFormatted = DateFormat(
        'yyyy-MM-dd',
      ).format(_fromDate!);
      final String toDateFormatted = DateFormat('yyyy-MM-dd').format(_toDate!);

      final isSuccess = await _controller.postPurchaseReportsData(
        fromDateFormatted,
        toDateFormatted,
        _selectedCurrencyId,
        _selectedSupplierId,
      );

      if (isSuccess && _controller.purchaseReportUrl != null) {
        final pdfPath = await PdfDownloadHelper.downloadAndOpenPdf(
          url: _controller.purchaseReportUrl!,
          reportType: 'purchase',
          context: context,
        );

        if (pdfPath != null && mounted) {
          setState(() {
            _pdfPath = pdfPath;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate report'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingReport = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Purchase Reports',
          style: TextStyle(
            color: Color(0xFF222B45),
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _pdfPath != null ? _buildPdfViewer() : _buildReportForm(),
    );
  }

  Widget _buildReportForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report Parameters',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Date Range Section
                  const Text(
                    'Date Range',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, true),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'From Date',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              suffixIcon: const Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              _fromDate != null
                                  ? DateFormat(
                                    'MMM dd, yyyy',
                                  ).format(_fromDate!)
                                  : 'Select Date',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, false),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'To Date',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              suffixIcon: const Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              _toDate != null
                                  ? DateFormat('MMM dd, yyyy').format(_toDate!)
                                  : 'Select Date',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Filters Section
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),

                  // Currency Dropdown
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    value: _selectedCurrencyId,
                    hint: const Text('Select Currency'),
                    isExpanded: true,
                    items: [
                      ..._purchaseController.currencyType?.map((currency) {
                            return DropdownMenuItem<int>(
                              value: currency['id'],
                              child: Text(currency['Name']),
                            );
                          }).toList() ??
                          [],
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCurrencyId = value;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Searchable Supplier Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _supplierSearchController,
                        decoration: InputDecoration(
                          labelText: 'Supplier',
                          hintText: 'Search or select supplier',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_selectedSupplierId != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: _clearSupplierSelection,
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(),
                                ),
                              IconButton(
                                icon: Icon(
                                  _isSupplierDropdownOpen
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isSupplierDropdownOpen =
                                        !_isSupplierDropdownOpen;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _isSupplierDropdownOpen = true;
                          });
                        },
                        readOnly: _selectedSupplierId != null,
                      ),
                      if (_isSupplierDropdownOpen)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              // "All" option
                              ListTile(
                                dense: true,
                                title: const Text('All'),
                                onTap: () => _selectSupplier('all', 'All'),
                                selected: _selectedSupplierId == 'all',
                              ),
                              // Filtered suppliers
                              ..._filteredSuppliers.map((supplier) {
                                return ListTile(
                                  dense: true,
                                  title: Text(supplier['Name']),
                                  onTap:
                                      () => _selectSupplier(
                                        supplier['id'],
                                        supplier['Name'],
                                      ),
                                  selected:
                                      _selectedSupplierId == supplier['id'],
                                );
                              }).toList(),
                              if (_filteredSuppliers.isEmpty &&
                                  _supplierSearchController.text.isNotEmpty)
                                const ListTile(
                                  dense: true,
                                  title: Text(
                                    'No suppliers found',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Column(
            children: [
              // Generate Report Button - Always visible
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isGeneratingReport ? null : _generateReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isGeneratingReport
                            ? Colors
                                .grey // Optional: change color when disabled
                            : Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Generate Report',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Ensure text is always visible
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 8,
              ), // Small space between button and loader
              // Only show loader when generating
              Visibility(
                visible: _isGeneratingReport,
                child: const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPdfViewer() {
    return Stack(
      children: [
        PDFView(
          filePath: _pdfPath!,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
          pageSnap: true,
          defaultPage: 0,
          fitPolicy: FitPolicy.BOTH,
          preventLinkNavigation: false,
          onError: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading PDF: $error'),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: Theme.of(context).colorScheme.primary,
            onPressed: () {
              setState(() {
                _pdfPath = null;
              });
            },
            child: const Icon(Icons.close),
          ),
        ),
      ],
    );
  }
}
