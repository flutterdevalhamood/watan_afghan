import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/reports_controller.dart';
import 'package:sample/src/util/pdf_share_helper.dart';
import 'package:sample/src/widgets/pdf_download_widget.dart';

class CurrentStockReportScreen extends StatefulWidget {
  const CurrentStockReportScreen({super.key});

  @override
  State<CurrentStockReportScreen> createState() =>
      _CurrentStockReportScreenState();
}

class _CurrentStockReportScreenState extends State<CurrentStockReportScreen> {
  bool _isGeneratingReport = false;
  String? _pdfPath;
  bool _includeValues = true; // Toggle between with/without values

  late ReportsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Provider.of<ReportsController>(context, listen: false);
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGeneratingReport = true;
    });

    try {
      bool isSuccess;
      String? reportUrl;

      if (_includeValues) {
        // Call API for stock report with values
        isSuccess = await _controller.getCurrentStockReportWithValues();
        reportUrl = _controller.currentStockReportWithValuesUrl;
      } else {
        // Call API for stock report without values
        isSuccess = await _controller.getCurrentStockReportWithoutValues();
        reportUrl = _controller.currentStockReportWithoutValuesUrl;
      }

      if (isSuccess && reportUrl != null) {
        final pdfPath = await PdfDownloadHelper.downloadAndOpenPdf(
          url: reportUrl,
          reportType:
              _includeValues
                  ? 'current_stock_with_values'
                  : 'current_stock_without_values',
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
          'Current Stock Report',
          style: TextStyle(
            color: Color(0xFF222B45),
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          if (_pdfPath != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed:
                  () => PdfShareHelper.sharePdf(
                    context: context,
                    pdfPath: _pdfPath!,
                    subject: 'Current Stock Report',
                    text: 'Current Stock Report ',
                  ),
              tooltip: 'Share Report',
            ),
        ],
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
                    'Report Configuration',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Report Type Selection
                  const Text(
                    'Report Type',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<bool>(
                          title: const Text(
                            'Current Stock Report (with values)',
                          ),
                          subtitle: const Text(
                            'Includes stock values and pricing information',
                          ),
                          value: true,
                          groupValue: _includeValues,
                          onChanged: (value) {
                            setState(() {
                              _includeValues = value!;
                            });
                          },
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                        const Divider(height: 1),
                        RadioListTile<bool>(
                          title: const Text(
                            'Current Stock Report (without values)',
                          ),
                          subtitle: const Text(
                            'Shows only stock quantities without pricing',
                          ),
                          value: false,
                          groupValue: _includeValues,
                          onChanged: (value) {
                            setState(() {
                              _includeValues = value!;
                            });
                          },
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Information Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _includeValues
                                ? 'This report will include current stock levels with their respective values and pricing information.'
                                : 'This report will show current stock quantities without any pricing or value information.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Generate Report Section
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isGeneratingReport ? null : _generateReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isGeneratingReport
                            ? Colors.grey
                            : Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _includeValues ? Icons.inventory : Icons.list_alt,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isGeneratingReport
                            ? 'Generating...'
                            : 'Generate Report',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Loading indicator
              Visibility(
                visible: _isGeneratingReport,
                child: const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text(
                        'Generating stock report...',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
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
