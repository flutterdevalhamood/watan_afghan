import 'package:sample/src/providers/base_controller.dart';
import 'package:sample/src/util/snack.dart';

import '../data/rest_client.dart';
import '../screens/customer/customer_model.dart';

class CustomerController extends BaseController {
  bool isLoading = false;
  bool isLoadingMore = false; // Separate loading state for pagination
  int currentPage = 1;
  final int totalPages = 10;
  bool hasMore = true;
  String? errorMessage;
  int? id;

  List<Map<String, dynamic>>? customerDetail;
  List<Map<String, dynamic>>? companyType;
  List<Map<String, dynamic>>? paymentType;
  List<Map<String, dynamic>>? countries;
  List<Customer> _customers = []; // Single source of truth
  String _searchQuery = '';

  bool get hasData => _customers.isNotEmpty;

  // Registration form state variables
  int? selectedCompanyTypeId;
  int? selectedPaymentTypeId;
  int? selectedRegionId;
  int? selectedCountryId;
  int? selectedStateId;
  int? selectedCityId;

  // Dropdown lists
  List<Map<String, dynamic>> states = [];
  List<Map<String, dynamic>> cities = [];
  List<Map<String, dynamic>> regions = [];

  // Computed property for filtered customers
  List<Customer> get customers {
    if (_searchQuery.isEmpty) {
      return _customers;
    }
    return _customers.where((customer) {
      return customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          customer.mobile.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  String get searchQuery => _searchQuery;
  bool get isEmpty => customers.isEmpty && !isLoading;

  List<Map<String, dynamic>>? _customerDetail;
  bool _isDetailLoading = false;
  String? _detailErrorMessage;

  List<Map<String, dynamic>>? get customerDetailData => _customerDetail;
  bool get isDetailLoading => _isDetailLoading;
  String? get detailErrorMessage => _detailErrorMessage;

  // Registration form methods remain the same...
  void onCountryChanged(int? countryId) {
    selectedCountryId = countryId;
    selectedStateId = null;
    selectedCityId = null;
    selectedRegionId = null;
    states = [];
    cities = [];
    regions = [];

    if (countryId != null && countries != null) {
      final country = countries!.firstWhere(
        (c) => c['id'] == countryId,
        orElse: () => <String, dynamic>{},
      );
      if (country.isNotEmpty) {
        states = List<Map<String, dynamic>>.from(country['states'] ?? []);
      }
    }
    notifyListeners();
  }

  void onStateChanged(int? stateId) {
    selectedStateId = stateId;
    selectedCityId = null;
    selectedRegionId = null;
    cities = [];
    regions = [];

    if (stateId != null && states.isNotEmpty) {
      final state = states.firstWhere(
        (s) => s['id'] == stateId,
        orElse: () => <String, dynamic>{},
      );
      if (state.isNotEmpty) {
        cities = List<Map<String, dynamic>>.from(state['cities'] ?? []);
      }
    }
    notifyListeners();
  }

  void onCityChanged(int? cityId) {
    selectedCityId = cityId;
    selectedRegionId = null;
    regions = [];

    if (cityId != null && cities.isNotEmpty) {
      final city = cities.firstWhere(
        (c) => c['id'] == cityId,
        orElse: () => <String, dynamic>{},
      );
      if (city.isNotEmpty) {
        regions = List<Map<String, dynamic>>.from(city['region'] ?? []);
      }
    }
    notifyListeners();
  }

  void onRegionChanged(int? regionId) {
    if (regionId == null) {
      selectedRegionId = null;
      notifyListeners();
      return;
    }

    Map<String, dynamic>? foundRegion;
    Map<String, dynamic>? parentCity;
    Map<String, dynamic>? parentState;
    Map<String, dynamic>? parentCountry;

    if (countries != null) {
      for (var country in countries!) {
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
    }

    if (foundRegion != null &&
        parentCity != null &&
        parentState != null &&
        parentCountry != null) {
      selectedRegionId = regionId;
      selectedCityId = parentCity['id'];
      selectedStateId = parentState['id'];
      selectedCountryId = parentCountry['id'];

      states = List<Map<String, dynamic>>.from(parentCountry['states'] ?? []);
      cities = List<Map<String, dynamic>>.from(parentState['cities'] ?? []);
      regions = List<Map<String, dynamic>>.from(parentCity['region'] ?? []);
    } else {
      selectedRegionId = regionId;
    }
    notifyListeners();
  }

  List<Map<String, dynamic>> getAllRegions() {
    List<Map<String, dynamic>> allRegions = [];

    if (countries != null) {
      for (var country in countries!) {
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
    }

    final uniqueRegions = <int, Map<String, dynamic>>{};
    for (var region in allRegions) {
      uniqueRegions[region['id']] = region;
    }

    return uniqueRegions.values.toList();
  }

  void setCompanyType(int? companyTypeId) {
    selectedCompanyTypeId = companyTypeId;
    notifyListeners();
  }

  void setPaymentType(int? paymentTypeId) {
    selectedPaymentTypeId = paymentTypeId;
    notifyListeners();
  }

  void resetFormState() {
    selectedCompanyTypeId = null;
    selectedPaymentTypeId = null;
    selectedRegionId = null;
    selectedCountryId = null;
    selectedStateId = null;
    selectedCityId = null;
    states = [];
    cities = [];
    regions = [];
    notifyListeners();
  }

  // FIXED: Simplified search functionality
  void searchCustomers(String query) {
    _searchQuery = query;
    notifyListeners(); // This will trigger a rebuild with the filtered customers
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> getCustomerData({bool loadMore = false}) async {
    if (!await checkToken()) return;

    // Prevent duplicate loading operations
    if (isLoading || (loadMore && isLoadingMore)) {
      return;
    }

    if (loadMore) {
      isLoadingMore = true;
    } else {
      isLoading = true;
      errorMessage = null;
    }

    notifyListeners();

    try {
      final response = await restApi.getCustomer(
        currentPage,
        totalPages,
        getAuthHeader(),
      );

      if (response == null) {
        errorMessage = 'No response received from server';
        return;
      }

      if (response is! Map<String, dynamic>) {
        errorMessage = 'Invalid response format received';

        return;
      }

      final customer = response;

      if (customer['IsSuccess'] == true) {
        final data = customer['Data'];

        if (data != null && data is List) {
          final newCustomerData =
              data
                  .where((item) => item != null && item is Map<String, dynamic>)
                  .map(
                    (json) => Customer.fromJson(json as Map<String, dynamic>),
                  )
                  .toList();

          if (loadMore) {
            _customers.addAll(newCustomerData);
          } else {
            _customers = newCustomerData;
          }

          hasMore = data.length == totalPages;
        } else {
          if (!loadMore) {
            errorMessage = 'No customer data received';
          }
        }
      } else {
        errorMessage =
            customer['Message'] as String? ?? 'Unknown error occurred';
      }
    } catch (e) {
      if (!loadMore) {
        handleApiError(e);
      }
    } finally {
      if (loadMore) {
        isLoadingMore = false;
      } else {
        isLoading = false;
      }
      notifyListeners();
    }
  }

  void loadMore() {
    if (hasMore && !isLoading && !isLoadingMore) {
      currentPage++;
      getCustomerData(loadMore: true);
    }
  }

  Future<void> refresh() async {
    currentPage = 1;
    hasMore = true;
    errorMessage = null;
    _searchQuery = '';

    // Don't clear data immediately - let the new data replace it
    await getCustomerData();
  }

  Future<void> getCustomerDetail(int customerId) async {
    if (!await checkToken()) return;

    _isDetailLoading = true;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      final response = await restApi.getCustomerDetail(
        id: customerId,
        token: getAuthHeader(),
      );

      if (response != null && response is Map<String, dynamic>) {
        final customerDetailData = response;

        if (customerDetailData['IsSuccess'] == true) {
          final data = customerDetailData['Data'];
          if (data != null && data is Map<String, dynamic>) {
            customerDetail = [data];
          } else {
            _detailErrorMessage = 'Invalid customer detail data format';
          }
        } else {
          _detailErrorMessage =
              customerDetailData['Message'] as String? ??
              'Failed to fetch customer details';
        }
      } else {
        _detailErrorMessage = 'Invalid response format';
      }
    } catch (e) {
      handleApiError(e);
      _detailErrorMessage = errorMessage;
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }

  Future<void> getCustomerBaseData() async {
    if (!await checkToken()) return;

    isLoading = true;
    notifyListeners();

    try {
      final response = await restApi.getCustomerBaseList(
        token: getAuthHeader(),
      );

      if (response != null && response is Map<String, dynamic>) {
        final customerBaseData = response;

        if (customerBaseData['IsSuccess'] == true) {
          final data = customerBaseData['Data'];
          if (data != null && data is Map<String, dynamic>) {
            companyType = List<Map<String, dynamic>>.from(
              data['company_type'] ?? [],
            );
            paymentType = List<Map<String, dynamic>>.from(
              data['payment_type'] ?? [],
            );
            countries = List<Map<String, dynamic>>.from(
              data['countries'] ?? [],
            );

            _setDefaultCompanyType();
          }
        } else {
          errorMessage =
              customerBaseData['Message'] as String? ??
              'Failed to fetch base data';
        }
      }
    } catch (e) {
      handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _setDefaultCompanyType() {
    if (companyType != null && companyType!.isNotEmpty) {
      var customerType = companyType!.firstWhere(
        (item) => (item['Name'] as String?)?.toLowerCase() == 'customer',
        orElse: () => <String, dynamic>{},
      );

      if (customerType.isEmpty) {
        customerType = companyType!.firstWhere(
          (item) =>
              (item['Name'] as String?)?.toLowerCase().contains('customer') ??
              false,
          orElse: () => <String, dynamic>{},
        );
      }

      if (customerType.isEmpty && companyType!.isNotEmpty) {
        customerType = companyType!.first;
      }

      if (customerType.isNotEmpty && customerType['id'] != null) {
        selectedCompanyTypeId = customerType['id'];
      }
    }
  }

  Future<CustomerRegistrationResult> postCustomerRegistration({
    String? name,
    String? representative,
    int? companyTypeId,
    String? registrationDate,
    int? paymentTypeId,
    String? toPaymentType,
    int? openingBalance,
    String? openingBalanceAsOfDate,
    String? mobile,
    String? phone,
    String? email,
    String? address,
    int? regionId,
    String? postCode,
  }) async {
    if (!await checkToken()) {
      return CustomerRegistrationResult(
        success: false,
        message: 'Authentication failed',
      );
    }

    try {
      final response = await restApi.postCustomerRegistration(
        token: getAuthHeader(),
        name: name,
        representative: representative,
        companyTypeId: companyTypeId,
        registrationDate: registrationDate,
        paymentTypeId: paymentTypeId,
        toPaymentType: toPaymentType,
        openingBalance: openingBalance,
        openingBalanceAsOfDate: openingBalanceAsOfDate,
        mobile: mobile,
        phone: phone,
        email: email,
        address: address,
        regionId: regionId,
        postCode: postCode,
      );

      if (response != null && response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          await refresh();
          return CustomerRegistrationResult(success: true);
        } else {
          final errorMessage =
              response['Message'] as String? ?? 'Unknown error';

          bool isDuplicate =
              errorMessage.toLowerCase().contains('duplicate') ||
              errorMessage.toLowerCase().contains('already exists') ||
              errorMessage.toLowerCase().contains('name already') ||
              response['ErrorCode'] == 'DUPLICATE_NAME' ||
              response['StatusCode'] == 409;

          return CustomerRegistrationResult(
            success: false,
            message: errorMessage,
            isDuplicateName: isDuplicate,
          );
        }
      } else {
        return CustomerRegistrationResult(
          success: false,
          message: 'Unexpected response format',
        );
      }
    } catch (e) {
      handleApiError(e);
      return CustomerRegistrationResult(
        success: false,
        message: errorMessage ?? 'An error occurred',
      );
    }
  }

  Future<void> deleteCustomer(int? id, String? descriptionText) async {
    if (!await checkToken()) {
      return;
    }

    try {
      final response = await restApi.deleteCustomer(
        token: getAuthHeader(),
        id: id,
        description: descriptionText,
      );

      if (response != null && response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          _customers.removeWhere((customer) => customer.id == id);
          notifyListeners();
          await refresh();
          showSuccessSnack('Customer deleted successfully');
        } else {
          // Handle different types of errors
          String errorMsg = 'Failed to delete customer';

          // Check if it's a validation error with specific field messages
          if (response['Data'] != null &&
              response['Data'] is Map<String, dynamic>) {
            final data = response['Data'] as Map<String, dynamic>;

            // Check for deleteDescription validation error
            if (data['deleteDescription'] != null &&
                data['deleteDescription'] is List) {
              final deleteDescriptionErrors = data['deleteDescription'] as List;
              if (deleteDescriptionErrors.isNotEmpty) {
                errorMsg = deleteDescriptionErrors.first.toString();
              }
            } else if (data.isNotEmpty) {
              // Handle other validation errors if needed
              final firstError = data.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                errorMsg = firstError.first.toString();
              }
            }
          } else {
            // Fallback to general message
            errorMsg =
                response['Message'] as String? ?? 'Failed to delete customer';
          }

          errorMessage = errorMsg;

          showErrorSnack(errorMessage.toString());
        }
      } else {
        // Remove locally and refresh
        _customers.removeWhere((customer) => customer.id == id);
        notifyListeners();
        await refresh();
        showErrorSnack(errorMessage.toString());
      }
    } catch (e) {
      handleApiError(e);
      showErrorSnack('Failed to delete customer: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class CustomerRegistrationResult {
  final bool success;
  final String? message;
  final bool isDuplicateName;

  CustomerRegistrationResult({
    required this.success,
    this.message,
    this.isDuplicateName = false,
  });
}
