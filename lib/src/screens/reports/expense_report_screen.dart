import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/reports_controller.dart';
import 'package:sample/src/providers/sales_controller.dart';

class ExpenseReportScreen extends StatefulWidget {
  const ExpenseReportScreen({super.key});

  @override
  State<ExpenseReportScreen> createState() => _ExpenseReportScreenState();
}

class _ExpenseReportScreenState extends State<ExpenseReportScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  int? _selectedCategoryId;
  int? _selectedCurrencyId;
  String? _selectedFilter;
  bool _isLoading = false;
  String? _pdfPath;
  bool _isGeneratingReport = false;

  late ReportsController _controller;
  late SalesController _salesController;

  @override
  void initState() {
    super.initState();
    _controller = Provider.of<ReportsController>(context, listen: false);
    _salesController = Provider.of<SalesController>(context, listen: false);

    // Set default date range to last 30 days
    _toDate = DateTime.now();
    _fromDate = DateTime.now().subtract(const Duration(days: 30));

    // Load investors and currencies data
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get investors and currencies data
      await _salesController.getSalesBaseData();
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

      final isSuccess = await _controller.postExpenseReportsData(
        fromDateFormatted,
        toDateFormatted,
        'all',
        'all',
        _selectedCurrencyId,
      );

      if (isSuccess && _controller.expenseReportUrl != null) {
        await _downloadAndOpenPdf(_controller.expenseReportUrl!);
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

  Future<void> _downloadAndOpenPdf(String url) async {
    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Storage permission denied');
      }

      // Get app directory for saving PDF
      final dir = await getApplicationDocumentsDirectory();
      final filePath =
          '${dir.path}/expense_report_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Download the PDF using Dio
      final dio = Dio();
      await dio.download(url, filePath);

      if (mounted) {
        setState(() {
          _pdfPath = filePath;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Expense Reports',
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

                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    value: _selectedCategoryId,
                    hint: const Text('Select Category'),
                    isExpanded: true,
                    items: [
                      ..._salesController.currencyType?.map((currency) {
                            return DropdownMenuItem<int>(
                              value: currency['id'],
                              child: Text(currency['Name']),
                            );
                          }).toList() ??
                          [],
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: 'Filter',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    value: _selectedCategoryId,
                    hint: const Text('Select Filter'),
                    isExpanded: true,
                    items: [
                      ..._salesController.currencyType?.map((currency) {
                            return DropdownMenuItem<int>(
                              value: currency['id'],
                              child: Text(currency['Name']),
                            );
                          }).toList() ??
                          [],
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value.toString();
                      });
                    },
                  ),

                  const SizedBox(height: 24),

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
                      ..._salesController.currencyType?.map((currency) {
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
