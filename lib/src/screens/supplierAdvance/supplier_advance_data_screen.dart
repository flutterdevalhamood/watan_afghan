import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/supplier_advance_controller.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';
import 'package:sample/src/util/snack.dart';

class SupplierAdvanceDataScreen extends StatefulWidget {
  const SupplierAdvanceDataScreen({super.key});

  @override
  State<SupplierAdvanceDataScreen> createState() =>
      _SupplierAdvanceDataScreenState();
}

class _SupplierAdvanceDataScreenState extends State<SupplierAdvanceDataScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final _transferDateController = TextEditingController();
  final _amountController = TextEditingController();
  final _sumOfController = TextEditingController();
  final _receivedByController = TextEditingController();
  final _noteController = TextEditingController();
  final _pvNumberController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _chequeNumberController = TextEditingController();

  // Dropdown values
  int? selectedSupplierId;
  String? selectedPaymentType;
  int? selectedCurrencyId;
  int? selectedBankId;

  // File handling
  List<File> selectedFiles = [];
  List<String> fileNames = [];

  // Payment types
  final List<String> paymentTypes = ['Cash', 'Bank Transfer', 'Cheque'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBaseData();
    });
  }

  void _loadBaseData() {
    final controller = Provider.of<SupplierAdvanceController>(
      context,
      listen: false,
    );
    controller.getSupplierAdvanceBaseData().then((_) {
      _prefillPvNumber();
    });
  }

  void _prefillPvNumber() {
    final controller = Provider.of<SupplierAdvanceController>(
      context,
      listen: false,
    );
    if (controller.nextPaymentVoucher != null) {
      final pvData = controller.nextPaymentVoucher;
      _pvNumberController.text = pvData.toString() ?? '';
      print('pvdata $pvData');
    }
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result != null) {
        setState(() {
          selectedFiles = result.paths.map((path) => File(path!)).toList();
          fileNames = result.files.map((file) => file.name).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking files: $e')));
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _transferDateController.text =
            "${picked.year}/${picked.month}/${picked.day}/";
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = Provider.of<SupplierAdvanceController>(
      context,
      listen: false,
    );

    // Convert files to MultipartFile
    List<MultipartFile>? multipartFiles;
    if (selectedFiles.isNotEmpty) {
      multipartFiles = [];
      for (File file in selectedFiles) {
        multipartFiles.add(await MultipartFile.fromFile(file.path));
      }
    }

    final success = await controller.postSupplierAdvanceRegistration(
      supplierId: selectedSupplierId,
      receiptNumber: _pvNumberController.text.trim(),
      paymentType: selectedPaymentType,
      bankId: selectedBankId,
      accountNumber: _accountNumberController.text.trim(),
      chequeNumber: _chequeNumberController.text.trim(),
      transferDate: _transferDateController.text.trim(),
      amount: _amountController.text.trim(),
      currencyId: selectedCurrencyId,
      sumOf: _sumOfController.text.trim(),
      receiverName: _receivedByController.text.trim(),
      description: _noteController.text.trim(),
      supplierAdvanceImage: multipartFiles,
    );

    if (success) {
      showSuccessSnack('Supplier advance saved successfully!');
      NavigationService().pushNavigation(
        Screenroutes.supplierAdvanceListScreen,
      );
      _clearForm();
    } else {
      controller.errorMessage ??
          showErrorSnack('Failed to save supplier advance');
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    setState(() {
      selectedSupplierId = null;
      selectedPaymentType = null;
      selectedCurrencyId = null;
      selectedBankId = null;
      selectedFiles.clear();
      fileNames.clear();
    });

    _transferDateController.clear();
    _amountController.clear();
    _sumOfController.clear();
    _receivedByController.clear();
    _noteController.clear();
    _pvNumberController.clear();
    _accountNumberController.clear();
    _chequeNumberController.clear();

    _prefillPvNumber();
  }

  @override
  void dispose() {
    _transferDateController.dispose();
    _amountController.dispose();
    _sumOfController.dispose();
    _receivedByController.dispose();
    _noteController.dispose();
    _pvNumberController.dispose();
    _accountNumberController.dispose();
    _chequeNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Advance'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<SupplierAdvanceController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Supplier Dropdown
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Supplier Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            value: selectedSupplierId,
                            decoration: const InputDecoration(
                              labelText: 'Supplier *',
                              border: OutlineInputBorder(),
                            ),
                            items:
                                controller.supplierName?.map((supplier) {
                                  return DropdownMenuItem<int>(
                                    value: supplier['id'],
                                    child: Text(supplier['Name'] ?? ''),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedSupplierId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a supplier';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Payment Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // PV Number (Pre-filled)
                          TextFormField(
                            controller: _pvNumberController,
                            decoration: const InputDecoration(
                              labelText: 'PV Number',
                              border: OutlineInputBorder(),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Payment Type Dropdown
                          DropdownButtonFormField<String>(
                            value: selectedPaymentType,
                            decoration: const InputDecoration(
                              labelText: 'Payment Type *',
                              border: OutlineInputBorder(),
                            ),
                            items:
                                paymentTypes.map((type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedPaymentType = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select payment type';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Bank Dropdown (shown for Bank Transfer and Cheque)
                          if (selectedPaymentType == 'Bank Transfer' ||
                              selectedPaymentType == 'Cheque')
                            Column(
                              children: [
                                DropdownButtonFormField<int>(
                                  value: selectedBankId,
                                  decoration: const InputDecoration(
                                    labelText: 'Bank *',
                                    border: OutlineInputBorder(),
                                  ),
                                  items:
                                      controller.bankName?.map((bank) {
                                        return DropdownMenuItem<int>(
                                          value: bank['id'],
                                          child: Text(bank['Name'] ?? ''),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedBankId = value;
                                    });
                                  },
                                  validator: (value) {
                                    if ((selectedPaymentType ==
                                                'Bank Transfer' ||
                                            selectedPaymentType == 'Cheque') &&
                                        value == null) {
                                      return 'Please select a bank';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),

                          // Account Number (for Bank Transfer)
                          if (selectedPaymentType == 'Bank Transfer')
                            Column(
                              children: [
                                TextFormField(
                                  controller: _accountNumberController,
                                  decoration: const InputDecoration(
                                    labelText: 'Account Number',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),

                          // Cheque Number (for Cheque)
                          if (selectedPaymentType == 'Cheque')
                            Column(
                              children: [
                                TextFormField(
                                  controller: _chequeNumberController,
                                  decoration: const InputDecoration(
                                    labelText: 'Cheque Number',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),

                          // Currency Dropdown
                          DropdownButtonFormField<int>(
                            value: selectedCurrencyId,
                            decoration: const InputDecoration(
                              labelText: 'Currency *',
                              border: OutlineInputBorder(),
                            ),
                            items:
                                controller.currencyName?.map((currency) {
                                  return DropdownMenuItem<int>(
                                    value: currency['id'],
                                    child: Text(currency['Name'] ?? ''),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedCurrencyId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select currency';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Transaction Details
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Transaction Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Transfer/Deposit Date
                          TextFormField(
                            controller: _transferDateController,
                            decoration: InputDecoration(
                              labelText: 'Transfer/Deposit Date *',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: _selectDate,
                              ),
                            ),
                            readOnly: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select transfer/deposit date';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Amount
                          TextFormField(
                            controller: _amountController,
                            decoration: const InputDecoration(
                              labelText: 'Amount *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter amount';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter valid amount';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Sum Of
                          TextFormField(
                            controller: _sumOfController,
                            decoration: const InputDecoration(
                              labelText: 'Sum Of',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),

                          const SizedBox(height: 16),

                          // Received By
                          TextFormField(
                            controller: _receivedByController,
                            decoration: const InputDecoration(
                              labelText: 'Received By *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter receiver name';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Note
                          TextFormField(
                            controller: _noteController,
                            decoration: const InputDecoration(
                              labelText: 'Note',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // File Upload Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Attachments',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          ElevatedButton.icon(
                            onPressed: _pickFiles,
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Choose PV File(s)'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),

                          if (fileNames.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Selected Files:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ...fileNames
                                .map(
                                  (fileName) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.attach_file, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(fileName)),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              int index = fileNames.indexOf(
                                                fileName,
                                              );
                                              fileNames.removeAt(index);
                                              selectedFiles.removeAt(index);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: controller.isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 50),
                          ),
                          child:
                              controller.isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : const Text(
                                    'Save',
                                    style: TextStyle(fontSize: 16),
                                  ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _clearForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 50),
                          ),
                          child: const Text(
                            'Clear',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
