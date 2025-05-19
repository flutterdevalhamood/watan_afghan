import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/currency_conversion_controller.dart';

class CurrencyConversionDataScreen extends StatefulWidget {
  final int? investorId;

  const CurrencyConversionDataScreen({super.key, this.investorId});

  @override
  State<CurrencyConversionDataScreen> createState() =>
      _CurrencyConversionScreenState();
}

class _CurrencyConversionScreenState
    extends State<CurrencyConversionDataScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isIncome = true;
  String _transactionType = 'currency';
  String? _selectedCurrencyId;
  String? _selectedPaymentType = 'bank';
  int? _selectedBankId;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _transferDateController = TextEditingController();
  final TextEditingController _referenceNumberController =
      TextEditingController();
  final TextEditingController _personNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _transferDateController.text = DateFormat(
      'yyyy-MM-dd',
    ).format(_selectedDate);

    // Fetch currency data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CurrencyConversionController>(
        context,
        listen: false,
      ).getCurrencyBaseData();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountNumberController.dispose();
    _transferDateController.dispose();
    _referenceNumberController.dispose();
    _personNameController.dispose();
    _descriptionController.dispose();
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
        _transferDateController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(_selectedDate);
      });
    }
  }

  Future<void> _submitConversion() async {
    if (_formKey.currentState!.validate()) {
      final controller = Provider.of<CurrencyConversionController>(
        context,
        listen: false,
      );

      final bool success = await controller.postCurrencyConversion(
        transactionType: _transactionType,
        totalAmount: _amountController.text,
        investorId: widget.investorId,
        paymentType: _selectedPaymentType,
        bankId: _selectedBankId,
        accountNumber: _accountNumberController.text,
        transferDate: _transferDateController.text,
        referenceNumber: _referenceNumberController.text,
        personName: _personNameController.text,
        description: _descriptionController.text,
        currencyId: _selectedCurrencyId,
        isIncome: _isIncome ? 'true' : 'false',
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Currency conversion registered successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              controller.errorMessage ?? 'Failed to register conversion',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Conversion'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<CurrencyConversionController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Transaction Type Card
                    _buildSectionCard(
                      title: 'Transaction Information',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Transaction Direction
                          Row(
                            children: [
                              const Text(
                                'Transaction Type:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 16),
                              ChoiceChip(
                                label: const Text('Income'),
                                selected: _isIncome,
                                onSelected: (selected) {
                                  setState(() {
                                    _isIncome = true;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('Expense'),
                                selected: !_isIncome,
                                onSelected: (selected) {
                                  setState(() {
                                    _isIncome = false;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Amount
                          TextFormField(
                            controller: _amountController,
                            decoration: const InputDecoration(
                              labelText: 'Amount',
                              hintText: 'Enter amount',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an amount';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Currency Selection
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Currency',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.currency_exchange),
                            ),
                            hint: const Text('Select Currency'),
                            value: _selectedCurrencyId,
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedCurrencyId = newValue;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a currency';
                              }
                              return null;
                            },
                            items:
                                controller.currencyData?.map<
                                  DropdownMenuItem<String>
                                >((currency) {
                                  return DropdownMenuItem<String>(
                                    value: currency['id'].toString(),
                                    child: Text(
                                      '${currency['currencyCode']} - ${currency['currencyName']}',
                                    ),
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Payment Details Card
                    _buildSectionCard(
                      title: 'Payment Details',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Payment Type
                          Row(
                            children: [
                              const Text(
                                'Payment Method:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 16),
                              ChoiceChip(
                                label: const Text('Bank'),
                                selected: _selectedPaymentType == 'bank',
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedPaymentType = 'bank';
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('Cash'),
                                selected: _selectedPaymentType == 'cash',
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedPaymentType = 'cash';
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (_selectedPaymentType == 'bank') ...[
                            // Bank Selection (assuming you have a list of banks)
                            DropdownButtonFormField<int>(
                              decoration: const InputDecoration(
                                labelText: 'Bank',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.account_balance),
                              ),
                              hint: const Text('Select Bank'),
                              value: _selectedBankId,
                              onChanged: (int? newValue) {
                                setState(() {
                                  _selectedBankId = newValue;
                                });
                              },
                              validator:
                                  _selectedPaymentType == 'bank'
                                      ? (value) {
                                        if (value == null) {
                                          return 'Please select a bank';
                                        }
                                        return null;
                                      }
                                      : null,
                              // Replace with actual bank data
                              items: const [
                                DropdownMenuItem<int>(
                                  value: 1,
                                  child: Text('Bank A'),
                                ),
                                DropdownMenuItem<int>(
                                  value: 2,
                                  child: Text('Bank B'),
                                ),
                                DropdownMenuItem<int>(
                                  value: 3,
                                  child: Text('Bank C'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Account Number
                            TextFormField(
                              controller: _accountNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Account Number',
                                hintText: 'Enter account number',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.account_balance_wallet),
                              ),
                              validator:
                                  _selectedPaymentType == 'bank'
                                      ? (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter account number';
                                        }
                                        return null;
                                      }
                                      : null,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Transfer Date
                          GestureDetector(
                            onTap: () => _selectDate(context),
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: _transferDateController,
                                decoration: const InputDecoration(
                                  labelText: 'Transfer Date',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today),
                                  suffixIcon: Icon(Icons.arrow_drop_down),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a date';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Reference Number
                          TextFormField(
                            controller: _referenceNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Reference Number',
                              hintText: 'Enter reference number',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.numbers),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Additional Information Card
                    _buildSectionCard(
                      title: 'Additional Information',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Person Name
                          TextFormField(
                            controller: _personNameController,
                            decoration: const InputDecoration(
                              labelText: 'Person Name',
                              hintText: 'Enter person name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              hintText: 'Enter description',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.description),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            controller.isLoading ? null : _submitConversion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child:
                            controller.isLoading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  'Register Conversion',
                                  style: TextStyle(fontSize: 16),
                                ),
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

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
