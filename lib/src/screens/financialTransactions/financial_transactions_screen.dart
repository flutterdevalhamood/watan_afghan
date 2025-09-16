import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';

class FinancialTransactionsScreen extends StatelessWidget {
  const FinancialTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        NavigationService().pushAndRemoveUntilNavigation(
          Screenroutes.dashboard,
          removeUntilPageName: Screenroutes.dashboard,
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Financial Transactions'),
          leading: IconButton(
            onPressed: () {
              NavigationService().pushAndRemoveUntilNavigation(
                Screenroutes.dashboard,
                removeUntilPageName: Screenroutes.dashboard,
              );
            },
            icon: const Icon(Icons.arrow_back),
          ),
          elevation: 2,
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction Categories',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildTransactionCard(
                      context,
                      'Investor Transactions',
                      Icons.account_balance,
                      Colors.purple,
                      () {
                        NavigationService().pushNavigation(
                          Screenroutes.investorTransactionScreen,
                        );
                      },
                    ),
                    _buildTransactionCard(
                      context,
                      'Currency Conversions',
                      Icons.currency_exchange,
                      Colors.black,
                      () {
                        NavigationService().pushNavigation(
                          Screenroutes.currencyConversionScreen,
                        );
                      },
                    ),
                    _buildTransactionCard(
                      context,
                      'Customer Advance',
                      Icons.account_balance_wallet,
                      Colors.blue,
                      () {
                        NavigationService().pushNavigation(
                          Screenroutes.customerAdvanceListScreen,
                        );
                      },
                    ),
                    // _buildTransactionCard(
                    //   context,
                    //   'Customer Payment',
                    //   Icons.payment,
                    //   Colors.green,
                    //   () {},
                    // ),
                    _buildTransactionCard(
                      context,
                      'Supplier Advance',
                      Icons.shopping_bag,
                      Colors.orange,
                      () {
                        NavigationService().pushNavigation(
                          Screenroutes.supplierAdvanceListScreen,
                        );
                      },
                    ),
                    // _buildTransactionCard(
                    //   context,
                    //   'Supplier Payment',
                    //   Icons.receipt_long,
                    //   Colors.purple,
                    //   () {},
                    // ),
                    // _buildTransactionCard(
                    //   context,
                    //   'Bank to Bank',
                    //   Icons.compare_arrows,
                    //   Colors.teal,
                    //   () {},
                    // ),
                  ],
                ),
                // SizedBox(height: 24),
                // Text(
                //   'Recent Transactions',
                //   style: Theme.of(context).textTheme.titleLarge,
                // ),
                // SizedBox(height: 16),
                // _buildRecentTransactionsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: color),
              SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsList() {
    final dummyTransactions = [
      {
        'type': 'Customer Advance',
        'name': 'Acme Corp',
        'amount': '₹50,000',
        'date': '10 May 2025',
      },
      {
        'type': 'Supplier Payment',
        'name': 'Global Supplies Ltd',
        'amount': '₹25,350',
        'date': '8 May 2025',
      },
      {
        'type': 'Bank to Bank',
        'name': 'HDFC to SBI',
        'amount': '₹100,000',
        'date': '5 May 2025',
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: dummyTransactions.length,
      separatorBuilder: (context, index) => Divider(),
      itemBuilder: (context, index) {
        final transaction = dummyTransactions[index];
        return ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          leading: CircleAvatar(
            backgroundColor: _getColorForTransactionType(transaction['type']!),
            child: Icon(
              _getIconForTransactionType(transaction['type']!),
              color: Colors.white,
            ),
          ),
          title: Text(
            transaction['name']!,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(transaction['date']!),
          trailing: Text(
            transaction['amount']!,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        );
      },
    );
  }

  Color _getColorForTransactionType(String type) {
    switch (type) {
      case 'Customer Advance':
        return Colors.blue;
      case 'Customer Payment':
        return Colors.green;
      case 'Supplier Advance':
        return Colors.orange;
      case 'Supplier Payment':
        return Colors.purple;
      case 'Bank to Bank':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForTransactionType(String type) {
    switch (type) {
      case 'Customer Advance':
        return Icons.account_balance_wallet;
      case 'Customer Payment':
        return Icons.payment;
      case 'Supplier Advance':
        return Icons.shopping_bag;
      case 'Supplier Payment':
        return Icons.receipt_long;
      case 'Bank to Bank':
        return Icons.compare_arrows;
      default:
        return Icons.attach_money;
    }
  }
}

class CustomerAdvanceListPage extends StatelessWidget {
  const CustomerAdvanceListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy data for customer advances
    final advances = [
      {
        'customerName': 'Acme Corp',
        'rvNumber': 'RV#4120',
        'amount': '₹50,000',
        'date': '10 May 2025',
      },
      {
        'customerName': 'TechStar Inc',
        'rvNumber': 'RV#4121',
        'amount': '₹25,000',
        'date': '9 May 2025',
      },
      {
        'customerName': 'Global Traders',
        'rvNumber': 'RV#4122',
        'amount': '₹75,000',
        'date': '7 May 2025',
      },
      {
        'customerName': 'Pinnacle Systems',
        'rvNumber': 'RV#4123',
        'amount': '₹33,000',
        'date': '5 May 2025',
      },
      {
        'customerName': 'First Solutions',
        'rvNumber': 'RV#4124',
        'amount': '₹29,500',
        'date': '3 May 2025',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Customer Advances'), elevation: 2),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search customer advances',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: advances.length,
              separatorBuilder: (_, __) => Divider(height: 1),
              itemBuilder: (context, index) {
                final advance = advances[index];
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: Text(
                    advance['customerName']!,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text('${advance['rvNumber']} | ${advance['date']}'),
                    ],
                  ),
                  trailing: Text(
                    advance['amount']!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                  onTap: () {
                    // View details of the specific advance
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddCustomerAdvancePage()),
          );
        },
      ),
    );
  }
}

class AddCustomerAdvancePage extends StatefulWidget {
  const AddCustomerAdvancePage({Key? key}) : super(key: key);

  @override
  _AddCustomerAdvancePageState createState() => _AddCustomerAdvancePageState();
}

class _AddCustomerAdvancePageState extends State<AddCustomerAdvancePage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _sumOfController = TextEditingController();
  final TextEditingController _receiverNameController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _rvNumberController = TextEditingController();

  String? _selectedCustomer;
  String? _selectedPaymentType;
  DateTime _selectedDate = DateTime.now();

  final List<String> _customers = [
    'Acme Corp',
    'TechStar Inc',
    'Global Traders',
    'Pinnacle Systems',
    'First Solutions',
  ];

  final List<String> _paymentTypes = [
    'Bank Transfer',
    'Cash',
    'Check',
    'Credit Card',
    'Debit Card',
  ];

  @override
  void initState() {
    super.initState();
    _rvNumberController.text = 'RV#4126'; // Pre-populated as in the screenshot
  }

  @override
  void dispose() {
    _amountController.dispose();
    _sumOfController.dispose();
    _receiverNameController.dispose();
    _noteController.dispose();
    _rvNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        NavigationService().pushAndRemoveUntilNavigation(
          Screenroutes.dashboard,
          removeUntilPageName: Screenroutes.dashboard,
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Add Customer Advance'), elevation: 2),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ADD CUSTOMER ADVANCE',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '* Fields are required please don\'t leave blank',
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
                SizedBox(height: 24),

                // Customer Selection
                _buildFieldLabel('Customer Selection', true),
                _buildDropdown(
                  hint: '--Select your Customer--',
                  value: _selectedCustomer,
                  items: _customers,
                  onChanged: (value) {
                    setState(() {
                      _selectedCustomer = value;
                    });
                  },
                ),
                SizedBox(height: 16),

                // RV Number
                _buildFieldLabel(
                  'RV Number',
                  true,
                  additionalText:
                      'RV number from system is only suggestion please enter actual',
                ),
                TextField(
                  controller: _rvNumberController,
                  decoration: InputDecoration(hintText: 'Enter RV Number'),
                ),
                SizedBox(height: 16),

                // Payment Type
                _buildFieldLabel('Payment Type', true),
                _buildDropdown(
                  hint: '--Select your Payment Type--',
                  value: _selectedPaymentType,
                  items: _paymentTypes,
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentType = value;
                    });
                  },
                ),
                SizedBox(height: 16),

                // Transfer or Deposit Date
                _buildFieldLabel('Transfer or Deposit Date', true),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Amount and Sum Of
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Amount', true),
                          TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Enter Amount',
                            ),
                            onChanged: (value) {
                              // Convert to words and update Sum Of field
                              if (value.isNotEmpty) {
                                try {
                                  final amount = double.parse(value);
                                  _sumOfController.text = _convertNumberToWords(
                                    amount,
                                  );
                                } catch (e) {
                                  // Handle parsing error
                                }
                              } else {
                                _sumOfController.text = '';
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Sum Of', true),
                          TextField(
                            controller: _sumOfController,
                            decoration: InputDecoration(
                              hintText: 'Amount in words',
                            ),
                            readOnly: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Receiver Name
                _buildFieldLabel('Receiver Name', true),
                TextField(
                  controller: _receiverNameController,
                  decoration: InputDecoration(hintText: 'Enter Receiver Name'),
                ),
                SizedBox(height: 16),

                // Note
                Text(
                  'Note',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter any additional notes',
                  ),
                ),
                SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Validate and submit form
                      if (_validateForm()) {
                        _submitForm();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'SUBMIT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(
    String label,
    bool isRequired, {
    String? additionalText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          if (additionalText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                additionalText,
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?)? onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint),
          value: value,
          items:
              items.map((String item) {
                return DropdownMenuItem<String>(value: item, child: Text(item));
              }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  bool _validateForm() {
    // Check required fields
    if (_selectedCustomer == null ||
        _selectedPaymentType == null ||
        _amountController.text.isEmpty ||
        _sumOfController.text.isEmpty ||
        _receiverNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return false;
    }
    return true;
  }

  void _submitForm() {
    // Process form submission
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Customer Advance added successfully')),
    );
    Navigator.pop(context);
  }

  String _convertNumberToWords(double number) {
    // This is a simplified version, for a real app you would use a more robust solution
    if (number == 0) return 'Zero';

    const units = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
    ];
    const teens = [
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];
    const tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];

    // Extract whole number and decimal parts
    int wholeNumber = number.toInt();
    int decimal = ((number - wholeNumber) * 100).round();

    if (wholeNumber < 10) return '${units[wholeNumber]} Rupees';
    if (wholeNumber < 20) return '${teens[wholeNumber - 10]} Rupees';
    if (wholeNumber < 100) {
      final ten = wholeNumber ~/ 10;
      final unit = wholeNumber % 10;
      return '${tens[ten]}${unit > 0 ? ' ${units[unit]}' : ''} Rupees';
    }

    if (wholeNumber < 1000) {
      final hundred = wholeNumber ~/ 100;
      final remainder = wholeNumber % 100;
      String words = '${units[hundred]} Hundred';
      if (remainder > 0) {
        words += ' and ${_convertNumberToWords(remainder.toDouble())}';
      } else {
        words += ' Rupees';
      }
      return words;
    }

    if (wholeNumber < 100000) {
      final thousand = wholeNumber ~/ 1000;
      final remainder = wholeNumber % 1000;
      String words = '${_convertNumberToWords(thousand.toDouble())} Thousand';
      if (remainder > 0) {
        words += ' ${_convertNumberToWords(remainder.toDouble())}';
      } else {
        words += ' Rupees';
      }
      return words;
    }

    return '$wholeNumber Rupees'; // Fallback for larger numbers
  }
}
