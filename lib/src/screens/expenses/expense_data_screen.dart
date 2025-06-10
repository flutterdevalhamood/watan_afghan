import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/expense_controller.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isExpenseRegistered = false;
  int? _savedExpenseId;
  PlatformFile? _selectedFile;

  final ImagePicker _picker = ImagePicker();
  File? _cameraImage;

  // Form values - Fixed variable assignments
  int? selectedSupplierId;
  int? selectedEmployeeId;
  int? selectedPaymentTypeId;
  String? selectedPaymentType;
  String? selectedReferenceNumber;
  int? selectedCurrencyId;
  String invoiceNumber = "ECFT-0087";
  DateTime invoiceDate = DateTime.now();

  // Payment related fields
  double paidAmount = 0.0;
  double roundOff = 0.0;
  double balanceAmount = 0.0;

  // Bank payment fields
  int? selectedBankId;
  String accountNumber = '';
  DateTime transferDate = DateTime.now();
  String chequeRefNumber = '';

  // Product table data
  List<SalesItem> salesItems = [SalesItem()];

  // Totals - Modified to include manual subtotal entry
  double subtotal = 0.0;
  double vatAmount = 0.0;
  double grandTotal = 0.0;
  double selectedVatRate = 0.05; // Default 5% VAT

  // Controllers for manual entry
  final TextEditingController subtotalController = TextEditingController(
    text: '0.0',
  );

  // VAT options
  final List<double> vatRates = [0.00, 0.05]; // 0% and 5%
  final List<String> vatLabels = ['0%', '5%'];

  // Controller for Terms and Customer Note
  final TextEditingController termsController = TextEditingController(
    text: 'Terms and Conditions',
  );
  final TextEditingController notesController = TextEditingController(
    text: 'Customer Notes',
  );

  // Controller for paid amount
  final TextEditingController paidAmountController = TextEditingController(
    text: '0.0',
  );

  // Stamp and signature
  String? needStamp = 'No';
  final List<String> stampOptions = ['Yes', 'No'];

  // Hardcoded Payment Types
  final List<Map<String, dynamic>> paymentTypes = [
    {'id': 1, 'Name': 'cash'},
    {'id': 2, 'Name': 'bank'},
    {'id': 3, 'Name': 'cheque'},
  ];

  @override
  void initState() {
    super.initState();
    // Load base data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBaseData();
    });
    // Initialize calculations
    _updateTotals();
  }

  Future<void> _captureImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80, // Reduce quality to avoid large file issues
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        // Create a copy of the image in app's directory to avoid permission issues
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String fileName =
            'camera_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String newPath = '${appDir.path}/$fileName';

        // Copy the image to app directory
        final File originalFile = File(image.path);
        final File newFile = await originalFile.copy(newPath);

        // Verify the file exists and has content
        if (await newFile.exists()) {
          final int fileSize = await newFile.length();
          print('Camera image saved: $newPath, Size: $fileSize bytes');

          setState(() {
            _cameraImage = newFile;
            _selectedFile = PlatformFile(
              name: fileName,
              path: newPath,
              size: fileSize,
            );
          });
        } else {
          throw Exception('Failed to save camera image');
        }
      }
    } catch (e) {
      print('Camera capture error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadBaseData() async {
    final controller = Provider.of<ExpenseController>(context, listen: false);
    await controller.getExpenseBaseData();
    if (controller.employeeType != null) {
      debugPrint(
        'Employee data loaded: ${controller.employeeType!.length} items',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're on a mobile device
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Consumer<ExpenseController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${controller.errorMessage}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  ElevatedButton(
                    onPressed: _loadBaseData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isExpenseRegistered) ...[
                      // Customer and Project section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDropdown(
                              value: controller.selectedSupplierTypeId,
                              items: controller.supplierType ?? [],
                              label: 'Supplier Type',
                              isRequired: true,
                              onChanged: (value) {
                                controller.setSupplierType(value);
                                setState(() {
                                  selectedSupplierId = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            _buildDropdown(
                              value: controller.selectedEmployeeId,
                              items: controller.employeeType ?? [],
                              label: 'Employee Name',
                              isRequired: true,
                              onChanged: (value) {
                                controller.setEmployee(value);
                                setState(() {
                                  selectedEmployeeId = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            // Single Date Field
                            _buildLabeledField(
                              'Expense Date:',
                              required: true,
                              child: GestureDetector(
                                onTap:
                                    () => _selectDate(
                                      context,
                                      isTransferDate: false,
                                    ),
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                      hintText: 'Select Date',
                                      suffixIcon: Icon(Icons.calendar_today),
                                    ),
                                    controller: TextEditingController(
                                      text: DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(invoiceDate),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Reference Number
                            _buildLabeledField(
                              'Reference Number:',
                              required: true,
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  hintText: 'Enter Reference Number',
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    selectedReferenceNumber = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a reference number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            _buildDropdown(
                              value: controller.selectedCurrencyTypeId,
                              items: controller.currency ?? [],
                              label: 'Currency Type',
                              isRequired: true,
                              onChanged: (value) {
                                controller.setCurrencyType(value);
                                setState(() {
                                  selectedCurrencyId = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Products Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Products Table Header
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              color: Colors.teal.shade100,
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Category *',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Amount *',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Products Table Rows
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: salesItems.length,
                              itemBuilder: (context, index) {
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  elevation: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildDropdown(
                                          value:
                                              salesItems[index]
                                                  .expenseCategoryId,
                                          items:
                                              controller.expenseCategory ?? [],
                                          label: 'Expense Type',
                                          isRequired: true,
                                          onChanged: (value) {
                                            setState(() {
                                              salesItems[index]
                                                  .expenseCategoryId = value;
                                            });
                                          },
                                        ),

                                        const SizedBox(height: 12),
                                        // Manual Subtotal Entry
                                        _buildLabeledField(
                                          'Amount:',
                                          required: true,
                                          child: TextFormField(
                                            controller:
                                                index == 0
                                                    ? subtotalController
                                                    : null,
                                            initialValue:
                                                index == 0
                                                    ? null
                                                    : salesItems[index].total
                                                        .toString(),
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              hintText: 'Enter amount',
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                double amount =
                                                    double.tryParse(value) ??
                                                    0.0;
                                                salesItems[index].total =
                                                    amount;
                                                if (index == 0) {
                                                  subtotal = amount;
                                                }
                                                _calculateGrandTotal();
                                              });
                                            },
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter amount';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),

                                        const SizedBox(height: 16),

                                        // VAT Selection
                                        _buildLabeledField(
                                          'VAT Rate:',
                                          required: true,
                                          child: DropdownButtonFormField<
                                            double
                                          >(
                                            decoration: const InputDecoration(
                                              hintText: 'Select VAT Rate',
                                            ),
                                            value:
                                                salesItems[index].vatAmount ==
                                                        0.0
                                                    ? selectedVatRate
                                                    : salesItems[index]
                                                        .vatAmount,
                                            items: List.generate(
                                              vatRates.length,
                                              (vatIndex) {
                                                return DropdownMenuItem<double>(
                                                  value: vatRates[vatIndex],
                                                  child: Text(
                                                    vatLabels[vatIndex],
                                                  ),
                                                );
                                              },
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                double vatRate = value ?? 0.05;
                                                salesItems[index].vatAmount =
                                                    vatRate;
                                                if (index == 0) {
                                                  selectedVatRate = vatRate;
                                                }
                                                _calculateGrandTotal();
                                              });
                                            },
                                            validator: (value) {
                                              if (value == null) {
                                                return 'Please select VAT rate';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),

                                        const SizedBox(height: 12),
                                        // Description TextField
                                        _buildLabeledField(
                                          'Description:',
                                          child: TextFormField(
                                            initialValue:
                                                salesItems[index].description,
                                            onChanged: (value) {
                                              setState(() {
                                                salesItems[index].description =
                                                    value;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 16),

                            // Totals Section
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  _buildTotalRow(
                                    'Subtotal:',
                                    '${_getCurrencyCode(controller)} ${subtotal.toStringAsFixed(2)}',
                                  ),
                                  _buildTotalRow(
                                    'VAT (${(selectedVatRate * 100).toInt()}%):',
                                    '${_getCurrencyCode(controller)} ${vatAmount.toStringAsFixed(2)}',
                                  ),
                                  _buildTotalRow(
                                    'Grand Total:',
                                    '${_getCurrencyCode(controller)} ${grandTotal.toStringAsFixed(2)}',
                                    isBold: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Payment Details Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section Header
                            const Text(
                              'Payment Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Payment Type Dropdown
                            _buildDropdown(
                              value: selectedPaymentTypeId,
                              items: paymentTypes,
                              label: 'Payment Type',
                              isRequired: true,
                              onChanged: (value) {
                                setState(() {
                                  selectedPaymentTypeId = value;
                                  // Set payment type string based on selection
                                  final paymentTypeItem = paymentTypes
                                      .firstWhere(
                                        (item) => item['id'] == value,
                                        orElse: () => {'Name': 'cash'},
                                      );
                                  selectedPaymentType = paymentTypeItem['Name'];
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            // Conditional fields based on payment type
                            if (selectedPaymentType != null &&
                                selectedPaymentType != 'cash')
                              _buildPaymentSpecificFields(isMobile, controller),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Submit Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Cancel Button
                          ElevatedButton.icon(
                            icon: const Icon(Icons.close),
                            label: const Text('Cancel'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),

                          const SizedBox(width: 16),

                          // Save Button
                          ElevatedButton.icon(
                            icon:
                                controller.isLoading
                                    ? const SizedBox(
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
                                    : const Icon(Icons.check),
                            label: Text(
                              controller.isLoading ? 'Saving...' : 'Save',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            onPressed:
                                controller.isLoading
                                    ? null
                                    : () => _saveExpense(controller),
                          ),
                        ],
                      ),
                    ],

                    // Document Upload Section (only shown after successful registration)
                    if (_isExpenseRegistered)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(top: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Upload Documents',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildFileUploadSection(),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade300,
                                    foregroundColor: Colors.black,
                                  ),
                                  child: const Text('Skip'),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: _uploadDocuments,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Upload Documents'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Get currency code helper
  String _getCurrencyCode(dynamic controller) {
    if (selectedCurrencyId != null && controller.currency != null) {
      final currency = controller.currency!.firstWhere(
        (c) => c['id'] == selectedCurrencyId,
        orElse: () => {'currency_code': 'AED'},
      );
      return currency['currency_code'] ?? currency['name'] ?? 'AED';
    }
    return 'AED';
  }

  // Save expense method
  Future<void> _saveExpense(ExpenseController controller) async {
    if (_formKey.currentState!.validate()) {
      if (selectedSupplierId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a supplier'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (selectedEmployeeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an employee'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (selectedCurrencyId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a currency'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      List<Map<String, dynamic>> expenseDetails =
          salesItems.map((item) {
            double vatAmount = item.total * (item.vatAmount ?? 0);

            return {
              "expense_category_id": item.expenseCategoryId,
              "expenseDate": DateFormat('yyyy-MM-dd').format(invoiceDate),
              "Description": item.description ?? '',
              "Total": item.total, // Send as number
              "VAT": item.vatAmount ?? 0, // Send as decimal (0.05 for 5%)
              "rowVatAmount": vatAmount, // Calculated VAT amount
              "rowSubTotal": item.total + vatAmount, // Total + VAT
            };
          }).toList();

      // Validate expense details
      if (expenseDetails.isEmpty ||
          expenseDetails.any(
            (detail) => detail["expense_category_id"] == null,
          )) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an expense category and enter amount'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      try {
        bool success = await controller.postExpenseRegistration(
          supplierId: selectedSupplierId,
          employeeId: selectedEmployeeId,
          expenseDate: DateFormat('yyyy-MM-dd').format(invoiceDate),
          referenceNumber: selectedReferenceNumber,
          currencyId: selectedCurrencyId,
          total: subtotal.toString(),
          subTotal: subtotal.toString(),
          totalVat: vatAmount.toString(),
          grandTotal: grandTotal.toString(),
          expenseDetail: jsonEncode(expenseDetails),
          paymentType: selectedPaymentType,
          bankId: selectedPaymentType == 'cash' ? 0 : selectedBankId,
          transferDate:
              selectedPaymentType == 'bank'
                  ? DateFormat('yyyy-MM-dd').format(transferDate)
                  : DateFormat('yyyy-MM-dd').format(DateTime.now()),
          chequeNumber: selectedPaymentType == 'cheque' ? chequeRefNumber : '',
        );

        if (success) {
          setState(() {
            _isExpenseRegistered = true;
            _savedExpenseId = controller.savedExpenseId;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Expense saved successfully! You can now upload documents.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to save expense: ${controller.errorMessage ?? 'Unknown error'}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving expense: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadDocuments() async {
    if (_selectedFile == null && _cameraImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file or capture an image to upload'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_savedExpenseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No expense ID found for document upload'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final controller = Provider.of<ExpenseController>(context, listen: false);

    try {
      MultipartFile multipartFile;
      File fileToUpload;
      String fileName;

      if (_cameraImage != null) {
        // Handle camera image
        fileToUpload = _cameraImage!;
        fileName =
            _selectedFile?.name ??
            'camera_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      } else {
        // Handle picked file
        fileToUpload = File(_selectedFile!.path!);
        fileName = _selectedFile!.name;
      }

      // Verify file exists and has content
      if (!await fileToUpload.exists()) {
        throw Exception('File does not exist: ${fileToUpload.path}');
      }

      final int fileSize = await fileToUpload.length();
      if (fileSize == 0) {
        throw Exception('File is empty');
      }

      print('Uploading file: ${fileToUpload.path}, Size: $fileSize bytes');

      // Create MultipartFile
      multipartFile = await MultipartFile.fromFile(
        fileToUpload.path,
        filename: fileName,
        contentType:
            _cameraImage != null
                ? MediaType('image', 'jpeg')
                : null, // Let dio determine content type for other files
      );

      print(
        'MultipartFile created: ${multipartFile.filename}, Length: ${multipartFile.length}',
      );

      bool success = await controller.postExpenseDocumentUpload(
        id: _savedExpenseId,
        files: [multipartFile],
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documents uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to upload documents: ${controller.errorMessage ?? 'Unknown error'}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Upload error details: $e');
      print('Stack trace: ${StackTrace.current}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading documents: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Future<void> _uploadDocuments() async {
  //   if (_selectedFile == null && _cameraImage == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Please select a file or capture an image to upload'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //     return;
  //   }
  //
  //   if (_savedExpenseId == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('No expense ID found for document upload'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //     return;
  //   }
  //
  //   final controller = Provider.of<ExpenseController>(context, listen: false);
  //
  //   try {
  //     MultipartFile multipartFile;
  //
  //     if (_cameraImage != null) {
  //       // Handle camera image
  //       final file = _cameraImage!;
  //       final fileName = 'expense_${DateTime.now().millisecondsSinceEpoch}.jpg';
  //       final fileStream = file.openRead();
  //       final length = await file.length();
  //
  //       multipartFile = MultipartFile(fileStream, length, filename: fileName);
  //     } else {
  //       // Handle picked file
  //       final file = File(_selectedFile!.path!);
  //       final fileName = _selectedFile!.name;
  //       final fileStream = file.openRead();
  //       final length = await file.length();
  //
  //       multipartFile = MultipartFile(fileStream, length, filename: fileName);
  //     }
  //
  //     bool success = await controller.postExpenseDocumentUpload(
  //       id: _savedExpenseId,
  //       files: [multipartFile],
  //     );
  //
  //     if (success) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Documents uploaded successfully!'),
  //           backgroundColor: Colors.green,
  //         ),
  //       );
  //       Navigator.pop(context);
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(
  //             'Failed to upload documents: ${controller.errorMessage ?? 'Unknown error'}',
  //           ),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Error uploading documents: $e'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select File(s):',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Camera button
            ElevatedButton(
              onPressed: _captureImageFromCamera,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade100,
                foregroundColor: Colors.blue.shade800,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt),
                  SizedBox(width: 8),
                  Text('Take Photo'),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // File picker button
            ElevatedButton(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles();
                if (result != null) {
                  setState(() {
                    _selectedFile = result.files.first;
                    _cameraImage =
                        null; // Clear any camera image when selecting a file
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.attach_file),
                  SizedBox(width: 8),
                  Text('Choose Files'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_selectedFile != null || _cameraImage != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selected file: ${_selectedFile?.name ?? 'Camera Image'}',
                style: const TextStyle(color: Colors.green),
              ),
              if (_cameraImage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: SizedBox(
                    height: 150,
                    child: Image.file(_cameraImage!),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  // Build Payment Specific Fields
  Widget _buildPaymentSpecificFields(bool isMobile, dynamic controller) {
    return Column(
      children: [
        // Bank Name - Required for Bank and Cheque
        if (selectedPaymentType == 'bank' || selectedPaymentType == 'cheque')
          _buildDropdown(
            value: controller.selectedBankTypeId,
            items: controller.banks ?? [],
            label: 'Bank Type',
            isRequired: true,
            onChanged: (value) {
              controller.setBankType(value);
              setState(() {
                selectedBankId = value;
              });
            },
          ),

        if (selectedPaymentType == 'bank' || selectedPaymentType == 'cheque')
          const SizedBox(height: 16),

        // Account Number - For Bank
        if (selectedPaymentType == 'bank')
          _buildLabeledField(
            'Account Number:',
            required: true,
            child: TextFormField(
              initialValue: accountNumber,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Enter Account Number',
              ),
              onChanged: (value) {
                setState(() {
                  accountNumber = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter account number';
                }
                return null;
              },
            ),
          ),

        if (selectedPaymentType == 'bank') const SizedBox(height: 16),

        // Transfer or Deposit Date - For Bank
        if (selectedPaymentType == 'bank')
          _buildLabeledField(
            'Transfer or Deposit Date:',
            required: true,
            child: GestureDetector(
              onTap: () => _selectDate(context, isTransferDate: true),
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: const InputDecoration(
                    hintText: 'Select Transfer Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  controller: TextEditingController(
                    text: DateFormat('dd/MM/yyyy').format(transferDate),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select transfer date';
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),

        if (selectedPaymentType == 'Bank') const SizedBox(height: 16),

        // Cheque or Reference Number - For Cheque
        if (selectedPaymentType == 'cheque')
          _buildLabeledField(
            'Cheque or Ref. Number:',
            required: true,
            child: TextFormField(
              initialValue: chequeRefNumber,
              decoration: const InputDecoration(
                hintText: 'Enter Cheque or Reference Number',
              ),
              onChanged: (value) {
                setState(() {
                  chequeRefNumber = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter cheque or reference number';
                }
                return null;
              },
            ),
          ),

        if (selectedPaymentType == 'cheque') const SizedBox(height: 16),
      ],
    );
  }

  // Function to select date
  Future<void> _selectDate(
    BuildContext context, {
    bool isTransferDate = false,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isTransferDate ? transferDate : invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isTransferDate) {
          transferDate = picked;
        } else {
          invoiceDate = picked;
        }
      });
    }
  }

  // Function to calculate grand total from manual subtotal entry
  void _calculateGrandTotal() {
    setState(() {
      // Calculate VAT amount from manual subtotal
      vatAmount = subtotal * selectedVatRate;

      // Calculate grand total
      grandTotal = subtotal + vatAmount;

      // Update balance amount
      _calculateRoundOffAndBalance();
    });
  }

  // Function to update totals (keep for compatibility)
  void _updateTotals() {
    // This method is kept for compatibility but grand total calculation
    // is now handled by _calculateGrandTotal() when subtotal is manually entered
    _calculateRoundOffAndBalance();
  }

  // Function to calculate Round Off and Balance
  void _calculateRoundOffAndBalance() {
    setState(() {
      // Calculate roundoff (to make the total a nice round number)
      double rawTotal = grandTotal;
      double roundedTotal = (rawTotal / 1).ceil().toDouble();
      roundOff = roundedTotal - rawTotal;

      // Round to 2 decimal places for display
      roundOff = double.parse(roundOff.toStringAsFixed(2));

      // Calculate balance (grand total with roundoff - paid amount)
      balanceAmount = (grandTotal + roundOff) - paidAmount;
      balanceAmount = double.parse(balanceAmount.toStringAsFixed(2));
    });
  }

  Widget _buildDropdown({
    required int? value,
    required List<Map<String, dynamic>> items,
    required String label,
    bool isRequired = false,
    required ValueChanged<int?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
            children:
                isRequired
                    ? [
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: Color(0xFFEF4444)),
                      ),
                    ]
                    : [],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: value,
          style: const TextStyle(fontSize: 16, color: Color(0xFF1F2937)),
          decoration: InputDecoration(
            hintText: 'Select ',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 16,
            ),
          ),
          items:
              items.map<DropdownMenuItem<int>>((item) {
                return DropdownMenuItem<int>(
                  value: item['id'],
                  child: Text(
                    item['Name'] ?? '',
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
          onChanged: onChanged,
          validator:
              isRequired
                  ? (value) {
                    if (value == null) {
                      return '$label is required';
                    }
                    return null;
                  }
                  : null,
        ),
      ],
    );
  }

  Widget _buildLabeledField(
    String label, {
    required Widget child,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  // Helper for building table header cells
  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Helper for building total rows
  Widget _buildTotalRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// Model class for Sales Item
class SalesItem {
  int? expenseCategoryId;
  String? product = 'Product';
  String? unit = 'UNIT';
  String description = '';
  int quantity = 0;
  double price = 0.0;
  double total = 0.0;
  double discount = 0.0;
  double vatAmount = 0.0;
  double subtotal = 0.0;

  SalesItem({
    this.expenseCategoryId,
    this.product,
    this.unit,
    this.description = '',
    this.quantity = 0,
    this.price = 0.0,
    this.total = 0.0,
    this.discount = 0.0,
    this.vatAmount = 0.0,
    this.subtotal = 0.0,
  });
}
