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

  List<Customer> get customers => _filteredCustomers;
  String get searchQuery => _searchQuery;
  bool get isEmpty => _filteredCustomers.isEmpty && !isLoading;
  bool get hasData => _filteredCustomers.isNotEmpty;

  List<Map<String, dynamic>>? _customerDetail;
  bool _isDetailLoading = false;
  String? _detailErrorMessage;

  List<Map<String, dynamic>>? get customerDetailData => _customerDetail;
  bool get isDetailLoading => _isDetailLoading;
  String? get detailErrorMessage => _detailErrorMessage;

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
    notifyListeners();

    try {
      final customer = await restApi.getCustomer(
        currentPage,
        totalPages,
        _getAuthHeader(),
      );

      if (customer is Map<String, dynamic>) {
        if (customer['IsSuccess'] == true) {
          final data = customer['Data'] as List<dynamic>?;
          if (data != null) {
            final newCustomerData =
                data.map((json) => Customer.fromJson(json)).toList();
            if (loadMore) {
              _allCustomers.addAll(newCustomerData);
            } else {
              _allCustomers = newCustomerData; // Replace list on initial load
            }
            searchCustomers(_searchQuery);
            hasMore = data.length == totalPages;
          } else {
            errorMessage = customer['Message'] as String?;
          }
        } else {
          debugPrint('API call failed: ${customer['Message']}');
        }
      } else {
        debugPrint('Unexpected API response format');
      }
    } catch (e) {
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
      final customerDetailData = await restApi.getCustomerDetail(
        id: customerId,
        token: _getAuthHeader(),
      );

      if (customerDetailData['IsSuccess'] == true) {
        final data = customerDetailData['Data'] as Map<String, dynamic>;
        customerDetail = [data];
        debugPrint('Assigned units fetched: ${customerDetail?.length}');
      } else {
        errorMessage =
            customerDetailData['Message'] ?? 'Failed to fetch assigned units';
        debugPrint('API call failed: $errorMessage');
      }
    } catch (e) {
      _handleApiError(e);
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
      final customerBaseData = await restApi.getCustomerBaseList(
        token: _getAuthHeader(),
      );

      if (customerBaseData['IsSuccess'] == true) {
        companyType = List<Map<String, dynamic>>.from(
          customerBaseData['Data']['company_type'],
        );
        paymentType = List<Map<String, dynamic>>.from(
          customerBaseData['Data']['payment_type'],
        );
        countries = List<Map<String, dynamic>>.from(
          customerBaseData['Data']['countries'],
        );
        debugPrint('Base data fetched successfully');
      } else {
        debugPrint('API call failed: ${customerBaseData['Message']}');
        errorMessage =
            customerBaseData['Message'] ?? 'Failed to fetch base data';
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
      if (response is Map<String, dynamic> && response['IsSuccess'] == true) {
        debugPrint("Transaction posted successfully!");
        return true;
      } else if (response is Map<String, dynamic>) {
        debugPrint(
          "Transaction failed: ${response['Message'] ?? 'Unknown error'}",
        );
        errorMessage = response['Message'] ?? 'Failed to save transaction';
      } else {
        debugPrint("Unknown response format");
        errorMessage = 'Unexpected response format';
      }
      return false;
    } catch (e) {
      return _handleApiError(e);
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
      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          debugPrint("Delete successful, refreshing customer list...");
          await getCustomerData();
          debugPrint("Customer list refreshed successfully");
        } else {
          errorMessage = response['Message'] ?? 'Failed to delete customer';
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
