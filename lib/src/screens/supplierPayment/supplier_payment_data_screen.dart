import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/supplier_payment_controller.dart';
import 'package:sample/src/screens/supplierPayment/utils/dialog_helpers.dart';
import 'package:sample/src/screens/supplierPayment/utils/payment_helpers.dart';
import 'package:sample/src/screens/supplierPayment/utils/validation_mixin.dart';
import 'package:sample/src/screens/supplierPayment/widgets/invoice_widget.dart';
import 'package:sample/src/util/number_to_words_convertor.dart';
import 'package:sample/src/util/snack.dart';

import 'widgets/file_upload_widget.dart';
// Import refactored components
import 'widgets/form_field_widget.dart';

class SupplierPaymentDataScreen extends StatefulWidget {
  const SupplierPaymentDataScreen({super.key});

  @override
  State<SupplierPaymentDataScreen> createState() =>
      _SupplierPaymentDataScreenState();
}

class _SupplierPaymentDataScreenState extends State<SupplierPaymentDataScreen>
    with ValidationMixin {
  bool _selectAll = false;
  final Set<int> _selectedInvoices = {};

  // Form controllers
  final TextEditingController _pvNumberController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _totalPayableController = TextEditingController();
  final TextEditingController _totalPayingController = TextEditingController();
  final TextEditingController _amountInWordsController =
      TextEditingController();
  final TextEditingController _paidByController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();

  String? _selectedPaymentType;
  DateTime _selectedDate = DateTime.now();
  final List<XFile> _selectedFiles = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> _paymentTypes = ['Cash', 'Cheque', 'Bank Transfer'];

  // Validation flags
  bool _currencyTouched = false;
  bool _supplierTouched = false;
  bool _paymentTypeTouched = false;
  bool _bankTouched = false;
  bool _accountNumberTouched = false;
  bool _totalPayingTouched = false;
  bool _paidByTouched = false;

  Timer? _debounceTimer;
  final Duration _debounceDuration = const Duration(milliseconds: 800);
  bool _isPvNumberUserModified = false;

  // ValidationMixin required getters
  @override
  bool get currencyTouched => _currencyTouched;
  @override
  bool get supplierTouched => _supplierTouched;
  @override
  bool get paymentTypeTouched => _paymentTypeTouched;
  @override
  bool get bankTouched => _bankTouched;
  @override
  bool get accountNumberTouched => _accountNumberTouched;
  @override
  bool get totalPayingTouched => _totalPayingTouched;
  @override
  bool get paidByTouched => _paidByTouched;
  @override
  String? get selectedPaymentType => _selectedPaymentType;
  @override
  String get accountNumber => _accountNumberController.text;
  @override
  String get totalPaying => _totalPayingController.text;
  @override
  String get paidBy => _paidByController.text;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<SupplierPaymentController>();
      controller.getSupplierAdvanceBaseData();
    });

    _pvNumberController.addListener(_onPvNumberChanged);
    _totalPayingController.addListener(
      () => _onAmountChanged(_totalPayingController.text),
    );
  }

  @override
  void dispose() {
    final controller = context.read<SupplierPaymentController>();
    controller.clearSupplierPaymentDetail();
    controller.clearSelections();
    controller.clearInvoiceDistributionData();

    _debounceTimer?.cancel();
    _pvNumberController.removeListener(_onPvNumberChanged);

    _pvNumberController.dispose();
    _descriptionController.dispose();
    _totalPayableController.dispose();
    _totalPayingController.dispose();
    _amountInWordsController.dispose();
    _paidByController.dispose();
    _accountNumberController.dispose();
    _selectedInvoices.clear();
    super.dispose();
  }

  void _onPvNumberChanged() {
    if (_isPvNumberUserModified) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(_debounceDuration, _validateReceiptNumber);
    }
  }

  void _onPvNumberManualChange() {
    _isPvNumberUserModified = true;
    _onPvNumberChanged();
  }

  Future<void> _validateReceiptNumber() async {
    final receiptNumber = _pvNumberController.text.trim();
    if (receiptNumber.isNotEmpty) {
      final controller = Provider.of<SupplierPaymentController>(
        context,
        listen: false,
      );
      await controller.checkSupplierpaymentReferenceExist(receiptNumber);
    }
  }

  void _onAmountChanged(String value) {
    if (value.isNotEmpty) {
      double? amount = double.tryParse(value);
      if (amount != null) {
        String amountInWords = convertAmountToWords(amount);
        _amountInWordsController.text = amountInWords;
      }
    } else {
      _amountInWordsController.text = '';
    }
  }

  void _calculateTotals(SupplierPaymentController controller) {
    double totalPayable = 0.0;
    final invoices = controller.supplierInvoicesForDistribution;

    if (invoices != null) {
      for (int index in _selectedInvoices) {
        if (index < invoices.length) {
          totalPayable +=
              double.tryParse(invoices[index].remainingBalance) ?? 0.0;
        }
      }
    }

    _totalPayableController.text = totalPayable.toStringAsFixed(2);
  }

  void _toggleSelectAll(SupplierPaymentController controller) {
    setState(() {
      _selectAll = !_selectAll;
      _selectedInvoices.clear();
      if (_selectAll && controller.supplierInvoicesForDistribution != null) {
        for (
          var i = 0;
          i < controller.supplierInvoicesForDistribution!.length;
          i++
        ) {
          _selectedInvoices.add(i);
        }
      }
      _calculateTotals(controller);
    });
  }

  void _toggleInvoiceSelection(
    int index,
    SupplierPaymentController controller,
  ) {
    setState(() {
      if (_selectedInvoices.contains(index)) {
        _selectedInvoices.remove(index);
        _selectAll = false;
      } else {
        _selectedInvoices.add(index);
        if (_selectedInvoices.length ==
            controller.supplierInvoicesForDistribution?.length) {
          _selectAll = true;
        }
      }
      _calculateTotals(controller);
    });
  }

  Future<void> _pickFiles() async {
    final List<XFile> images = await _picker.pickMultiImage();
    setState(() {
      _selectedFiles.addAll(images);
    });
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await DialogHelpers.showCustomDatePicker(
      context: context,
      initialDate: _selectedDate,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildReceiptValidationWidget() {
    return Consumer<SupplierPaymentController>(
      builder: (context, controller, child) {
        if (!_isPvNumberUserModified) {
          return const SizedBox.shrink();
        }

        if (controller.isCheckingReceipt) {
          return Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Checking PV number...',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ],
            ),
          );
        }

        if (controller.receiptCheckMessage != null) {
          final isError = controller.receiptExists == true;
          return Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Icon(
                  isError ? Icons.error : Icons.check_circle,
                  size: 16,
                  color: isError ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.receiptCheckMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isError ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final controller = context.read<SupplierPaymentController>();
        controller.clearInvoiceDistributionData();
        controller.clearSelections();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Add Supplier Payment'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Consumer<SupplierPaymentController>(
          builder: (context, controller, child) {
            if (controller.isLoading && controller.supplierName == null) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF26A69A)),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSelectionCard(controller),
                          const SizedBox(height: 16),
                          _buildInvoiceSection(controller),
                          const SizedBox(height: 16),
                          _buildPaymentDetailsCard(controller),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildBottomActionBar(controller),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectionCard(SupplierPaymentController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomDropdownField(
            label: 'Currency',
            value: controller.selectedCurrencyId,
            items: controller.currencyName ?? [],
            onChanged: (value) {
              setState(() => _currencyTouched = true);
              controller.setCurrencyName(value);
              if (controller.selectedSupplierId != null && value != null) {
                controller.getSupplierPaymentInvoicesForDistribution(
                  controller.selectedSupplierId!,
                  value,
                );
                setState(() {
                  _selectedInvoices.clear();
                  _selectAll = false;
                  _totalPayableController.clear();
                  _totalPayingController.clear();
                });
              }
            },
            displayKey: 'Name',
            valueKey: 'id',
            errorText: validateCurrency(controller),
          ),
          const SizedBox(height: 16),
          CustomDropdownField(
            label: 'Supplier',
            value: controller.selectedSupplierId,
            items: controller.supplierName ?? [],
            onChanged: (value) {
              setState(() => _supplierTouched = true);
              controller.setSupplierName(value);
              if (value != null && controller.selectedCurrencyId != null) {
                controller.getSupplierPaymentInvoicesForDistribution(
                  value,
                  controller.selectedCurrencyId!,
                );
                setState(() {
                  _selectedInvoices.clear();
                  _selectAll = false;
                  _totalPayableController.clear();
                  _totalPayingController.clear();
                });
              }
            },
            displayKey: 'Name',
            valueKey: 'id',
            errorText: validateSupplier(controller),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceSection(SupplierPaymentController controller) {
    if (controller.isDistributionLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: Column(
            children: [
              CircularProgressIndicator(color: Color(0xFF26A69A)),
              SizedBox(height: 16),
              Text('Loading invoices...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (controller.distributionErrorMessage != null) {
      return InvoiceEmptyState(
        title: 'Failed to load invoices',
        subtitle: controller.distributionErrorMessage!,
        icon: Icons.error_outline,
      );
    }

    if (controller.supplierInvoicesForDistribution == null ||
        controller.supplierInvoicesForDistribution!.isEmpty) {
      return const InvoiceEmptyState(
        title: 'No invoices available',
        subtitle: 'Select currency and supplier to view invoices',
      );
    }

    return _buildInvoiceList(controller);
  }

  Widget _buildInvoiceList(SupplierPaymentController controller) {
    final invoices = controller.supplierInvoicesForDistribution!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectAllInvoicesHeader(
          selectAll: _selectAll,
          onToggle: () => _toggleSelectAll(controller),
          selectedCount: _selectedInvoices.length,
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: invoices.length,
          itemBuilder: (context, index) {
            final invoice = invoices[index];
            final isSelected = _selectedInvoices.contains(index);

            return InvoiceListItem(
              invoice: invoice,
              isSelected: isSelected,
              onTap: () => _toggleInvoiceSelection(index, controller),
              index: index,
            );
          },
        ),
      ],
    );
  }

  Widget _buildPaymentDetailsCard(SupplierPaymentController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          CustomDropdownField(
            label: 'Payment Type',
            value: _selectedPaymentType,
            items:
                _paymentTypes
                    .map((type) => {'id': type, 'Name': type})
                    .toList(),
            onChanged: (value) {
              setState(() {
                _paymentTypeTouched = true;
                _selectedPaymentType = value as String?;
                if (_selectedPaymentType == 'Cash') {
                  controller.setBankName(null);
                  _accountNumberController.clear();
                  _bankTouched = false;
                  _accountNumberTouched = false;
                }
              });
            },
            displayKey: 'Name',
            valueKey: 'id',
            isString: true,
            errorText: validatePaymentType(),
          ),
          if (PaymentHelpers.requiresBankDetails(_selectedPaymentType)) ...[
            const SizedBox(height: 16),
            CustomDropdownField(
              label: 'Bank',
              value: controller.selectedBankId,
              items: controller.bankName ?? [],
              onChanged: (value) {
                setState(() => _bankTouched = true);
                controller.setBankName(value);
                if (controller.selectedBankAccountNumber != null) {
                  _accountNumberController.text =
                      controller.selectedBankAccountNumber!;
                } else {
                  _accountNumberController.clear();
                }
              },
              displayKey: 'Name',
              valueKey: 'id',
              isRequired: true,
              errorText: validateBank(controller),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Account Number',
              controller: _accountNumberController,
              keyboardType: TextInputType.text,
              hintText: 'Enter account number',
              isRequired: true,
              onChanged: (value) {
                setState(() => _accountNumberTouched = true);
              },
              errorText: validateAccountNumber(),
            ),
          ],
          const SizedBox(height: 16),
          CustomDateField(
            label: 'Payment Date',
            date: _selectedDate,
            onTap: () => _selectDate(context),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'PV Number',
                controller: _pvNumberController,
                hintText: 'PV#0001',
                onChanged: (value) => _onPvNumberManualChange(),
              ),
              _buildReceiptValidationWidget(),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Description',
            controller: _descriptionController,
            maxLines: 3,
            hintText: 'Enter description',
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Total Payable',
            controller: _totalPayableController,
            keyboardType: TextInputType.number,
            enabled: false,
            hintText: '0.00',
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Paying Amount',
            controller: _totalPayingController,
            keyboardType: TextInputType.number,
            hintText: '0.00',
            isRequired: true,
            onChanged: (value) {
              setState(() => _totalPayingTouched = true);
            },
            errorText: validateTotalPaying(),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Amount In Words',
            controller: _amountInWordsController,
            enabled: false,
            hintText: 'Amount in words',
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Paid By',
            controller: _paidByController,
            hintText: 'Enter name',
            isRequired: true,
            onChanged: (value) {
              setState(() => _paidByTouched = true);
            },
            errorText: validatePaidBy(),
          ),
          const SizedBox(height: 16),
          FileUploadSection(
            selectedFiles: _selectedFiles,
            onPickFiles: _pickFiles,
            onRemoveFile: _removeFile,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(SupplierPaymentController controller) {
    final selectedAmount = double.tryParse(_totalPayableController.text) ?? 0.0;
    final hasInvoices =
        controller.supplierInvoicesForDistribution != null &&
        controller.supplierInvoicesForDistribution!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedInvoices.isNotEmpty && hasInvoices)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Invoices',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${_selectedInvoices.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Total Payable',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            selectedAmount.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF26A69A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _handleSave(controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  void _handleSave(SupplierPaymentController controller) async {
    if (controller.receiptExists == true) {
      showErrorSnack(
        'PV number already exists. Please use a different number.',
      );
      return;
    }

    setState(() {
      _currencyTouched = true;
      _supplierTouched = true;
      _paymentTypeTouched = true;
      _bankTouched = true;
      _accountNumberTouched = true;
      _totalPayingTouched = true;
      _paidByTouched = true;
    });

    if (!validateAllRequiredFields(controller)) {
      _showValidationErrors(controller);
      return;
    }

    final payingAmount = double.tryParse(_totalPayingController.text) ?? 0.0;
    final payableAmount = double.tryParse(_totalPayableController.text) ?? 0.0;

    final amountError = PaymentHelpers.validatePayingAmount(
      payingAmount: payingAmount,
      payableAmount: payableAmount,
      hasSelectedInvoices: _selectedInvoices.isNotEmpty,
    );

    if (amountError != null) {
      showErrorSnack(amountError);
      return;
    }

    final paymentDetails = _preparePaymentDetails(controller);

    final confirmed = await DialogHelpers.showPaymentConfirmation(
      context: context,
      paymentDetails: paymentDetails,
      selectedInvoicesCount:
          _selectedInvoices.isNotEmpty ? _selectedInvoices.length : null,
    );

    if (confirmed) {
      await _processSave(controller);
    }
  }

  void _showValidationErrors(SupplierPaymentController controller) {
    if (controller.selectedCurrencyId == null) {
      showErrorSnack('Please select a currency');
    } else if (controller.selectedSupplierId == null) {
      showErrorSnack('Please select a supplier');
    } else if (_selectedPaymentType == null) {
      showErrorSnack('Please select payment type');
    } else if (_totalPayingController.text.isEmpty) {
      showErrorSnack('Please enter total paying amount');
    } else if (_paidByController.text.isEmpty) {
      showErrorSnack('Please enter paid by name');
    } else if (PaymentHelpers.requiresBankDetails(_selectedPaymentType)) {
      if (controller.selectedBankId == null) {
        showErrorSnack('Please select a bank');
      } else if (_accountNumberController.text.isEmpty) {
        showErrorSnack('Please enter account number');
      }
    }
  }

  Map<String, String> _preparePaymentDetails(
    SupplierPaymentController controller,
  ) {
    final details = <String, String>{
      'Payment Amount:': _totalPayingController.text,
      'Payment Type:': _selectedPaymentType ?? '',
    };

    if (PaymentHelpers.requiresBankDetails(_selectedPaymentType)) {
      final bankName =
          controller.bankName?.firstWhere(
            (bank) => bank['id'] == controller.selectedBankId,
            orElse: () => {'Name': 'N/A'},
          )['Name'] ??
          'N/A';

      details['Bank:'] = bankName;
      details['Account Number:'] = _accountNumberController.text;
    }

    details['PV Number:'] = _pvNumberController.text;
    details['Paid By:'] = _paidByController.text;

    return details;
  }

  Future<void> _processSave(SupplierPaymentController controller) async {
    DialogHelpers.showLoadingDialog(context);

    try {
      List<MultipartFile>? paymentFiles;
      if (_selectedFiles.isNotEmpty) {
        paymentFiles = [];
        for (var file in _selectedFiles) {
          final bytes = await file.readAsBytes();
          paymentFiles.add(MultipartFile.fromBytes(bytes, filename: file.name));
        }
      }

      final success = await controller.postSupplierPaymentRegistration(
        supplierId: controller.selectedSupplierId!,
        referenceNumber: _pvNumberController.text,
        paymentType: _selectedPaymentType!,
        bankId: controller.selectedBankId ?? 0,
        accountNumber: _accountNumberController.text,
        transferDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        totalAmount: _totalPayableController.text,
        paidAmount: _totalPayingController.text,
        amountInWords: _amountInWordsController.text,
        currencyId: controller.selectedCurrencyId!,
        receiverName: _paidByController.text,
        description: _descriptionController.text,
        paymentFiles: paymentFiles,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text('Payment saved successfully')),
                ],
              ),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        showErrorSnack('Failed to save payment: ${e.toString()}');
      }
    }
  }
}
