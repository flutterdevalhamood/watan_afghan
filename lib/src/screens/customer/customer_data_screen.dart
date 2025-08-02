import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/customer_controller.dart';

class CustomerDataScreen extends StatefulWidget {
  const CustomerDataScreen({super.key});

  @override
  State<CustomerDataScreen> createState() => _CustomerRegistrationScreenState();
}

class _CustomerRegistrationScreenState extends State<CustomerDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form controllers
  final _companyNameController = TextEditingController();
  final _representativeController = TextEditingController();
  final _registrationDateController = TextEditingController();
  final _openingBalanceController = TextEditingController();
  final _openingBalanceAsOfDateController = TextEditingController();
  final _mobileController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _postCodeController = TextEditingController();
  final _noteController = TextEditingController();

  // Global keys for form fields to track their positions
  final Map<String, GlobalKey> _fieldKeys = {
    'companyName': GlobalKey(),
    'representative': GlobalKey(),
    'companyType': GlobalKey(),
    'registrationDate': GlobalKey(),
    'paymentType': GlobalKey(),
    'openingBalance': GlobalKey(),
    'openingBalanceDate': GlobalKey(),
    'mobile': GlobalKey(),
    'phone': GlobalKey(),
    'email': GlobalKey(),
    'address': GlobalKey(),
    'country': GlobalKey(),
    'postCode': GlobalKey(),
    'state': GlobalKey(),
    'city': GlobalKey(),
    'region': GlobalKey(),
    'note': GlobalKey(),
  };

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setDefaultDate();
  }

  void _initializeData() {
    final controller = Provider.of<CustomerController>(context, listen: false);
    controller.resetFormState();
    controller.getCustomerBaseData();
  }

  @override
  void dispose() {
    // Clear all controllers before disposing
    _companyNameController.clear();
    _representativeController.clear();
    _registrationDateController.clear();
    _openingBalanceController.clear();
    _openingBalanceAsOfDateController.clear();
    _mobileController.clear();
    _phoneController.clear();
    _emailController.clear();
    _addressController.clear();
    _postCodeController.clear();
    _noteController.clear();

    // Clear provider state
    final controller = Provider.of<CustomerController>(context, listen: false);
    controller.resetFormState();

    // Dispose controllers
    _companyNameController.dispose();
    _representativeController.dispose();
    _registrationDateController.dispose();
    _openingBalanceController.dispose();
    _openingBalanceAsOfDateController.dispose();
    _mobileController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _postCodeController.dispose();
    _noteController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _clearAllFields() {
    _companyNameController.clear();
    _representativeController.clear();
    _registrationDateController.clear();
    _openingBalanceController.clear();
    _openingBalanceAsOfDateController.clear();
    _mobileController.clear();
    _phoneController.clear();
    _emailController.clear();
    _addressController.clear();
    _postCodeController.clear();
    _noteController.clear();

    // Reset form validation
    _formKey.currentState?.reset();

    // Clear company name error

    // Clear provider state
    final controller = Provider.of<CustomerController>(context, listen: false);
    controller.resetFormState();

    // Set default values again
    _setDefaultDate();
  }

  void _setDefaultDate() {
    final today = DateTime.now();
    final formattedDate =
        "${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}";
    _registrationDateController.text = formattedDate;
    _openingBalanceAsOfDateController.text = formattedDate;
    _openingBalanceController.text = "0.00";
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text =
            "${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}}";
      });
    }
  }

  // Method to scroll to the first validation error
  Future<void> _scrollToFirstError() async {
    await Future.delayed(
      const Duration(milliseconds: 100),
    ); // Wait for validation to complete

    final controller = Provider.of<CustomerController>(context, listen: false);

    // List of field validation checks in order of appearance
    final validationChecks = [
      {
        'key': 'companyName',
        'check': () => _companyNameController.text.trim().isEmpty,
      },
      {
        'key': 'representative',
        'check': () => _representativeController.text.trim().isEmpty,
      },
      {
        'key': 'companyType',
        'check': () => controller.selectedCompanyTypeId == null,
      },
      {
        'key': 'registrationDate',
        'check': () => _registrationDateController.text.trim().isEmpty,
      },
      {
        'key': 'paymentType',
        'check': () => controller.selectedPaymentTypeId == null,
      },
      {
        'key': 'openingBalance',
        'check': () => _openingBalanceController.text.trim().isEmpty,
      },
      {
        'key': 'openingBalanceDate',
        'check': () => _openingBalanceAsOfDateController.text.trim().isEmpty,
      },
      {'key': 'mobile', 'check': () => _mobileController.text.trim().isEmpty},
      {'key': 'region', 'check': () => controller.selectedRegionId == null},
    ];

    // Find the first field with validation error
    for (final validation in validationChecks) {
      final checkFunction = validation['check'] as bool Function()?;
      if (checkFunction != null && checkFunction()) {
        final fieldKey = _fieldKeys[validation['key']];
        if (fieldKey?.currentContext != null) {
          await _scrollToWidget(fieldKey!);
          break;
        }
      }
    }
  }

  // Method to scroll to a specific widget
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

      // Add a subtle shake animation to highlight the error field
      _shakeWidget(key);
    }
  }

  // Method to add a shake animation to highlight the error field
  void _shakeWidget(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      // You can add a shake animation here if needed
      // For now, we'll just focus on the field if possible
      final focusNode = FocusScope.of(context);
      focusNode.requestFocus();
    }
  }

  Future<void> _submitForm() async {
    // Clear previous company name error

    if (!_formKey.currentState!.validate()) {
      // Scroll to the first validation error
      await _scrollToFirstError();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final controller = Provider.of<CustomerController>(context, listen: false);

    try {
      final result = await controller.postCustomerRegistration(
        name: _companyNameController.text.trim(),
        representative: _representativeController.text.trim(),
        companyTypeId: controller.selectedCompanyTypeId,
        registrationDate: _registrationDateController.text,
        paymentTypeId: controller.selectedPaymentTypeId,
        openingBalance:
            int.tryParse(_openingBalanceController.text.replaceAll('.', '')) ??
            0,
        openingBalanceAsOfDate: _openingBalanceAsOfDateController.text,
        mobile: _mobileController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        regionId: controller.selectedRegionId,
        postCode: _postCodeController.text.trim(),
      );

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Customer registered successfully!'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context);
      } else {
        String errorMessage = result.message ?? 'Registration failed';
        if (result.isDuplicateName) {
          errorMessage =
              'A supplier with this name already exists. Please choose a different name.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor:
                result.isDuplicateName
                    ? Colors.orange.shade600
                    : Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(
              seconds: 4,
            ), // Longer duration for duplicate name message
          ),
        );

        // If it's a duplicate name, scroll to and highlight the company name field
        if (result.isDuplicateName) {
          await _scrollToWidget(_fieldKeys['companyName']!);
          _companyNameController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _companyNameController.text.length,
          );
          // Focus on the company name field
          FocusScope.of(context).requestFocus(FocusNode());
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF1F2937),
            size: 20,
          ),
        ),
        title: const Text(
          'Customer Registration',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Consumer<CustomerController>(
        builder: (context, controller, child) {
          return Form(
            key: _formKey,
            child: Column(
              children: [
                // Form content
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Company Information Card
                        _buildCard(
                          title: 'Company Information',
                          icon: Icons.business_outlined,
                          children: [
                            _buildTextField(
                              key: _fieldKeys['companyName'],
                              controller: _companyNameController,
                              label: 'Company Name',
                              isRequired: true,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              key: _fieldKeys['representative'],
                              controller: _representativeController,
                              label: 'Owner/Representative Name',
                              isRequired: true,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDropdown(
                                    key: _fieldKeys['companyType'],
                                    value: controller.selectedCompanyTypeId,
                                    items: controller.companyType ?? [],
                                    label: 'Company Type',
                                    isRequired: true,
                                    onChanged: controller.setCompanyType,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDateField(
                                    key: _fieldKeys['registrationDate'],
                                    controller: _registrationDateController,
                                    label: 'Registration Date',
                                    isRequired: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Payment Information Card
                        _buildCard(
                          title: 'Payment Information',
                          icon: Icons.payment_outlined,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDropdown(
                                    key: _fieldKeys['paymentType'],
                                    value: controller.selectedPaymentTypeId,
                                    items: controller.paymentType ?? [],
                                    label: 'Payment Type',
                                    isRequired: true,
                                    onChanged: controller.setPaymentType,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    key: _fieldKeys['openingBalance'],
                                    controller: _openingBalanceController,
                                    label: 'Opening Balance',
                                    isRequired: true,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildDateField(
                              key: _fieldKeys['openingBalanceDate'],
                              controller: _openingBalanceAsOfDateController,
                              label: 'Opening Balance As of Date',
                              isRequired: true,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Contact Information Card
                        _buildCard(
                          title: 'Contact Information',
                          icon: Icons.contact_phone_outlined,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    key: _fieldKeys['mobile'],
                                    controller: _mobileController,
                                    label: 'Mobile',
                                    isRequired: true,
                                    keyboardType: TextInputType.phone,
                                    isMobile: true,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    key: _fieldKeys['phone'],
                                    controller: _phoneController,
                                    label: 'Phone',
                                    keyboardType: TextInputType.phone,
                                    isPhone: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              key: _fieldKeys['email'],
                              controller: _emailController,
                              label: 'Email',
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Address Information Card
                        _buildCard(
                          title: 'Address Information',
                          icon: Icons.location_on_outlined,
                          children: [
                            _buildTextField(
                              key: _fieldKeys['address'],
                              controller: _addressController,
                              label: 'Street Address',
                              maxLines: 2,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'This will appear as address line in official documentation',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 20),

                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildDropdown(
                                    key: _fieldKeys['country'],
                                    value: controller.selectedCountryId,
                                    items: controller.countries ?? [],
                                    label: 'Country',
                                    onChanged: controller.onCountryChanged,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    key: _fieldKeys['postCode'],
                                    controller: _postCodeController,
                                    label: 'Post Code',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildDropdown(
                                    key: _fieldKeys['state'],
                                    value: controller.selectedStateId,
                                    items: controller.states,
                                    label: 'State',
                                    onChanged: controller.onStateChanged,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDropdown(
                                    key: _fieldKeys['city'],
                                    value: controller.selectedCityId,
                                    items: controller.cities,
                                    label: 'City',
                                    onChanged: controller.onCityChanged,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Updated region dropdown to show all regions and use controller handler
                            _buildDropdown(
                              key: _fieldKeys['region'],
                              value: controller.selectedRegionId,
                              items: controller.getAllRegions(),
                              label: 'Region',
                              isRequired: true,
                              onChanged: controller.onRegionChanged,
                            ),
                            const SizedBox(height: 20),

                            _buildTextField(
                              key: _fieldKeys['note'],
                              controller: _noteController,
                              label: 'Note',
                              maxLines: 3,
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : () {
                                      _clearAllFields();
                                      Navigator.pop(context);
                                    },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF6B7280),
                              side: const BorderSide(color: Color(0xFFD1D5DB)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                    : const Text(
                                      'Save Customer',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    GlobalKey? key,
    required TextEditingController controller,
    required String label,
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool isMobile = false,
    bool isPhone = false,
    String? customError,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
            children:
                isRequired
                    ? [
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: Color(0xFFEF4444)),
                      ),
                    ]
                    : [],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: (isMobile || isPhone) ? 15 : null,
          style: const TextStyle(fontSize: 16, color: Color(0xFF1F2937)),
          decoration: InputDecoration(
            hintText: 'Enter ${label.toLowerCase()}',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            counterText: '',
          ),
          validator: (value) {
            // Custom error takes precedence
            if (customError != null) {
              return customError;
            }

            // Required field validation
            if (isRequired && (value == null || value.trim().isEmpty)) {
              return '$label is required';
            }

            // Skip further validation if field is empty and not required
            if (value == null || value.trim().isEmpty) {
              return null;
            }

            // Mobile number validation
            if (isMobile) {
              // Remove any spaces, dashes, or parentheses for validation
              String cleanedValue = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

              // Check if only digits (and optional + at the beginning)
              if (!RegExp(r'^\+?[0-9]+$').hasMatch(cleanedValue)) {
                return 'Only digits and optional + are allowed';
              }

              // Remove + for length check
              String digitsOnly = cleanedValue.replaceAll('+', '');

              // Check minimum length (at least 7 digits for local numbers)
              if (digitsOnly.length < 7) {
                return 'Mobile number must be at least 7 digits';
              }

              // Check maximum length
              if (digitsOnly.length > 15) {
                return 'Mobile number cannot exceed 15 digits';
              }
            }

            // Phone number validation
            if (isPhone) {
              // Remove any spaces, dashes, parentheses for validation
              String cleanedValue = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

              // Check if only digits (and optional + at the beginning)
              if (!RegExp(r'^\+?[0-9]+$').hasMatch(cleanedValue)) {
                return 'Only digits and optional + are allowed';
              }

              // Remove + for length check
              String digitsOnly = cleanedValue.replaceAll('+', '');

              // Check minimum length
              if (digitsOnly.length < 7) {
                return 'Phone number must be at least 7 digits';
              }

              // Check maximum length
              if (digitsOnly.length > 15) {
                return 'Phone number cannot exceed 15 digits';
              }
            }

            // Email validation (if it's an email field)
            if (keyboardType == TextInputType.emailAddress &&
                value.isNotEmpty) {
              if (!RegExp(
                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email address';
              }
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdown({
    GlobalKey? key,
    required int? value,
    required List<Map<String, dynamic>> items,
    required String label,
    bool isRequired = false,
    required ValueChanged<int?> onChanged,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
            children:
                isRequired
                    ? [
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: Color(0xFFEF4444)),
                      ),
                    ]
                    : [],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: value,
          style: const TextStyle(fontSize: 16, color: Color(0xFF1F2937)),
          decoration: InputDecoration(
            hintText: 'Select ',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 16,
            ),
          ),
          items:
              items.map<DropdownMenuItem<int>>((item) {
                return DropdownMenuItem<int>(
                  value: item['id'],
                  child: Text(
                    item['Name'] ?? '',
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
          onChanged: onChanged,
          validator:
              isRequired
                  ? (value) {
                    if (value == null) {
                      return '$label is required';
                    }
                    return null;
                  }
                  : null,
        ),
      ],
    );
  }

  Widget _buildDateField({
    GlobalKey? key,
    required TextEditingController controller,
    required String label,
    bool isRequired = false,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
            children:
                isRequired
                    ? [
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: Color(0xFFEF4444)),
                      ),
                    ]
                    : [],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          style: const TextStyle(fontSize: 16, color: Color(0xFF1F2937)),
          decoration: InputDecoration(
            hintText: 'Select date',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            suffixIcon: const Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFF6B7280),
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          onTap: () => _selectDate(controller),
          validator:
              isRequired
                  ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '$label is required';
                    }
                    return null;
                  }
                  : null,
        ),
      ],
    );
  }
}
