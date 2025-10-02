import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/supplier_payment_controller.dart';
import 'package:sample/src/util/number_to_words_convertor.dart';
import 'package:sample/src/util/snack.dart';

class SupplierPaymentDataScreen extends StatefulWidget {
  const SupplierPaymentDataScreen({super.key});

  @override
  State<SupplierPaymentDataScreen> createState() =>
      _SupplierPaymentDataScreenState();
}

class _SupplierPaymentDataScreenState extends State<SupplierPaymentDataScreen> {
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

    _pvNumberController.addListener(_onPvNumberChanged);
  }

  @override
  void dispose() {
    // Clear controller data when leaving the screen
    final controller = context.read<SupplierPaymentController>();
    controller.clearSupplierPaymentDetail();
    controller.clearSelections();

    _debounceTimer?.cancel();
    _pvNumberController.removeListener(_onPvNumberChanged);

    // Clear invoice distribution data
    controller.clearInvoiceDistributionData();

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

  void _prefillPvNumber() {
    final controller = Provider.of<SupplierPaymentController>(
      context,
      listen: false,
    );
    if (controller.nextPaymentVoucher != null) {
      final pvData = controller.nextPaymentVoucher;
      _isPvNumberUserModified = false; // Mark as system-generated
      _pvNumberController.text = pvData.toString() ?? '';
      print('pvdata $pvData');
    }
  }

  void _onPvNumberChanged() {
    if (_isPvNumberUserModified) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(_debounceDuration, () {
        _validateReceiptNumber();
      });
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF26A69A),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String? _validateCurrency(SupplierPaymentController controller) {
    if (_currencyTouched && controller.selectedCurrencyId == null) {
      return 'Please select a currency';
    }
    return null;
  }

  String? _validateSupplier(SupplierPaymentController controller) {
    if (_supplierTouched && controller.selectedSupplierId == null) {
      return 'Please select a supplier';
    }
    return null;
  }

  String? _validatePaymentType() {
    if (_paymentTypeTouched && _selectedPaymentType == null) {
      return 'Please select payment type';
    }
    return null;
  }

  String? _validateBank(SupplierPaymentController controller) {
    if ((_selectedPaymentType == 'Cheque' ||
            _selectedPaymentType == 'Bank Transfer') &&
        _bankTouched &&
        controller.selectedBankId == null) {
      return 'Please select a bank';
    }
    return null;
  }

  String? _validateAccountNumber() {
    if ((_selectedPaymentType == 'Cheque' ||
            _selectedPaymentType == 'Bank Transfer') &&
        _accountNumberTouched &&
        _accountNumberController.text.isEmpty) {
      return 'Please enter account number';
    }
    return null;
  }

  String? _validateTotalPaying() {
    if (_totalPayingTouched && _totalPayingController.text.isEmpty) {
      return 'Please enter paying amount';
    }
    if (_totalPayingTouched) {
      final amount = double.tryParse(_totalPayingController.text);
      if (amount == null || amount <= 0) {
        return 'Amount must be greater than zero';
      }
    }
    return null;
  }

  String? _validatePaidBy() {
    if (_paidByTouched && _paidByController.text.isEmpty) {
      return 'Please enter paid by name';
    }
    return null;
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
        // Clear data when back button is pressed
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
          _buildDropdownField(
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
            errorText: _validateCurrency(controller),
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
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
            errorText: _validateSupplier(controller),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceSection(SupplierPaymentController controller) {
    if (controller.isDistributionLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            children: const [
              CircularProgressIndicator(color: Color(0xFF26A69A)),
              SizedBox(height: 16),
              Text('Loading invoices...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (controller.distributionErrorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Failed to load invoices',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                controller.distributionErrorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (controller.supplierInvoicesForDistribution == null ||
        controller.supplierInvoicesForDistribution!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No invoices available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select currency and supplier to view invoices',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return _buildInvoiceList(controller);
  }

  Widget _buildInvoiceList(SupplierPaymentController controller) {
    final invoices = controller.supplierInvoicesForDistribution!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Checkbox(
                value: _selectAll,
                onChanged: (_) => _toggleSelectAll(controller),
                activeColor: Theme.of(context).primaryColor,
              ),
              const Text(
                'Select All Invoices',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (_selectedInvoices.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedInvoices.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: invoices.length,
          itemBuilder: (context, index) {
            final invoice = invoices[index];
            final isSelected = _selectedInvoices.contains(index);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[200]!,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _toggleInvoiceSelection(index, controller),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isSelected,
                        onChanged:
                            (_) => _toggleInvoiceSelection(index, controller),
                        activeColor: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Invoice #${invoice.invoiceNumber}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatAmount(invoice.totalAmount.toString()),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF26A69A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildInfoChip(
                                  'Paid',
                                  invoice.totalAmount,
                                  Colors.green,
                                ),
                                const SizedBox(width: 8),
                                _buildInfoChip(
                                  'Balance',
                                  invoice.remainingBalance,
                                  Colors.orange,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_month,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(invoice.purchaseDate),
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
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoChip(String label, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: ${_formatAmount(amount)}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
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
          _buildDropdownField(
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
            errorText: _validatePaymentType(),
          ),
          if (_selectedPaymentType == 'Cheque' ||
              _selectedPaymentType == 'Bank Transfer') ...[
            const SizedBox(height: 16),
            _buildDropdownField(
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
              errorText: _validateBank(controller),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Account Number',
              controller: _accountNumberController,
              keyboardType: TextInputType.text,
              hintText: 'Enter account number',
              isRequired: true,
              onChanged: (value) {
                setState(() => _accountNumberTouched = true);
              },
              errorText: _validateAccountNumber(),
            ),
          ],
          const SizedBox(height: 16),
          // CHANGED: Payment Date in separate row instead of column
          _buildDateField(
            label: 'Payment Date',
            date: _selectedDate,
            onTap: () => _selectDate(context),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                label: 'PV Number',
                controller: _pvNumberController,
                hintText: 'PV#0001',
                onChanged: (value) => _onPvNumberManualChange(),
              ),
              _buildReceiptValidationWidget(),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Description',
            controller: _descriptionController,
            maxLines: 3,
            hintText: 'Enter description',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Total Payable',
            controller: _totalPayableController,
            keyboardType: TextInputType.number,
            enabled: false,
            hintText: '0.00',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Paying Amount',
            controller: _totalPayingController,
            keyboardType: TextInputType.number,
            hintText: '0.00',
            isRequired: true,
            onChanged: (value) {
              setState(() => _totalPayingTouched = true);
            },
            errorText: _validateTotalPaying(),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Amount In Words',
            controller: _amountInWordsController,
            enabled: false,
            hintText: 'Amount in words',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Paid By',
            controller: _paidByController,
            hintText: 'Enter name',
            isRequired: true,
            onChanged: (value) {
              setState(() => _paidByTouched = true);
            },
            errorText: _validatePaidBy(),
          ),
          const SizedBox(height: 16),
          _buildFileUploadSection(),
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

  Widget _buildDropdownField({
    required String label,
    required dynamic value,
    required List<Map<String, dynamic>> items,
    required Function(dynamic) onChanged,
    required String displayKey,
    required String valueKey,
    bool isString = false,
    bool isRequired = true,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: errorText != null ? Colors.red : Colors.grey[300]!,
              width: errorText != null ? 2 : 1,
            ),
          ),
          child: DropdownButtonFormField<dynamic>(
            value: value,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: InputBorder.none,
            ),
            hint: Text(
              'Select $label',
              style: const TextStyle(color: Colors.grey),
            ),
            isExpanded: true,
            items:
                items.map((item) {
                  return DropdownMenuItem<dynamic>(
                    value:
                        isString
                            ? item[valueKey] as String
                            : item[valueKey] as int,
                    child: Text(
                      item[displayKey]?.toString() ?? '',
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
            onChanged: onChanged,
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF26A69A)),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hintText,
    bool enabled = true,
    bool isRequired = false,
    Function(String)? onChanged,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: errorText != null ? Colors.red : Colors.grey[300]!,
              width: errorText != null ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            enabled: enabled,
            onChanged: onChanged,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.grey),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity, // Make it full width
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(date),
                  style: const TextStyle(fontSize: 14),
                ),
                const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF26A69A),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attach Files',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickFiles,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Choose Files',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedFiles.isEmpty
                        ? 'No file chosen'
                        : '${_selectedFiles.length} file(s) selected',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_selectedFiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _selectedFiles.asMap().entries.map((entry) {
                  int index = entry.key;
                  XFile file = entry.value;
                  return Chip(
                    label: Text(
                      file.name,
                      style: const TextStyle(fontSize: 12),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeFile(index),
                    backgroundColor: Colors.grey[200],
                  );
                }).toList(),
          ),
        ],
      ],
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

  void _handleSave(SupplierPaymentController controller) {
    if (controller.receiptExists == true) {
      showErrorSnack(
        'PV number already exists. Please use a different number.',
      );
      return;
    }
    // Mark all fields as touched to show validation
    setState(() {
      _currencyTouched = true;
      _supplierTouched = true;
      _paymentTypeTouched = true;
      _bankTouched = true;
      _accountNumberTouched = true;
      _totalPayingTouched = true;
      _paidByTouched = true;
    });

    // Validate required fields
    if (controller.selectedCurrencyId == null) {
      showErrorSnack('Please select a currency');
      return;
    }

    if (controller.selectedSupplierId == null) {
      showErrorSnack('Please select a supplier');
      return;
    }

    if (_selectedPaymentType == null) {
      showErrorSnack('Please select payment type');
      return;
    }

    if (_totalPayingController.text.isEmpty) {
      showErrorSnack('Please enter total paying amount');
      return;
    }

    if (_paidByController.text.isEmpty) {
      showErrorSnack('Please enter paid by name');
      return;
    }

    if (_selectedPaymentType == 'Cheque' ||
        _selectedPaymentType == 'Bank Transfer') {
      if (controller.selectedBankId == null) {
        showErrorSnack('Please select a bank');
        return;
      }

      if (_accountNumberController.text.isEmpty) {
        showErrorSnack('Please enter account number');
        return;
      }
    }

    final payingAmount = double.tryParse(_totalPayingController.text) ?? 0.0;
    final payableAmount = double.tryParse(_totalPayableController.text) ?? 0.0;

    if (payingAmount <= 0) {
      showErrorSnack('Paying amount must be greater than zero');
      return;
    }

    if (payingAmount > payableAmount && _selectedInvoices.isNotEmpty) {
      showErrorSnack('Paying amount cannot exceed total payable amount');
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.save_outlined, color: Color(0xFF26A69A)),
              SizedBox(width: 8),
              Text('Confirm Payment'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to save this payment?',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildConfirmationRow(
                      'Payment Amount:',
                      _totalPayingController.text,
                    ),
                    const SizedBox(height: 4),
                    _buildConfirmationRow(
                      'Payment Type:',
                      _selectedPaymentType ?? '',
                    ),
                    if (_selectedPaymentType == 'Cheque' ||
                        _selectedPaymentType == 'Bank Transfer') ...[
                      const SizedBox(height: 4),
                      _buildConfirmationRow(
                        'Bank:',
                        controller.bankName?.firstWhere(
                              (bank) => bank['id'] == controller.selectedBankId,
                              orElse: () => {'Name': 'N/A'},
                            )['Name'] ??
                            'N/A',
                      ),
                      const SizedBox(height: 4),
                      _buildConfirmationRow(
                        'Account Number:',
                        _accountNumberController.text,
                      ),
                    ],
                    const SizedBox(height: 4),
                    _buildConfirmationRow(
                      'PV Number:',
                      _pvNumberController.text,
                    ),
                    const SizedBox(height: 4),
                    _buildConfirmationRow('Paid By:', _paidByController.text),
                    if (_selectedInvoices.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _buildConfirmationRow(
                        'Selected Invoices:',
                        '${_selectedInvoices.length}',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processSave(controller);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF26A69A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF26A69A),
            ),
          ),
        ),
      ],
    );
  }

  void _processSave(SupplierPaymentController controller) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF26A69A)),
        );
      },
    );

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
