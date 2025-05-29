import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form values
  String? selectedSupplier;
  String? selectedReferenceNumber;
  String? selectedCurrency = 'AED'; // Added currency selection
  String invoiceNumber = "ECFT-0087";
  DateTime invoiceDate = DateTime.now();

  // Currency options
  final List<String> currencies = ['AED', 'USD', 'EUR'];

  // Payment related fields
  String? selectedPaymentType = 'Cash';
  final List<String> paymentTypes = ['Cash', 'Bank Transfer', 'Check'];
  double paidAmount = 0.0;
  double roundOff = 0.0;
  double balanceAmount = 0.0;

  // Bank payment fields
  String? selectedBankName;
  String accountNumber = '';
  DateTime transferDate = DateTime.now();
  String chequeRefNumber = '';

  // Bank options
  final List<String> bankNames = ['--Select Bank Name--', 'Bank 1'];

  // File upload
  String? selectedFile = 'No file chosen';

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

  // Dropdown options
  final List<String> customers = ['--Select Customer--', 'Customer 1'];

  @override
  void initState() {
    super.initState();
    // Initialize calculations
    _updateTotals();
  }

  final List<String> products = ['Product', 'Product 1'];
  final List<String> units = ['UNIT', 'PCS', 'KG', 'METER'];

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

  @override
  Widget build(BuildContext context) {
    // Check if we're on a mobile device
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      // Customer Dropdown
                      _buildLabeledField(
                        'Supplier Name:',
                        required: true,
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            hintText: 'Select Supplier',
                          ),
                          value: selectedSupplier,
                          items:
                              customers
                                  .map(
                                    (item) => DropdownMenuItem<String>(
                                      value: item,
                                      child: Text(item),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSupplier = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value == customers[0]) {
                              return 'Please select a supplier';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Currency Dropdown - Added
                      _buildLabeledField(
                        'Currency:',
                        required: true,
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            hintText: 'Select Currency',
                          ),
                          value: selectedCurrency,
                          items:
                              currencies
                                  .map(
                                    (item) => DropdownMenuItem<String>(
                                      value: item,
                                      child: Text(item),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCurrency = value;
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

                      // Single Date Field
                      _buildLabeledField(
                        'Date:',
                        required: true,
                        child: GestureDetector(
                          onTap:
                              () => _selectDate(context, isTransferDate: false),
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

                      _buildLabeledField(
                        'Reference Number:',
                        required: true,
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            hintText: 'Select Reference Number',
                          ),
                          value: selectedReferenceNumber,
                          items:
                              customers
                                  .map(
                                    (item) => DropdownMenuItem<String>(
                                      value: item,
                                      child: Text(item),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedReferenceNumber = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value == customers[0]) {
                              return 'Please select a reference number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Products Section - Modified with manual subtotal entry and VAT selection
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
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildTableHeaderCell('Category *'),
                            ),
                            Expanded(
                              flex: 1,
                              child: _buildTableHeaderCell('UNIT *'),
                            ),
                            Expanded(
                              flex: 1,
                              child: _buildTableHeaderCell('Qty *'),
                            ),
                            Expanded(
                              flex: 1,
                              child: _buildTableHeaderCell('Price *'),
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
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product Dropdown
                                  _buildLabeledField(
                                    'Category:',
                                    required: true,
                                    child: DropdownButtonFormField<String>(
                                      value: salesItems[index].product,
                                      items:
                                          products
                                              .map(
                                                (item) =>
                                                    DropdownMenuItem<String>(
                                                      value: item,
                                                      child: Text(item),
                                                    ),
                                              )
                                              .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          salesItems[index].product = value;
                                        });
                                      },
                                    ),
                                  ),

                                  const SizedBox(height: 12),
                                  // Manual Subtotal Entry - Added
                                  _buildLabeledField(
                                    'Subtotal:',
                                    required: true,
                                    child: TextFormField(
                                      controller: subtotalController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: 'Enter subtotal amount',
                                        prefixText:
                                            '${selectedCurrency ?? 'AED'} ',
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          subtotal =
                                              double.tryParse(value) ?? 0.0;
                                          _calculateGrandTotal();
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter subtotal amount';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // VAT Selection - Modified
                                  _buildLabeledField(
                                    'VAT Rate:',
                                    required: true,
                                    child: DropdownButtonFormField<double>(
                                      decoration: const InputDecoration(
                                        hintText: 'Select VAT Rate',
                                      ),
                                      value: selectedVatRate,
                                      items: List.generate(vatRates.length, (
                                        index,
                                      ) {
                                        return DropdownMenuItem<double>(
                                          value: vatRates[index],
                                          child: Text(vatLabels[index]),
                                        );
                                      }),
                                      onChanged: (value) {
                                        setState(() {
                                          selectedVatRate = value ?? 0.05;
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

                                  // Description TextField
                                  _buildLabeledField(
                                    'Description:',
                                    child: TextFormField(
                                      initialValue:
                                          salesItems[index].description,
                                      onChanged: (value) {
                                        setState(() {
                                          salesItems[index].description = value;
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
                              '${selectedCurrency ?? 'AED'} ${subtotal.toStringAsFixed(2)}',
                            ),
                            _buildTotalRow(
                              'VAT (${(selectedVatRate * 100).toInt()}%):',
                              '${selectedCurrency ?? 'AED'} ${vatAmount.toStringAsFixed(2)}',
                            ),
                            _buildTotalRow(
                              'Grand Total:',
                              '${selectedCurrency ?? 'AED'} ${grandTotal.toStringAsFixed(2)}',
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Payment Details Section - Modified
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
                      _buildLabeledField(
                        'Payment Type:',
                        required: true,
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            hintText: 'Select Payment Type',
                          ),
                          value: selectedPaymentType,
                          items:
                              paymentTypes
                                  .map(
                                    (item) => DropdownMenuItem<String>(
                                      value: item,
                                      child: Text(item),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedPaymentType = value;
                              // Reset bank fields when payment type changes
                              if (value == 'Cash') {
                                selectedBankName = null;
                                accountNumber = '';
                                chequeRefNumber = '';
                              }
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a payment type';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Conditional fields based on payment type - Modified logic
                      if (selectedPaymentType != 'Cash')
                        _buildPaymentSpecificFields(isMobile),

                      // Paid Amount field
                      _buildLabeledField(
                        'Paid Amount:',
                        required: true,
                        child: TextFormField(
                          controller: paidAmountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter paid amount',
                            prefixText: '${selectedCurrency ?? 'AED'} ',
                          ),
                          onChanged: (value) {
                            double enteredAmount =
                                double.tryParse(value) ?? 0.0;
                            setState(() {
                              paidAmount = enteredAmount;
                              _calculateRoundOffAndBalance();
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter paid amount';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Round Off field
                      _buildLabeledField(
                        'Round Off:',
                        child: TextFormField(
                          readOnly: true,
                          initialValue: roundOff.toStringAsFixed(2),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            prefixText: '${selectedCurrency ?? 'AED'} ',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Balance field
                      _buildLabeledField(
                        'Balance:',
                        child: TextFormField(
                          readOnly: true,
                          initialValue: balanceAmount.toStringAsFixed(2),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            prefixText: '${selectedCurrency ?? 'AED'} ',
                            fillColor: const Color(0xFFFFEEEE),
                            filled: true,
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                balanceAmount > 0 ? Colors.red : Colors.green,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // File Upload Section - only for non-cash payments
                      if (selectedPaymentType != 'Cash')
                        _buildFileUploadSection(),
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
                      icon: const Icon(Icons.check),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Process data
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Processing Data')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build Payment Specific Fields - New method for cleaner logic
  Widget _buildPaymentSpecificFields(bool isMobile) {
    return Column(
      children: [
        // Bank Name - Required for Bank Transfer and Check
        if (selectedPaymentType == 'Bank Transfer' ||
            selectedPaymentType == 'Check')
          _buildLabeledField(
            'Bank Name:',
            required: true,
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(hintText: 'Select Bank Name'),
              value: selectedBankName,
              items:
                  bankNames
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  selectedBankName = value;
                });
              },
              validator: (value) {
                if (value == null || value == bankNames[0]) {
                  return 'Please select a bank';
                }
                return null;
              },
            ),
          ),

        if (selectedPaymentType == 'Bank Transfer' ||
            selectedPaymentType == 'Check')
          const SizedBox(height: 16),

        // Account Number - For Bank Transfer
        if (selectedPaymentType == 'Bank Transfer')
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

        if (selectedPaymentType == 'Bank Transfer') const SizedBox(height: 16),

        // Transfer or Deposit Date - For Bank Transfer
        if (selectedPaymentType == 'Bank Transfer')
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

        if (selectedPaymentType == 'Bank Transfer') const SizedBox(height: 16),

        // Cheque or Reference Number - For Check
        if (selectedPaymentType == 'Check')
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

        if (selectedPaymentType == 'Check') const SizedBox(height: 16),
      ],
    );
  }

  // Build File Upload Section
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
            // File Upload button
            ElevatedButton(
              onPressed: () {
                // Implement file picker functionality here
                setState(() {
                  selectedFile = 'receipt.pdf'; // Demo value
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black,
              ),
              child: const Text('Choose Files'),
            ),
            const SizedBox(width: 12),

            // Selected file name
            Expanded(
              child: Text(
                selectedFile ?? 'No file chosen',
                style: TextStyle(color: Colors.grey.shade700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
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

  // Function to calculate item total
  void _calculateTotal(int index) {
    setState(() {
      salesItems[index].total =
          salesItems[index].quantity * salesItems[index].price;
      salesItems[index].subtotal = salesItems[index].total;
      salesItems[index].vatAmount =
          salesItems[index].subtotal * selectedVatRate;
    });
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

  // Helper for building labeled form fields

  // Helper for building labeled form fields
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
