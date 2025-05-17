import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/investor_transaction_controller.dart';
import 'package:sample/src/widgets/form_field_widget.dart';

class InvestorTransactionDataScreen extends StatefulWidget {
  const InvestorTransactionDataScreen({super.key});

  @override
  State<InvestorTransactionDataScreen> createState() =>
      _InvestorTransactionDataScreenState();
}

class _InvestorTransactionDataScreenState
    extends State<InvestorTransactionDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _paidByController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String? _selectedTransactionType;
  int? _selectedCurrencyId;
  int? _selectedInvestorId;
  String? _isPnlEntry = 'No';
  String? _selectedPaymentType;
  int? _selectedBankId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<String> transactionType = ['Deposit', 'Withdrawal'];
  List<String> paymentType = ['bank', 'cash'];

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<InvestorTransactionController>(
        context,
        listen: false,
      );
      controller.getInvestorBaseData();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _paidByController.dispose();
    _descriptionController.dispose();
    _accountNumberController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _amountController.clear();
    _referenceController.clear();
    _paidByController.clear();
    _descriptionController.clear();
    _accountNumberController.clear();
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    setState(() {
      _selectedTransactionType = null;
      _selectedCurrencyId = null;
      _selectedInvestorId = null;
      _isPnlEntry = 'No';
      _selectedPaymentType = null;
      _selectedBankId = null;
      _selectedDate = DateTime.now();
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final controller = Provider.of<InvestorTransactionController>(
        context,
        listen: false,
      );

      bool success = await controller.postInvestorTransaction(
        transactionType:
            _selectedTransactionType == "deposit" ? "credit" : "debit",
        totalAmount: _amountController.text,
        investorId: _selectedInvestorId,
        paymentType: _selectedPaymentType,
        bankId: _selectedPaymentType == 'bank' ? _selectedBankId : null,
        accountNumber:
            _selectedPaymentType == 'bank'
                ? _accountNumberController.text
                : null,
        transferDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        referenceNumber: _referenceController.text,
        personName: _paidByController.text,
        description: _descriptionController.text,
        currencyId: _selectedCurrencyId?.toString(),
        isIncome: _isPnlEntry == 'Yes' ? '1' : '0',
      );

      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction saved successfully')),
        );
        _resetForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save transaction')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Investor Transaction')),
      body: Consumer<InvestorTransactionController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final currencies = controller.currencyData ?? [];
          final investors = controller.investorData ?? [];
          final banks = controller.banksData ?? [];

          // Filter banks based on selected currency
          final filteredBanks =
              _selectedCurrencyId != null
                  ? banks
                      .where(
                        (bank) =>
                            bank['currency_id'].toString() ==
                            _selectedCurrencyId.toString(),
                      )
                      .toList()
                  : banks;

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction Type
                  CustomFormField(
                    title: 'Transaction Type',
                    isRequired: true,
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        hintText: 'Select Transaction Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: _selectedTransactionType,
                      items:
                          transactionType
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTransactionType = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a transaction type';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Currency
                  CustomFormField(
                    title: 'Currency',
                    isRequired: true,
                    child: DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        hintText: 'Select Currency',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: _selectedCurrencyId,
                      items:
                          currencies
                              .map(
                                (currency) => DropdownMenuItem(
                                  value: currency['id'] as int,
                                  child: Text(currency['Name'] as String),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCurrencyId = value;
                          // Reset bank selection if currency changes
                          _selectedBankId = null;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a currency';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Investor
                  CustomFormField(
                    title: 'Select Investor',
                    isRequired: true,
                    child: DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        hintText: 'Select Investor',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: _selectedInvestorId,
                      items:
                          investors
                              .map(
                                (investor) => DropdownMenuItem(
                                  value: investor['id'] as int,
                                  child: Text(investor['Name'] as String),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedInvestorId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select an investor';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Is This P&L Entry
                  CustomFormField(
                    title: 'Is This P&L Entry?',
                    isRequired: true,
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        hintText: 'Select Option',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: _isPnlEntry,
                      items:
                          ['Yes', 'No']
                              .map(
                                (option) => DropdownMenuItem(
                                  value: option,
                                  child: Text(option),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          _isPnlEntry = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select an option';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Type
                  CustomFormField(
                    title: 'Payment Type',
                    isRequired: true,
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        hintText: 'Select your Payment Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: _selectedPaymentType,
                      items:
                          paymentType
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentType = value;
                          if (value != 'bank') {
                            _selectedBankId = null;
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a payment type';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bank selection (visible only when Payment Type is Bank)
                  if (_selectedPaymentType == 'bank') ...[
                    CustomFormField(
                      title: 'Select Bank',
                      isRequired: true,
                      child: DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          hintText: 'Select Bank',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        value: _selectedBankId,
                        items:
                            filteredBanks
                                .map(
                                  (bank) => DropdownMenuItem(
                                    value: bank['id'] as int,
                                    child: Text('${bank['Name']}'),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBankId = value;
                            // Find the selected bank to get its account number
                            final selectedBank = filteredBanks.firstWhere(
                              (bank) => bank['id'] == value,
                              orElse: () => <String, dynamic>{},
                            );
                            if (selectedBank.isNotEmpty) {
                              _accountNumberController.text =
                                  selectedBank['account_number'] as String;
                            }
                          });
                        },
                        validator: (value) {
                          if (_selectedPaymentType == 'bank' && value == null) {
                            return 'Please select a bank';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Account Number (auto-filled from selected bank)
                    CustomFormField(
                      title: 'Account Number',
                      isRequired: false,
                      child: TextFormField(
                        controller: _accountNumberController,
                        decoration: InputDecoration(
                          hintText: 'Account Number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Amount
                  CustomFormField(
                    title: 'Amount',
                    isRequired: true,
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cheque or Ref. Number
                  CustomFormField(
                    title: 'Cheque or Ref. Number',
                    isRequired: true,
                    child: TextFormField(
                      controller: _referenceController,
                      decoration: InputDecoration(
                        hintText: 'Cheque or Ref. Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a reference number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Receive Date
                  CustomFormField(
                    title: 'Payment Receive Date',
                    isRequired: false,
                    child: TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: 'DD/MM/YYYY',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Paid/Received By
                  CustomFormField(
                    title: 'Paid/Received By',
                    isRequired: true,
                    child: TextFormField(
                      controller: _paidByController,
                      decoration: InputDecoration(
                        hintText: 'Enter Paid By Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  CustomFormField(
                    title: 'Description',
                    isRequired: false,
                    child: TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit and Cancel buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: Text(_isLoading ? 'Saving...' : 'Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _isLoading ? null : _submitForm,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _isLoading ? null : _resetForm,
                          child: const Text('Cancel'),
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
