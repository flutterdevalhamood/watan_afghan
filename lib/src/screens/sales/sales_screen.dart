import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form values
  String? selectedCustomer;
  String invoiceNumber = "ECFT-0087";
  DateTime invoiceDate = DateTime.now();

  // Product table data
  List<SalesItem> salesItems = [SalesItem()];

  // Totals
  double subtotal = 0.0;
  double vatAmount = 0.0;
  double grandTotal = 0.0;
  final double vatRate = 0.05; // 5% VAT

  // Dropdown options
  final List<String> customers = [
    '--Select Customer--',
    'Customer 1',
    'Customer 2',
    'Customer 3',
  ];
  @override
  void initState() {
    super.initState();
    // Initialize calculations
    _updateTotals();
  }

  final List<String> products = [
    'Product',
    'Product 1',
    'Product 2',
    'Product 3',
  ];
  final List<String> units = ['UNIT', 'PCS', 'KG', 'METER'];

  // Controller for Terms and Customer Note
  final TextEditingController termsController = TextEditingController(
    text: 'Terms and Conditions',
  );
  final TextEditingController notesController = TextEditingController(
    text: 'Customer Notes',
  );

  // Stamp and signature
  String? needStamp = 'No';
  final List<String> stampOptions = ['Yes', 'No'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Sales Invoice'),
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
                // Verification warning
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please Verify all data before submit.',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

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
                        'Customer:',
                        required: true,
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            hintText: 'Select Customer',
                          ),
                          value: selectedCustomer,
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
                              selectedCustomer = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value == customers[0]) {
                              return 'Please select a customer';
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Project dropdown removed
                      const SizedBox(height: 16),

                      // Invoice Number
                      _buildLabeledField(
                        'Invoice Number:',
                        child: TextFormField(
                          initialValue: invoiceNumber,
                          decoration: const InputDecoration(
                            hintText: 'Enter Invoice Number',
                          ),
                          onChanged: (value) {
                            invoiceNumber = value;
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Single Date Field
                      _buildLabeledField(
                        'Invoice date:',
                        required: true,
                        child: GestureDetector(
                          onTap: () => _selectDate(context),
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
                      // Warning removed
                      const SizedBox(height: 8),

                      // Products Table Header
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        color: Colors.teal.shade100,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildTableHeaderCell('Product *'),
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

                      // Products Table Rows - Vertical layout to avoid overflow
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
                                    'Product:',
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

                                  // Total for this item
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    color: Colors.grey.shade100,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Item Total:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${salesItems[index].total.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Unit Dropdown
                                  _buildLabeledField(
                                    'Unit:',
                                    required: true,
                                    child: DropdownButtonFormField<String>(
                                      value: salesItems[index].unit,
                                      items:
                                          units
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
                                          salesItems[index].unit = value;
                                        });
                                      },
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  Row(
                                    children: [
                                      // Quantity TextField
                                      Expanded(
                                        child: _buildLabeledField(
                                          'Quantity:',
                                          required: true,
                                          child: TextFormField(
                                            initialValue:
                                                salesItems[index].quantity
                                                    .toString(),
                                            keyboardType: TextInputType.number,
                                            onChanged: (value) {
                                              setState(() {
                                                salesItems[index].quantity =
                                                    int.tryParse(value) ?? 0;
                                                _calculateTotal(index);
                                                _updateTotals();
                                              });
                                            },
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 16),

                                      // Price TextField
                                      Expanded(
                                        child: _buildLabeledField(
                                          'Price:',
                                          required: true,
                                          child: TextFormField(
                                            initialValue:
                                                salesItems[index].price
                                                    .toString(),
                                            keyboardType: TextInputType.number,
                                            onChanged: (value) {
                                              setState(() {
                                                salesItems[index].price =
                                                    double.tryParse(value) ??
                                                    0.0;
                                                _calculateTotal(index);
                                                _updateTotals();
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
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

                      // Description TextField removed (moved into each item card)
                      const SizedBox(height: 16),

                      // Add Row Button removed
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
                              subtotal.toStringAsFixed(2),
                            ),
                            _buildTotalRow(
                              'VAT (5%):',
                              vatAmount.toStringAsFixed(2),
                            ),
                            _buildTotalRow(
                              'Grand Total:',
                              grandTotal.toStringAsFixed(2),
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Terms and Notes Section
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
                      // Terms & Conditions
                      _buildLabeledField(
                        'Terms & Condition:',
                        child: TextFormField(
                          controller: termsController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Enter terms and conditions',
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Customer Note
                      _buildLabeledField(
                        'Customer Note:',
                        child: TextFormField(
                          controller: notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Enter customer note',
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Need Stamp and signature
                      _buildLabeledField(
                        'Need Stamp and signature?',
                        child: DropdownButtonFormField<String>(
                          value: needStamp,
                          items:
                              stampOptions
                                  .map(
                                    (item) => DropdownMenuItem<String>(
                                      value: item,
                                      child: Text(item),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              needStamp = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

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

  // Function to select date - simplified for single date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        invoiceDate = picked;
      });
    }
  }

  // Function to add new row
  void _addNewRow() {
    setState(() {
      salesItems.add(SalesItem());
    });
  }

  // Function to calculate item total
  void _calculateTotal(int index) {
    setState(() {
      salesItems[index].total =
          salesItems[index].quantity * salesItems[index].price;
      salesItems[index].subtotal = salesItems[index].total;
      // Apply VAT to this item
      salesItems[index].vatAmount = salesItems[index].subtotal * vatRate;
    });
  }

  // Function to update grand totals
  void _updateTotals() {
    setState(() {
      // Calculate subtotal (sum of all item totals)
      subtotal = salesItems.fold(0, (sum, item) => sum + item.total);

      // Calculate VAT amount
      vatAmount = subtotal * vatRate;

      // Calculate grand total
      grandTotal = subtotal + vatAmount;
    });
  }

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
