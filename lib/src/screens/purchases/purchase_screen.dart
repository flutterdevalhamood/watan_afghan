import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/purchase_controller.dart';
import 'package:sample/src/util/snack.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController(); // Add this
  final List<GlobalKey> _productKeys = [];

  List<FocusNode> quantityFocusNodes = [];

  final Map<String, GlobalKey> _fieldKeys = {
    'supplier': GlobalKey(),
    'invoiceNumber': GlobalKey(),
    'purchaseDate': GlobalKey(),
    'currency': GlobalKey(),
  };

  List<TextEditingController> quantityControllers = [];
  List<TextEditingController> priceControllers = [];

  void _initializeControllers() {
    for (var controller in quantityControllers) {
      controller.dispose();
    }
    for (var controller in priceControllers) {
      controller.dispose();
    }
    for (var focusNode in quantityFocusNodes) {
      focusNode.dispose();
    }

    quantityControllers.clear();
    priceControllers.clear();
    quantityFocusNodes.clear();

    // Create new controllers for each item
    for (int i = 0; i < salesItems.length; i++) {
      quantityControllers.add(
        TextEditingController(
          text:
              salesItems[i].quantity == 0
                  ? ''
                  : salesItems[i].quantity.toString(),
        ),
      );
      priceControllers.add(
        TextEditingController(text: salesItems[i].price.toString()),
      );
      quantityFocusNodes.add(FocusNode());

      // Add focus listener to clear field when focused
      quantityFocusNodes[i].addListener(() {
        if (quantityFocusNodes[i].hasFocus &&
            quantityControllers[i].text == '0') {
          quantityControllers[i].clear();
        }
      });
    }
  }

  // Form values
  String? selectedSupplier;
  String? selectedCurrency;
  String? invoiceNumber;
  DateTime invoiceDate = DateTime.now();

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
    _productKeys.add(GlobalKey());
    invoiceNumberController.text = invoiceNumber ?? '';
    _initializeControllers();
    _updateTotals();

    // Load base data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<PurchaseController>(
        context,
        listen: false,
      );
      controller.clearSelections();
      controller.clearImages();
      controller.getPurchaseBaseData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (var controller in quantityControllers) {
      controller.dispose();
    }
    for (var controller in priceControllers) {
      controller.dispose();
    }
    for (var focusNode in quantityFocusNodes) {
      focusNode.dispose();
    }
    termsController.dispose();
    notesController.dispose();
    invoiceNumberController.dispose();
    super.dispose();
  }

  // Controller for Terms and Customer Note
  final TextEditingController termsController = TextEditingController(
    text: 'Terms and Conditions',
  );
  final TextEditingController notesController = TextEditingController(
    text: 'Customer Notes',
  );
  final TextEditingController invoiceNumberController = TextEditingController();

  // Function to check if all previous products are filled
  bool _areAllPreviousProductsFilled() {
    for (int i = 0; i < salesItems.length; i++) {
      if (salesItems[i].productId == null ||
          salesItems[i].unitId == null ||
          salesItems[i].quantity <= 0 ||
          salesItems[i].price <= 0) {
        return false;
      }
    }
    return true;
  }

  // Function to get the first incomplete product index
  int _getFirstIncompleteProductIndex() {
    for (int i = 0; i < salesItems.length; i++) {
      if (salesItems[i].productId == null ||
          salesItems[i].unitId == null ||
          salesItems[i].quantity <= 0 ||
          salesItems[i].price <= 0) {
        return i;
      }
    }
    return -1;
  }

  Future<void> _scrollToFirstError() async {
    await Future.delayed(const Duration(milliseconds: 100));

    final controller = Provider.of<PurchaseController>(context, listen: false);

    // Check main form fields first
    final mainValidationChecks = [
      {'key': 'supplier', 'check': () => controller.selectedSupplierId == null},
      {
        'key': 'invoiceNumber',
        'check': () => invoiceNumberController.text.trim().isEmpty,
      },
      {
        'key': 'currency',
        'check': () => controller.selectedCurrencyTypeId == null,
      },
    ];

    // Check main form fields
    for (final validation in mainValidationChecks) {
      final checkFunction = validation['check'] as bool Function()?;
      if (checkFunction != null && checkFunction()) {
        final fieldKey = _fieldKeys[validation['key']];
        if (fieldKey?.currentContext != null) {
          await _scrollToWidget(fieldKey!);
          return;
        }
      }
    }

    // Check product fields if main fields are valid
    for (int i = 0; i < salesItems.length; i++) {
      if (salesItems[i].productId == null ||
          salesItems[i].unitId == null ||
          salesItems[i].quantity <= 0 ||
          salesItems[i].price <= 0) {
        if (i < _productKeys.length && _productKeys[i].currentContext != null) {
          await _scrollToWidget(_productKeys[i]);
          return;
        }
      }
    }
  }

  // Add this method to scroll to a specific widget
  Future<void> _scrollToWidget(GlobalKey key) async {
    final context = key.currentContext;
    if (context != null) {
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);

      // Calculate the scroll offset needed
      final scrollOffset =
          _scrollController.offset +
          position.dy -
          100; // 100px padding from top

      // Animate to the error field
      await _scrollController.animateTo(
        scrollOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      final controller = Provider.of<PurchaseController>(
        context,
        listen: false,
      );

      for (XFile image in images) {
        controller.addImage(File(image.path));
      }
    } catch (e) {
      showErrorSnack('Error picking images: ${e.toString()}');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        final controller = Provider.of<PurchaseController>(
          context,
          listen: false,
        );
        controller.addImage(File(image.path));
      }
    } catch (e) {
      showErrorSnack('Error taking photo: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PurchaseController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Purchase'),
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
                        controller: _scrollController,
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
                                    'Supplier Name:',
                                    required: true,
                                    child: Container(
                                      key: _fieldKeys['supplier'],
                                      child: DropdownButtonFormField<String>(
                                        decoration: const InputDecoration(
                                          hintText: 'Select Supplier',
                                        ),
                                        value:
                                            controller.selectedSupplierId
                                                ?.toString(),
                                        items:
                                            controller.supplier
                                                ?.map(
                                                  (
                                                    item,
                                                  ) => DropdownMenuItem<String>(
                                                    value:
                                                        item['id'].toString(),
                                                    child: Text(
                                                      item['Name'] ??
                                                          item['supplier_name'] ??
                                                          'Unknown',
                                                    ),
                                                  ),
                                                )
                                                .toList() ??
                                            [],
                                        onChanged: (value) {
                                          if (value != null) {
                                            controller.setSupplier(
                                              int.parse(value),
                                            );
                                            setState(() {
                                              selectedSupplier = value;
                                            });
                                          }
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please select a supplier';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Invoice Number Field
                                  _buildLabeledField(
                                    'Invoice Number:',
                                    required: true,
                                    child: Container(
                                      key: _fieldKeys['invoiceNumber'],
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
                                  ),
                                  const SizedBox(height: 16),

                                  // Single Date Field
                                  _buildLabeledField(
                                    'Purchase date:',
                                    required: true,
                                    child: Container(
                                      key: _fieldKeys['purchaseDate'],
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
                                              ).format(invoiceDate),
                                            ),
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
                                    child: Container(
                                      key: _fieldKeys['currency'],
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
                                                  (
                                                    item,
                                                  ) => DropdownMenuItem<String>(
                                                    value:
                                                        item['id'].toString(),
                                                    child: Text(
                                                      item['Name'] ??
                                                          item['currency_name'] ??
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
                                  // Products Section Header with Add Button
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Products',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed:
                                                _areAllPreviousProductsFilled()
                                                    ? _addNewProduct
                                                    : null,
                                            icon: const Icon(
                                              Icons.add,
                                              size: 18,
                                            ),
                                            label: const Text('Add Product'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  _areAllPreviousProductsFilled()
                                                      ? Colors.teal
                                                      : Colors.grey,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                            ),
                                          ),
                                          if (!_areAllPreviousProductsFilled())
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Text(
                                                'Complete Product ${_getFirstIncompleteProductIndex() + 1} first',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.red.shade600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Products Table Rows
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: salesItems.length,
                                    itemBuilder: (context, index) {
                                      return Card(
                                        key: _productKeys[index],
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
                                              // Product row header with delete button
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Product ${index + 1}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  if (salesItems.length > 1)
                                                    IconButton(
                                                      onPressed:
                                                          () => _removeProduct(
                                                            index,
                                                          ),
                                                      icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                      ),
                                                      tooltip: 'Remove Product',
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),

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
                                                      });
                                                    }
                                                  },
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Please select a product';
                                                    }
                                                    return null;
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
                                                                    item['unit_name'] ??
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
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Please select a unit';
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
                                                        controller:
                                                            quantityControllers[index],
                                                        focusNode:
                                                            quantityFocusNodes[index],
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        validator: (value) {
                                                          if (value == null ||
                                                              value.isEmpty) {
                                                            return 'Required';
                                                          }
                                                          if (int.tryParse(
                                                                    value,
                                                                  ) ==
                                                                  null ||
                                                              int.parse(
                                                                    value,
                                                                  ) <=
                                                                  0) {
                                                            return 'Invalid quantity';
                                                          }
                                                          return null;
                                                        },
                                                        onTap: () {
                                                          // Alternative approach: Clear on tap if value is 0
                                                          if (quantityControllers[index]
                                                                  .text ==
                                                              '0') {
                                                            quantityControllers[index]
                                                                .clear();
                                                          }
                                                        },
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

                                                  Expanded(
                                                    child: _buildLabeledField(
                                                      'Price:',
                                                      required: true,
                                                      child: TextFormField(
                                                        controller:
                                                            priceControllers[index],
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        validator: (value) {
                                                          if (value == null ||
                                                              value.isEmpty) {
                                                            return 'Required';
                                                          }
                                                          if (double.tryParse(
                                                                    value,
                                                                  ) ==
                                                                  null ||
                                                              double.parse(
                                                                    value,
                                                                  ) <
                                                                  0) {
                                                            return 'Invalid price';
                                                          }
                                                          return null;
                                                        },
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
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Invoice Images',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: _pickImageFromCamera,
                                            icon: const Icon(
                                              Icons.camera_alt,
                                              size: 16,
                                            ),
                                            label: const Text('Camera'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton.icon(
                                            onPressed: _pickImages,
                                            icon: const Icon(
                                              Icons.photo_library,
                                              size: 16,
                                            ),
                                            label: const Text('Gallery'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  if (controller.selectedImages.isEmpty)
                                    Container(
                                      width: double.infinity,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          style: BorderStyle.solid,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.image,
                                              size: 40,
                                              color: Colors.grey,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'No images selected',
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children:
                                          controller.selectedImages
                                              .asMap()
                                              .entries
                                              .map((entry) {
                                                int index = entry.key;
                                                File image = entry.value;

                                                return Stack(
                                                  children: [
                                                    Container(
                                                      width: 100,
                                                      height: 100,
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade300,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        child: Image.file(
                                                          image,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 4,
                                                      right: 4,
                                                      child: GestureDetector(
                                                        onTap:
                                                            () => controller
                                                                .removeImage(
                                                                  index,
                                                                ),
                                                        child: Container(
                                                          width: 24,
                                                          height: 24,
                                                          decoration:
                                                              const BoxDecoration(
                                                                color:
                                                                    Colors.red,
                                                                shape:
                                                                    BoxShape
                                                                        .circle,
                                                              ),
                                                          child: const Icon(
                                                            Icons.close,
                                                            color: Colors.white,
                                                            size: 16,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              })
                                              .toList(),
                                    ),
                                ],
                              ),
                            ),

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
                                            await _savePurchase(controller);
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

  void _addNewProduct() {
    setState(() {
      salesItems.add(SalesItem());
      final newIndex = quantityControllers.length;
      quantityControllers.add(TextEditingController());
      priceControllers.add(TextEditingController());
      final newFocusNode = FocusNode();
      newFocusNode.addListener(() {
        if (newFocusNode.hasFocus &&
            quantityControllers[newIndex].text == '0') {
          quantityControllers[newIndex].clear();
        }
      });
      quantityFocusNodes.add(newFocusNode);
      _productKeys.add(GlobalKey()); // Add key for new product
    });

    // Auto-scroll to the new product after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToNewProduct();
    });
  }

  void _scrollToNewProduct() {
    if (_productKeys.isNotEmpty) {
      final RenderBox? renderBox =
          _productKeys.last.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        final scrollOffset =
            _scrollController.offset +
            position.dy -
            100; // 100px padding from top

        _scrollController.animateTo(
          scrollOffset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _removeProduct(int index) {
    if (salesItems.length > 1) {
      setState(() {
        salesItems.removeAt(index);
        quantityControllers[index].dispose();
        priceControllers[index].dispose();
        quantityControllers.removeAt(index);
        priceControllers.removeAt(index);
        _productKeys.removeAt(index);
        quantityFocusNodes.removeAt(index); // Remove corresponding key
        _updateTotals();
      });
    }
  }

  // Save purchase function
  Future<void> _savePurchase(PurchaseController controller) async {
    if (!_formKey.currentState!.validate()) {
      await _scrollToFirstError();
      return;
    }
    // Validate that all products have required fields
    for (int i = 0; i < salesItems.length; i++) {
      if (salesItems[i].productId == null ||
          salesItems[i].unitId == null ||
          salesItems[i].quantity <= 0 ||
          salesItems[i].price <= 0) {
        showErrorSnack('Please fill all required fields for Product ${i + 1}');
        return;
      }
    }

    // Prepare product details JSON
    List<Map<String, dynamic>> productDetails =
        salesItems.map((item) {
          return {
            'product_id': item.productId,
            'unit_id': item.unitId,
            'qty': item.quantity,
            'cost': item.price,
            'total_before_tax': item.total.toString(),
            'tax_per': item.taxRate,
            'tax_amount': item.taxAmount,
            'total_amount': item.totalWithTax,
          };
        }).toList();

    // In the _savePurchase method, update the controller call:
    final success = await controller.postPurchaseRegistration(
      supplierId: controller.selectedSupplierId,
      currencyId: controller.selectedCurrencyTypeId,
      purchaseDate: DateFormat('yyyy-MM-dd').format(invoiceDate),
      invoiceNumber: invoiceNumber,
      finalTotalBeforeTax: subtotal.toString(),
      totalTax: _calculateTotalTax().toString(),
      grandTotal: grandTotal.toString(),
      customerNote: notesController.text,
      productDetails: jsonEncode(productDetails),
      invoiceImages:
          controller.selectedImages.isNotEmpty
              ? controller.selectedImages
              : null,
    );

    if (success) {
      if (mounted) {
        showSuccessSnack(
          'Purchase saved successfully! ID: ${controller.savedPurchaseId}',
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
  String? product = 'Product';
  String? unit = 'UNIT';
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
    this.product,
    this.unit,
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
