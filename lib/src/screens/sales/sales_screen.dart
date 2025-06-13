import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/sales_controller.dart';
import 'package:sample/src/util/snack.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form values
  String? selectedCustomer;
  String? selectedCurrency;
  String invoiceNumber = "ECFT-0087";
  DateTime saleDate = DateTime.now();

  List<SalesItem> salesItems = [SalesItem()];

  // Totals
  double subtotal = 0.0;
  double vatAmount = 0.0;
  double grandTotal = 0.0;
  final double vatRate = 0.05; // 5% VAT

  // Tax percentage options
  final List<double> taxOptions = [0.0, 5.0];

  @override
  void initState() {
    super.initState();
    invoiceNumberController.text = invoiceNumber;
    _updateTotals();

    // Load base data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<SalesController>(context, listen: false);
      controller.clearSelections();
      controller.getSalesBaseData();
    });
  }

  // Controller for Terms and Customer Note
  final TextEditingController termsController = TextEditingController(
    text: 'Terms and Conditions',
  );
  final TextEditingController notesController = TextEditingController(
    text: 'Customer Notes',
  );
  final TextEditingController invoiceNumberController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<SalesController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Sales'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          body:
              controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
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
                                  // Supplier Dropdown
                                  _buildLabeledField(
                                    'Customer:',
                                    required: true,
                                    child: DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        hintText: 'Select Customer',
                                      ),
                                      value:
                                          controller.selectedCustomerId
                                              ?.toString(),
                                      items:
                                          controller.customer
                                              ?.map(
                                                (item) =>
                                                    DropdownMenuItem<String>(
                                                      value:
                                                          item['id'].toString(),
                                                      child: Text(
                                                        item['Name'] ??
                                                            item['customers'] ??
                                                            'Unknown',
                                                      ),
                                                    ),
                                              )
                                              .toList() ??
                                          [],
                                      onChanged: (value) {
                                        if (value != null) {
                                          controller.setCustomer(
                                            int.parse(value),
                                          );
                                          setState(() {
                                            selectedCustomer = value;
                                          });
                                        }
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please select a customer';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Invoice Number Field
                                  _buildLabeledField(
                                    'Invoice Number:',
                                    required: true,
                                    child: TextFormField(
                                      controller: invoiceNumberController,
                                      decoration: const InputDecoration(
                                        hintText: 'Enter Invoice Number',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter invoice number';
                                        }
                                        return null;
                                      },
                                      onChanged: (value) {
                                        setState(() {
                                          invoiceNumber = value;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Single Date Field
                                  _buildLabeledField(
                                    'Sale date:',
                                    required: true,
                                    child: GestureDetector(
                                      onTap: () => _selectDate(context),
                                      child: AbsorbPointer(
                                        child: TextFormField(
                                          decoration: const InputDecoration(
                                            hintText: 'Select Date',
                                            suffixIcon: Icon(
                                              Icons.calendar_today,
                                            ),
                                          ),
                                          controller: TextEditingController(
                                            text: DateFormat(
                                              'dd/MM/yyyy',
                                            ).format(saleDate),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Currency Dropdown
                                  _buildLabeledField(
                                    'Currency',
                                    required: true,
                                    child: DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        hintText: 'Select Currency',
                                      ),
                                      value:
                                          controller.selectedCurrencyTypeId
                                              ?.toString(),
                                      items:
                                          controller.currencyType
                                              ?.map(
                                                (item) =>
                                                    DropdownMenuItem<String>(
                                                      value:
                                                          item['id'].toString(),
                                                      child: Text(
                                                        item['Name'] ??
                                                            item['currency'] ??
                                                            'Unknown',
                                                      ),
                                                    ),
                                              )
                                              .toList() ??
                                          [],
                                      onChanged: (value) {
                                        if (value != null) {
                                          controller.setCurrencyType(
                                            int.parse(value),
                                          );
                                          setState(() {
                                            selectedCurrency = value;
                                          });
                                        }
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please select a currency';
                                        }
                                        return null;
                                      },
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
                                  const SizedBox(height: 8),

                                  // Products Table Header
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    color: Colors.teal.shade100,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: _buildTableHeaderCell(
                                            'Product',
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: _buildTableHeaderCell('UNIT'),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: _buildTableHeaderCell(
                                            'From Inv',
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: _buildTableHeaderCell('Qty'),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: _buildTableHeaderCell('Price'),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: _buildTableHeaderCell(
                                            'Amount',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Products Table Rows
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
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
                                              // Product Dropdown
                                              _buildLabeledField(
                                                'Product:',
                                                required: true,
                                                child: DropdownButtonFormField<
                                                  String
                                                >(
                                                  value:
                                                      salesItems[index]
                                                          .productId
                                                          ?.toString(),
                                                  items:
                                                      controller.productType
                                                          ?.map(
                                                            (
                                                              item,
                                                            ) => DropdownMenuItem<
                                                              String
                                                            >(
                                                              value:
                                                                  item['id']
                                                                      .toString(),
                                                              child: Text(
                                                                item['Name'] ??
                                                                    item['product_name'] ??
                                                                    'Unknown',
                                                              ),
                                                            ),
                                                          )
                                                          .toList() ??
                                                      [],
                                                  onChanged: (value) {
                                                    if (value != null) {
                                                      setState(() {
                                                        salesItems[index]
                                                                .productId =
                                                            int.parse(value);
                                                        salesItems[index]
                                                                .product =
                                                            controller
                                                                .productType
                                                                ?.firstWhere(
                                                                  (item) =>
                                                                      item['id']
                                                                          .toString() ==
                                                                      value,
                                                                )?['Name'] ??
                                                            'Unknown';

                                                        // Reset from inventory dropdown when product changes
                                                        salesItems[index]
                                                            .fromInvId = null;
                                                      });

                                                      // Call API to get invoices for selected product
                                                      controller
                                                          .getInvoicesOfProduct(
                                                            int.parse(value),
                                                          );
                                                    }
                                                  },
                                                ),
                                              ),

                                              const SizedBox(height: 12),

                                              // Unit Dropdown
                                              _buildLabeledField(
                                                'Unit:',
                                                required: true,
                                                child: DropdownButtonFormField<
                                                  String
                                                >(
                                                  value:
                                                      salesItems[index].unitId
                                                          ?.toString(),
                                                  items:
                                                      controller.unitType
                                                          ?.map(
                                                            (
                                                              item,
                                                            ) => DropdownMenuItem<
                                                              String
                                                            >(
                                                              value:
                                                                  item['id']
                                                                      .toString(),
                                                              child: Text(
                                                                item['Name'] ??
                                                                    item['units'] ??
                                                                    'Unknown',
                                                              ),
                                                            ),
                                                          )
                                                          .toList() ??
                                                      [],
                                                  onChanged: (value) {
                                                    if (value != null) {
                                                      setState(() {
                                                        salesItems[index]
                                                            .unitId = int.parse(
                                                          value,
                                                        );
                                                        salesItems[index].unit =
                                                            controller.unitType
                                                                ?.firstWhere(
                                                                  (item) =>
                                                                      item['id']
                                                                          .toString() ==
                                                                      value,
                                                                )?['name'] ??
                                                            'Unknown';
                                                      });
                                                    }
                                                  },
                                                ),
                                              ),

                                              const SizedBox(height: 12),

                                              // From Inventory Dropdown
                                              _buildLabeledField(
                                                'From Inv:',
                                                required: true,
                                                child: DropdownButtonFormField<
                                                  String
                                                >(
                                                  value:
                                                      salesItems[index]
                                                          .fromInvId
                                                          ?.toString(),
                                                  items:
                                                      controller
                                                              .isLoadingInvoices
                                                          ? [] // Empty items while loading
                                                          : controller
                                                                  .invoicesOfProductData
                                                                  ?.map(
                                                                    (
                                                                      item,
                                                                    ) => DropdownMenuItem<
                                                                      String
                                                                    >(
                                                                      value:
                                                                          item['id']
                                                                              .toString(), // Use the index as ID
                                                                      child: Text(
                                                                        item['invoice_number'] ??
                                                                            'Unknown', // Display the invoice number
                                                                      ),
                                                                    ),
                                                                  )
                                                                  .toList() ??
                                                              [],
                                                  onChanged:
                                                      salesItems[index]
                                                                      .productId ==
                                                                  null ||
                                                              controller
                                                                  .isLoadingInvoices
                                                          ? null
                                                          : (value) {
                                                            if (value != null) {
                                                              setState(() {
                                                                salesItems[index]
                                                                        .fromInvId =
                                                                    value;
                                                                // Find the selected invoice number by index
                                                                final selectedInvoice = controller
                                                                    .invoicesOfProductData
                                                                    ?.firstWhere(
                                                                      (item) =>
                                                                          item['id']
                                                                              .toString() ==
                                                                          value,
                                                                      orElse:
                                                                          () => {
                                                                            'invoice_number':
                                                                                'Unknown',
                                                                          },
                                                                    );
                                                                salesItems[index]
                                                                        .fromInv =
                                                                    selectedInvoice?['invoice_number'] ??
                                                                    'Unknown';
                                                              });
                                                            }
                                                          },
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        salesItems[index]
                                                                    .productId ==
                                                                null
                                                            ? 'Select Product First'
                                                            : controller
                                                                .isLoadingInvoices
                                                            ? 'Loading invoices...'
                                                            : 'Select From Inventory',
                                                    enabled:
                                                        salesItems[index]
                                                                .productId !=
                                                            null &&
                                                        !controller
                                                            .isLoadingInvoices,
                                                    suffixIcon:
                                                        controller
                                                                .isLoadingInvoices
                                                            ? const SizedBox(
                                                              width: 20,
                                                              height: 20,
                                                              child: Padding(
                                                                padding:
                                                                    EdgeInsets.all(
                                                                      12.0,
                                                                    ),
                                                                child:
                                                                    CircularProgressIndicator(
                                                                      strokeWidth:
                                                                          2,
                                                                    ),
                                                              ),
                                                            )
                                                            : null,
                                                  ),
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Please select from inventory';
                                                    }
                                                    return null;
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
                                                            salesItems[index]
                                                                .quantity
                                                                .toString(),
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        onChanged: (value) {
                                                          setState(() {
                                                            salesItems[index]
                                                                    .quantity =
                                                                int.tryParse(
                                                                  value,
                                                                ) ??
                                                                0;
                                                            _calculateTotal(
                                                              index,
                                                            );
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
                                                            salesItems[index]
                                                                .price
                                                                .toString(),
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        onChanged: (value) {
                                                          setState(() {
                                                            salesItems[index]
                                                                    .price =
                                                                double.tryParse(
                                                                  value,
                                                                ) ??
                                                                0.0;
                                                            _calculateTotal(
                                                              index,
                                                            );
                                                            _updateTotals();
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 12),

                                              Row(
                                                children: [
                                                  // Tax Percentage Dropdown
                                                  Expanded(
                                                    child: _buildLabeledField(
                                                      'Tax %:',
                                                      required: true,
                                                      child: DropdownButtonFormField<
                                                        double
                                                      >(
                                                        value:
                                                            salesItems[index]
                                                                .taxRate,
                                                        items:
                                                            taxOptions
                                                                .map(
                                                                  (
                                                                    rate,
                                                                  ) => DropdownMenuItem<
                                                                    double
                                                                  >(
                                                                    value: rate,
                                                                    child: Text(
                                                                      '${rate}%',
                                                                    ),
                                                                  ),
                                                                )
                                                                .toList(),
                                                        onChanged: (value) {
                                                          setState(() {
                                                            salesItems[index]
                                                                    .taxRate =
                                                                value ?? 0.0;
                                                            _calculateTotal(
                                                              index,
                                                            );
                                                            _updateTotals();
                                                          });
                                                        },
                                                        decoration:
                                                            const InputDecoration(
                                                              hintText:
                                                                  'Select Tax',
                                                            ),
                                                      ),
                                                    ),
                                                  ),

                                                  const SizedBox(width: 16),

                                                  // Amount (Auto-calculated, read-only)
                                                  Expanded(
                                                    child: _buildLabeledField(
                                                      'Amount:',
                                                      child: TextFormField(
                                                        readOnly: true,
                                                        decoration:
                                                            const InputDecoration(
                                                              filled: true,
                                                              fillColor: Color(
                                                                0xFFF5F5F5,
                                                              ),
                                                            ),
                                                        controller:
                                                            TextEditingController(
                                                              text: salesItems[index]
                                                                  .totalWithTax
                                                                  .toStringAsFixed(
                                                                    2,
                                                                  ),
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 12),
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
                                          subtotal.toStringAsFixed(2),
                                        ),
                                        _buildTotalRow(
                                          'Total Tax:',
                                          _calculateTotalTax().toStringAsFixed(
                                            2,
                                          ),
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

                            // Notes Section
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
                                  _buildLabeledField(
                                    'Notes:',
                                    child: TextFormField(
                                      controller: notesController,
                                      maxLines: 4,
                                      decoration: const InputDecoration(
                                        hintText:
                                            'Enter any additional notes or comments...',
                                        border: OutlineInputBorder(),
                                        alignLabelWithHint: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Error Message Display
                            if (controller.errorMessage != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                  ),
                                ),
                                child: Text(
                                  controller.errorMessage!,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),

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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                  onPressed:
                                      controller.isLoading
                                          ? null
                                          : () async {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              await _saveSales(controller);
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
      },
    );
  }

  // Save purchase function
  Future<void> _saveSales(SalesController controller) async {
    // Prepare product details JSON
    List<Map<String, dynamic>> productDetails =
        salesItems.map((item) {
          return {
            'product_id': item.productId,
            'unit_id': item.unitId,
            'from_inv_id': item.fromInvId, // Add from inventory ID
            'qty': item.quantity,
            'cost': item.price,
            'total_before_tax': subtotal.toString(),
            'tax_per': item.taxRate,
            'tax_amount': item.taxAmount,
            'total_amount': item.totalWithTax,
          };
        }).toList();

    final success = await controller.postSalesRegistration(
      customerId: controller.selectedCustomerId,
      currencyId: controller.selectedCurrencyTypeId,
      saleDate: DateFormat('yyyy-MM-dd').format(saleDate),
      invoiceNumber: invoiceNumber,
      finalTotalBeforeTax: subtotal.toString(),
      totalTax: _calculateTotalTax().toString(),
      grandTotal: grandTotal.toString(),
      customerNote: notesController.text,
      productDetails: jsonEncode(productDetails),
    );

    if (success) {
      if (mounted) {
        showSuccessSnack(
          'Purchase saved successfully! ID: ${controller.savedSalesId}',
        );

        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        showErrorSnack(controller.errorMessage ?? 'Failed to save purchase');
      }
    }
  }

  // Function to select date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: saleDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        saleDate = picked;
      });
    }
  }

  // Function to calculate item total
  void _calculateTotal(int index) {
    setState(() {
      // Calculate base total (quantity * price)
      salesItems[index].total =
          salesItems[index].quantity * salesItems[index].price;

      // Calculate tax amount
      salesItems[index].taxAmount =
          salesItems[index].total * (salesItems[index].taxRate / 100);

      // Calculate total with tax
      salesItems[index].totalWithTax =
          salesItems[index].total + salesItems[index].taxAmount;

      salesItems[index].subtotal = salesItems[index].total;
      // Apply VAT to this item
      salesItems[index].vatAmount = salesItems[index].subtotal * vatRate;
    });
  }

  // Function to calculate total tax from all items
  double _calculateTotalTax() {
    return salesItems.fold(0, (sum, item) => sum + item.taxAmount);
  }

  void _updateTotals() {
    setState(() {
      subtotal = salesItems.fold(0, (sum, item) => sum + item.total);
      double totalItemTax = _calculateTotalTax();
      grandTotal = subtotal + totalItemTax;
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

// Updated Model class for Sales Item
class SalesItem {
  int? productId;
  int? unitId;
  String? fromInvId; // Add this property
  String? product = 'Product';
  String? unit = 'UNIT';
  String? fromInv = 'From Inventory'; // Add this property
  String description = '';
  int quantity = 0;
  double price = 0.0;
  double total = 0.0;
  double taxRate = 0.0; // Tax percentage (0.0 or 0.5)
  double taxAmount = 0.0; // Calculated tax amount
  double totalWithTax = 0.0; // Total including tax
  double discount = 0.0;
  double vatAmount = 0.0;
  double subtotal = 0.0;

  SalesItem({
    this.productId,
    this.unitId,
    this.fromInvId, // Add this parameter
    this.product,
    this.unit,
    this.fromInv, // Add this parameter
    this.description = '',
    this.quantity = 0,
    this.price = 0.0,
    this.total = 0.0,
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
    this.totalWithTax = 0.0,
    this.discount = 0.0,
    this.vatAmount = 0.0,
    this.subtotal = 0.0,
  });
}
