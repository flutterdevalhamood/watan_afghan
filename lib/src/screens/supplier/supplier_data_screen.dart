import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sample/src/providers/supplier_controller.dart';

class SupplierDataScreen extends StatefulWidget {
  const SupplierDataScreen({super.key});

  @override
  State<SupplierDataScreen> createState() => _SupplierDataScreenState();
}

class _SupplierDataScreenState extends State<SupplierDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form controllers
  final _companyNameController = TextEditingController();
  final _trnNumberController = TextEditingController();
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

  // Selected values
  int? selectedCompanyTypeId;
  int? selectedPaymentTypeId;
  int? selectedRegionId;
  int? selectedCountryId;
  int? selectedStateId;
  int? selectedCityId;

  // Dropdown lists
  List<Map<String, dynamic>> companyTypes = [];
  List<Map<String, dynamic>> paymentTypes = [];
  List<Map<String, dynamic>> countries = [];
  List<Map<String, dynamic>> states = [];
  List<Map<String, dynamic>> cities = [];
  List<Map<String, dynamic>> regions = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setDefaultDate();
  }

  void _initializeData() {
    final controller = Provider.of<SupplierController>(context, listen: false);
    controller.getSupplierBaseData().then((_) {
      setState(() {
        companyTypes = controller.companyType ?? [];
        paymentTypes = controller.paymentType ?? [];
        countries = controller.countries ?? [];
      });
    });
  }

  void _setDefaultDate() {
    final today = DateTime.now();
    final formattedDate =
        "${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}";
    _registrationDateController.text = formattedDate;
    _openingBalanceAsOfDateController.text = formattedDate;
    _openingBalanceController.text = "0.00";
  }

  void _onCountryChanged(int? countryId) {
    setState(() {
      selectedCountryId = countryId;
      selectedStateId = null;
      selectedCityId = null;
      selectedRegionId = null;
      states = [];
      cities = [];
      regions = [];

      if (countryId != null) {
        final country = countries.firstWhere((c) => c['id'] == countryId);
        states = List<Map<String, dynamic>>.from(country['states'] ?? []);
      }
    });
  }

  void _onStateChanged(int? stateId) {
    setState(() {
      selectedStateId = stateId;
      selectedCityId = null;
      selectedRegionId = null;
      cities = [];
      regions = [];

      if (stateId != null) {
        final state = states.firstWhere((s) => s['id'] == stateId);
        cities = List<Map<String, dynamic>>.from(state['cities'] ?? []);
      }
    });
  }

  void _onCityChanged(int? cityId) {
    setState(() {
      selectedCityId = cityId;
      selectedRegionId = null;
      regions = [];

      if (cityId != null) {
        final city = cities.firstWhere((c) => c['id'] == cityId);
        regions = List<Map<String, dynamic>>.from(city['region'] ?? []);
      }
    });
  }

  // New method to handle region selection and autofill parent locations
  void _onRegionChanged(int? regionId) {
    if (regionId == null) {
      setState(() {
        selectedRegionId = null;
      });
      return;
    }

    // Find the region and its parent city/state/country
    Map<String, dynamic>? foundRegion;
    Map<String, dynamic>? parentCity;
    Map<String, dynamic>? parentState;
    Map<String, dynamic>? parentCountry;

    // Search through all countries to find the region
    for (var country in countries) {
      final countryStates = List<Map<String, dynamic>>.from(
        country['states'] ?? [],
      );
      for (var state in countryStates) {
        final stateCities = List<Map<String, dynamic>>.from(
          state['cities'] ?? [],
        );
        for (var city in stateCities) {
          final cityRegions = List<Map<String, dynamic>>.from(
            city['region'] ?? [],
          );
          for (var region in cityRegions) {
            if (region['id'] == regionId) {
              foundRegion = region;
              parentCity = city;
              parentState = state;
              parentCountry = country;
              break;
            }
          }
          if (foundRegion != null) break;
        }
        if (foundRegion != null) break;
      }
      if (foundRegion != null) break;
    }

    if (foundRegion != null &&
        parentCity != null &&
        parentState != null &&
        parentCountry != null) {
      setState(() {
        // Set the selected values
        selectedRegionId = regionId;
        selectedCityId = parentCity!['id'];
        selectedStateId = parentState!['id'];
        selectedCountryId = parentCountry!['id'];

        // Populate the dropdown lists
        states = List<Map<String, dynamic>>.from(parentCountry['states'] ?? []);
        cities = List<Map<String, dynamic>>.from(parentState['cities'] ?? []);
        regions = List<Map<String, dynamic>>.from(parentCity['region'] ?? []);
      });
    } else {
      // If region not found, just set the region ID
      setState(() {
        selectedRegionId = regionId;
      });
    }
  }

  // Method to get all regions from all locations for the region dropdown
  List<Map<String, dynamic>> _getAllRegions() {
    List<Map<String, dynamic>> allRegions = [];

    for (var country in countries) {
      final countryStates = List<Map<String, dynamic>>.from(
        country['states'] ?? [],
      );
      for (var state in countryStates) {
        final stateCities = List<Map<String, dynamic>>.from(
          state['cities'] ?? [],
        );
        for (var city in stateCities) {
          final cityRegions = List<Map<String, dynamic>>.from(
            city['region'] ?? [],
          );
          allRegions.addAll(cityRegions);
        }
      }
    }

    // Remove duplicates based on ID
    final uniqueRegions = <int, Map<String, dynamic>>{};
    for (var region in allRegions) {
      uniqueRegions[region['id']] = region;
    }

    return uniqueRegions.values.toList();
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final controller = Provider.of<SupplierController>(context, listen: false);

    try {
      final result = await controller.postSupplierRegistration(
        name: _companyNameController.text.trim(),
        trnNumber: _trnNumberController.text.trim(),
        representative: _representativeController.text.trim(),
        companyTypeId: selectedCompanyTypeId,
        registrationDate: _registrationDateController.text,
        paymentTypeId: selectedPaymentTypeId,
        openingBalance:
            int.tryParse(_openingBalanceController.text.replaceAll('.', '')) ??
            0,
        openingBalanceAsOfDate: _openingBalanceAsOfDateController.text,
        mobile: _mobileController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        regionId: selectedRegionId,
        postCode: _postCodeController.text.trim(),
      );

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Supplier registered successfully!'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context);
      } else {
        // Show specific message for duplicate name
        String errorMessage = result.message ?? 'Registration failed';
        if (result.isDuplicateName) {
          errorMessage = result.message ?? '';
          // 'A supplier with this name already exists. Please choose a different name.';
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

        // If it's a duplicate name, highlight the company name field
        if (result.isDuplicateName) {
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
          'Supplier Registration',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Form(
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
                          controller: _companyNameController,
                          label: 'Company Name',
                          isRequired: true,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _trnNumberController,
                          label: 'TRN Number',
                          isRequired: true,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _representativeController,
                          label: 'Owner/Representative Name',
                          isRequired: true,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdown(
                                value: selectedCompanyTypeId,
                                items: companyTypes,
                                label: 'Company Type',
                                isRequired: true,
                                onChanged:
                                    (value) => setState(
                                      () => selectedCompanyTypeId = value,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDateField(
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
                                value: selectedPaymentTypeId,
                                items: paymentTypes,
                                label: 'Payment Type',
                                isRequired: true,
                                onChanged:
                                    (value) => setState(
                                      () => selectedPaymentTypeId = value,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
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
                                controller: _mobileController,
                                label: 'Mobile',
                                isRequired: true,
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _phoneController,
                                label: 'Phone',
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
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
                                value: selectedCountryId,
                                items: countries,
                                label: 'Country',
                                onChanged: _onCountryChanged,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
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
                                value: selectedStateId,
                                items: states,
                                label: 'State',
                                onChanged: _onStateChanged,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDropdown(
                                value: selectedCityId,
                                items: cities,
                                label: 'City',
                                onChanged: _onCityChanged,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Updated region dropdown to show all regions and use new handler
                        _buildDropdown(
                          value: selectedRegionId,
                          items: _getAllRegions(),
                          label: 'Region',
                          isRequired: true,
                          onChanged: _onRegionChanged,
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(
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
                            _isLoading ? null : () => Navigator.pop(context),
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Text(
                                  'Save Supplier',
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
    required TextEditingController controller,
    required String label,
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
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
          ),
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

  Widget _buildDropdown({
    required int? value,
    required List<Map<String, dynamic>> items,
    required String label,
    bool isRequired = false,
    required ValueChanged<int?> onChanged,
  }) {
    return Column(
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
    required TextEditingController controller,
    required String label,
    bool isRequired = false,
  }) {
    return Column(
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

  @override
  void dispose() {
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
}
