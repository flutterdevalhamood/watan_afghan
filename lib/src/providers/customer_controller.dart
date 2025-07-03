import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';
import '../screens/customer/customer_model.dart';

class CustomerController with ChangeNotifier {
  bool isLoading = false;
  int currentPage = 1;
  final int totalPages = 10;
  bool hasMore = true;
  String? errorMessage;
  int? id;

  List<Map<String, dynamic>>? customerDetail;
  List<Map<String, dynamic>>? companyType;
  List<Map<String, dynamic>>? paymentType;
  List<Map<String, dynamic>>? countries;
  List<Customer> _allCustomers = [];
  List<Customer> _filteredCustomers = [];
  String _searchQuery = '';

  bool get hasData => _allCustomers.isNotEmpty;

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

  List<Customer> get customers => _filteredCustomers;
  String get searchQuery => _searchQuery;
  bool get isEmpty => _filteredCustomers.isEmpty && !isLoading;

  List<Map<String, dynamic>>? _customerDetail;
  bool _isDetailLoading = false;
  String? _detailErrorMessage;

  List<Map<String, dynamic>>? get customerDetailData => _customerDetail;
  bool get isDetailLoading => _isDetailLoading;
  String? get detailErrorMessage => _detailErrorMessage;

  // Registration form methods
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

