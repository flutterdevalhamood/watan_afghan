import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/currency_conversion_controller.dart';
import 'package:sample/src/widgets/form_field_widget.dart';

class CurrencyConversionDataScreen extends StatefulWidget {
  const CurrencyConversionDataScreen({super.key});

  @override
  State<CurrencyConversionDataScreen> createState() =>
      _CurrencyConversionScreenState();
}

class _CurrencyConversionScreenState
    extends State<CurrencyConversionDataScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fromAmountController = TextEditingController();
  final TextEditingController _toAmountController = TextEditingController();
  final TextEditingController _referenceNumberController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _fromAccountNumberController =
      TextEditingController();
  final TextEditingController _toAccountNumberController =
      TextEditingController();

  Map<String, dynamic>? _selectedFromCurrency;
  int? _selectedFromCurrencyId;
  int? _selectedToCurrencyId;
  Map<String, dynamic>? _selectedToCurrency;
  String _fromPaymentType = 'cash';
  String _toPaymentType = 'cash';
  DateTime _selectedDate = DateTime.now();
  int? _fromBankId;
  int? _toBankId;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<CurrencyConversionController>(
        context,
        listen: false,
      );
      controller.getCurrencyBaseData();
    });
  }

  @override
  void dispose() {
    _fromAmountController.dispose();
    _toAmountController.dispose();
    _referenceNumberController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // Show date picker
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

  // Save currency conversion
  Future<void> _saveConversion() async {
    if (_formKey.currentState!.validate()) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final controller = Provider.of<CurrencyConversionController>(
        context,
        listen: false,
      );

      // Format date for API
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final success = await controller.postCurrencyConversion(
        fromPaymentType: _fromPaymentType,
        fromCurrencyId: _selectedFromCurrencyId,
        fromAmount: _fromAmountController.text,
        fromBankId: _fromBankId,
        toPaymentType: _toPaymentType,
        toCurrencyId: _selectedToCurrencyId,
        toAmount: _toAmountController.text,
        toBankId: _toBankId.toString(),
        referenceNumber: _referenceNumberController.text,
        transactionDate: formattedDate,
        description: _descriptionController.text,
      );

      // Hide loading indicator
      Navigator.of(context).pop();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Currency conversion saved successfully'),
          ),
        );
        Navigator.of(context).pop(); // Return to previous screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.errorMessage ?? 'Failed to save')),
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
      ),
      body: Consumer<CurrencyConversionController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final currencies = controller.currencyData ?? [];
          final banks = controller.banksData ?? [];

          final filteredFromBanks =
              _selectedFromCurrencyId != null
                  ? banks
                      .where(
                        (bank) =>
                            bank['id'].toString() ==
                            _selectedFromCurrencyId.toString(),
                      )
                      .toList()
                  : banks;

          final filteredToBanks =
              _selectedToCurrencyId != null
                  ? banks
                      .where(
                        (bank) =>
                            bank['id'].toString() ==
                            _selectedToCurrencyId.toString(),
                      )
                      .toList()
                  : banks;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('From Currency Details'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownField(
                            label: 'From Currency *',
                            hint: '--Select Currency--',
                            value: _selectedFromCurrencyId,
                            items:
                                currencies.map((currency) {
                                  return DropdownMenuItem(
                                    value: currency['id'] as int,
                                    child: Text(currency['Name'] as String),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedFromCurrencyId = value;
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
                      ],
                    ),
                    const SizedBox(height: 16),

                    // From Amount
                    _buildTextField(
                      controller: _fromAmountController,
                      label: 'From Amount *',
                      keyboardType: TextInputType.number,
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

                    // From Payment Type
                    _buildDropdownField(
                      label: 'From Payment Type *',
                      hint: 'Select Payment Type',
                      value: _fromPaymentType,
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'bank', child: Text('Bank')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _fromPaymentType = value as String;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    if (_fromPaymentType == 'bank') ...[
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
                          value: _fromBankId,
                          items:
                              filteredFromBanks
                                  .map(
                                    (bank) => DropdownMenuItem(
                                      value: bank['id'] as int,
                                      child: Text('${bank['Name']}'),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              _fromBankId = value;
                            });
                          },
                          validator: (value) {
                            if (_fromPaymentType == 'bank' && value == null) {
                              return 'Please select a bank';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      const SizedBox(height: 16),
                    ],

                    // To Currency Section
                    _buildSectionTitle('To Currency Details'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownField(
                            label: 'To Currency *',
                            hint: '--Select Currency--',
                            value: _selectedToCurrencyId,
                            items:
                                currencies.map((currency) {
                                  return DropdownMenuItem(
                                    value: currency['id'] as int,
                                    child: Text(currency['Name'] as String),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedToCurrencyId = value;
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
                      ],
                    ),
                    const SizedBox(height: 16),

                    // To Amount
                    _buildTextField(
                      controller: _toAmountController,
                      label: 'To Amount *',
                      keyboardType: TextInputType.number,
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

                    // To Payment Type
                    _buildDropdownField(
                      label: 'To Payment Type *',
                      hint: 'Select Payment Type',
                      value: _toPaymentType,
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'bank', child: Text('Bank')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _toPaymentType = value as String;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    if (_toPaymentType == 'bank') ...[
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
                          value: _toBankId,
                          items:
                              filteredToBanks
                                  .map(
                                    (bank) => DropdownMenuItem(
                                      value: bank['id'] as int,
                                      child: Text('${bank['Name']}'),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              _toBankId = value;
                            });
                          },
                          validator: (value) {
                            if (_toPaymentType == 'bank' && value == null) {
                              return 'Please select a bank';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Transaction Details Section
                    _buildSectionTitle('Transaction Details'),

                    // Reference Number
                    _buildTextField(
                      controller: _referenceNumberController,
                      label: 'Reference Number *',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a reference number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date Picker
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: IgnorePointer(
                        child: _buildTextField(
                          controller: _dateController,
                          label: 'Transaction Date *',
                          suffixIcon: const Icon(Icons.calendar_today),
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

                    // Description
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saveConversion,
                            icon: const Icon(Icons.save),
                            label: const Text('Save'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancel'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper method to build section titles
  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const Divider(),
        const SizedBox(height: 8),
      ],
    );
  }

  // Helper method to build text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        suffixIcon: suffixIcon,
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      validator: validator,
    );
  }

  // Helper method to build dropdown fields
  Widget _buildDropdownField<T>({
    required String label,
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      hint: Text(hint),
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      isExpanded: true,
    );
  }
}