  // Method to handle region selection and autofill parent locations
  void onRegionChanged(int? regionId) {
    if (regionId == null) {
      selectedRegionId = null;
      notifyListeners();
      return;
    }

    // Find the region and its parent city/state/country
    Map<String, dynamic>? foundRegion;
    Map<String, dynamic>? parentCity;
    Map<String, dynamic>? parentState;
    Map<String, dynamic>? parentCountry;

    // Search through all countries to find the region
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
      // Set the selected values
      selectedRegionId = regionId;
      selectedCityId = parentCity!['id'];
      selectedStateId = parentState!['id'];
      selectedCountryId = parentCountry!['id'];

      // Populate the dropdown lists
      states = List<Map<String, dynamic>>.from(parentCountry['states'] ?? []);
      cities = List<Map<String, dynamic>>.from(parentState['cities'] ?? []);
      regions = List<Map<String, dynamic>>.from(parentCity['region'] ?? []);
    } else {
      // If region not found, just set the region ID
      selectedRegionId = regionId;
    }
    notifyListeners();
  }

  // Method to get all regions from all locations for the region dropdown
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

    // Remove duplicates based on ID
    final uniqueRegions = <int, Map<String, dynamic>>{};
    for (var region in allRegions) {
      uniqueRegions[region['id']] = region;
    }

    return uniqueRegions.values.toList();
  }

  // Method to set company type
  void setCompanyType(int? companyTypeId) {
    selectedCompanyTypeId = companyTypeId;
    notifyListeners();
  }

  // Method to set payment type
  void setPaymentType(int? paymentTypeId) {
    selectedPaymentTypeId = paymentTypeId;
    notifyListeners();
  }

  // Method to reset form state
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

  // Search functionality
  void searchCustomers(String query) {
    _searchQuery = query.toLowerCase();

    if (_searchQuery.isEmpty) {
      _filteredCustomers = List.from(_allCustomers);
    } else {
      _filteredCustomers =
          _allCustomers.where((customer) {
            return customer.name.toLowerCase().contains(_searchQuery) ||
                customer.mobile.toLowerCase().contains(_searchQuery);
          }).toList();
    }

    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredCustomers = List.from(_allCustomers);
    notifyListeners();
  }

  Future<bool> _checkToken() async {
    final token = AuthRepo.token;

    // Check if token is valid
    if (token == null || token.isEmpty) {
      debugPrint("No token available - auth failed");
      // Handle missing token
      AuthRepo.handleAuthError();
      return false;
    }

    // Check if token is expired (if implementation supports it)
    if (AuthRepo.isTokenExpired()) {
      debugPrint("Token expired - auth failed");
      // Handle expired token
      AuthRepo.handleAuthError();
      return false;
    }

    return true;
  }

  // Format the token with Bearer prefix
  String _getAuthHeader() {
    return 'Bearer ${AuthRepo.token}';
  }

  Future<void> getCustomerData({bool loadMore = false}) async {
    if (!await _checkToken()) return;

    isLoading = true;
    errorMessage = null; // Clear previous errors
    notifyListeners();

    try {
      final response = await restApi.getCustomer(
        currentPage,
        totalPages,
        _getAuthHeader(),
      );

      debugPrint("API Response: $response");

      // Check if response is null
      if (response == null) {
        errorMessage = 'No response received from server';
        return;
      }

      // Ensure response is a Map
      if (response is! Map<String, dynamic>) {
        errorMessage = 'Invalid response format received';
        debugPrint('Response is not a Map: ${response.runtimeType}');
        return;
      }

      final customer = response;

      // Check if the response indicates success
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
            _allCustomers.addAll(newCustomerData);
          } else {
            _allCustomers = newCustomerData;
          }

          searchCustomers(_searchQuery);
          hasMore = data.length == totalPages;

          debugPrint('Successfully loaded ${newCustomerData.length} customers');
        } else {
          errorMessage = 'No customer data received';
          debugPrint('Data is null or not a List: $data');
        }
      } else {
        // Handle API error response
        errorMessage =
            customer['Message'] as String? ?? 'Unknown error occurred';
        debugPrint('API call failed: $errorMessage');
      }
    } catch (e) {
      debugPrint('Exception in getCustomerData: $e');
      _handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void loadMore() {
    if (hasMore && !isLoading) {
      currentPage++;
      getCustomerData(loadMore: true);
    }
  }

  void refresh() {
    currentPage = 1;
    hasMore = true;
    errorMessage = null;
    _allCustomers.clear();
    _filteredCustomers.clear();
    getCustomerData();
  }

  Future<void> getCustomerDetail(int customerId) async {
    if (!await _checkToken()) return;

    _isDetailLoading = true;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      final response = await restApi.getCustomerDetail(
        id: customerId,
        token: _getAuthHeader(),
      );

      if (response != null && response is Map<String, dynamic>) {
        final customerDetailData = response;

        if (customerDetailData['IsSuccess'] == true) {
          final data = customerDetailData['Data'];
          if (data != null && data is Map<String, dynamic>) {
            customerDetail = [data];
            debugPrint('Customer detail fetched: ${customerDetail?.length}');
          } else {
            _detailErrorMessage = 'Invalid customer detail data format';
          }
        } else {
          _detailErrorMessage =
              customerDetailData['Message'] as String? ??
              'Failed to fetch customer details';
          debugPrint('API call failed: $_detailErrorMessage');
        }
      } else {
        _detailErrorMessage = 'Invalid response format';
      }
    } catch (e) {
      _handleApiError(e);
      _detailErrorMessage = errorMessage;
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }

  Future<void> getCustomerBaseData() async {
    if (!await _checkToken()) return;

    isLoading = true;
    notifyListeners();

    try {
      final response = await restApi.getCustomerBaseList(
        token: _getAuthHeader(),
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
            debugPrint('Base data fetched successfully');
          }
        } else {
          errorMessage =
              customerBaseData['Message'] as String? ??
              'Failed to fetch base data';
          debugPrint('API call failed: $errorMessage');
        }
      }
    } catch (e) {
      _handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> postCustomerRegistration({
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
    if (!await _checkToken()) return false;

    try {
      final response = await restApi.postCustomerRegistration(
        token: _getAuthHeader(),
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

      // Check response
      if (response != null &&
          response is Map<String, dynamic> &&
          response['IsSuccess'] == true) {
        debugPrint("Customer registration posted successfully!");
        await getCustomerData();
        return true;
      } else if (response != null && response is Map<String, dynamic>) {
        debugPrint(
          "Registration failed: ${response['Message'] ?? 'Unknown error'}",
        );
        errorMessage =
            response['Message'] as String? ??
            'Failed to save customer registration';
      } else {
        debugPrint("Unknown response format");
        errorMessage = 'Unexpected response format';
      }
      return false;
    } catch (e) {
      _handleApiError(e);
      return false;
    }
  }

  Future<void> deleteCustomer(int? id, String? descriptionText) async {
    // Enhanced debugging for delete API
    debugPrint("=== DELETE CUSTOMER DEBUG INFO ===");
    debugPrint("Customer ID: $id");
    debugPrint("Description: $descriptionText");
    debugPrint("Token available: ${AuthRepo.token != null}");
    debugPrint("Auth header: ${_getAuthHeader()}");

    if (!await _checkToken()) {
      debugPrint("Token check failed");
      return;
    }

    // Show loading state
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      debugPrint("Calling restApi.deleteCustomer...");

      final response = await restApi.deleteCustomer(
        token: _getAuthHeader(),
        id: id,
        description: descriptionText,
      );

      debugPrint("Delete API Response: $response");

      // Handle response based on your API structure
      if (response != null && response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          debugPrint("Delete successful, refreshing customer list...");
          await getCustomerData();
          debugPrint("Customer list refreshed successfully");
        } else {
          errorMessage =
              response['Message'] as String? ?? 'Failed to delete customer';
          debugPrint("Delete failed: $errorMessage");
        }
      } else {
        debugPrint("Delete completed, refreshing customer list...");
        await getCustomerData();
      }
    } catch (e) {
      debugPrint("Delete API Exception: $e");

      // Enhanced error handling for delete specifically
      if (e is DioException) {
        debugPrint("=== DELETE API DETAILED ERROR INFO ===");
        debugPrint("Status Code: ${e.response?.statusCode}");
        debugPrint("Request URL: ${e.requestOptions.uri}");
        debugPrint("Request Method: ${e.requestOptions.method}");
        debugPrint("Request Headers: ${e.requestOptions.headers}");
        debugPrint("Request Data: ${e.requestOptions.data}");
        debugPrint("Response Headers: ${e.response?.headers}");
        debugPrint("Response Data: ${e.response?.data}");
        debugPrint("=====================================");

        // Check for common 404 causes
        if (e.response?.statusCode == 404) {
          String detailedError = "404 Error - Possible causes:\n";
          detailedError += "1. Incorrect endpoint URL\n";
          detailedError += "2. Customer ID ($id) doesn't exist\n";
          detailedError += "3. Wrong HTTP method\n";
          detailedError += "4. Missing route parameters\n";
          detailedError += "5. Server endpoint not implemented\n";
          detailedError += "\nActual URL called: ${e.requestOptions.uri}";

          errorMessage = detailedError;
          debugPrint(detailedError);
        }
      }

      _handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Standardized error handling
  dynamic _handleApiError(dynamic e) {
    if (e is DioException) {
      debugPrint("Dio Exception: ${e.message}");

      // Handle redirect to login (authentication failure)
      if (e.response?.statusCode == 302 ||
          (e.response?.data is String &&
              (e.response?.data as String).contains('login'))) {
        debugPrint("Authentication failed - redirected to login page");
        errorMessage = 'Authentication failed. Please log in again.';
        AuthRepo.handleAuthError();
        return false;
      }

      // Log detailed response information
      if (e.response != null) {
        debugPrint('Response status: ${e.response?.statusCode}');
        debugPrint('Response data: ${e.response?.data}');
      }

      errorMessage = 'Network error: ${e.message}';
    } else {
      debugPrint("Error: $e");
      errorMessage = 'Error: ${e.toString()}';
    }
    return false;
  }
}
