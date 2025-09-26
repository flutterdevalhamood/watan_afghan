import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sample/src/models/customer_advance_disburse_model.dart';
import 'package:sample/src/models/customer_advance_model.dart';
import 'package:sample/src/util/snack.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class CustomerAdvanceController with ChangeNotifier {
  bool isLoading = false;
  int currentPage = 1;
  final int totalPages = 10;
  bool hasMore = true;
  String? errorMessage;
  int? id;

  List<CustomerAdvance> _allCustomerAdvances = [];
  List<CustomerAdvance> _filteredCustomerAdvances = [];
  String _searchQuery = '';

  bool get hasData => _allCustomerAdvances.isNotEmpty;

  // Detail properties
  CustomerAdvanceWithDetails? _customerAdvanceDetail;
  bool _isDetailLoading = false;
  String? _detailErrorMessage;

  bool _isPushLoading = false;
  String? _pushErrorMessage;

  // Getters
  List<CustomerAdvance> get filteredCustomerAdvances =>
      _filteredCustomerAdvances;
  List<CustomerAdvance> get allSupplierAdvances => _allCustomerAdvances;
  String get searchQuery => _searchQuery;
  bool get hasExpenses => _filteredCustomerAdvances.isNotEmpty;

  // Detail getters
  CustomerAdvanceWithDetails? get customerAdvanceDetail =>
      _customerAdvanceDetail;
  bool get isDetailLoading => _isDetailLoading;
  String? get detailErrorMessage => _detailErrorMessage;

  bool get isPushLoading => _isPushLoading;
  String? get pushErrorMessage => _pushErrorMessage;

  // List<Map<String, dynamic>>? expenseDetail;
  List<Map<String, dynamic>>? customerName;
  List<Map<String, dynamic>>? bankName;
  List<Map<String, dynamic>>? currencyName;
  String? nextPaymentVoucher;

  int? selectedCustomerId;
  int? selectedBankId;
  int? selectedCurrencyId;
  int? selectedPaymentVoucherId;

  String? savedCustomerAdvanceId;
  List<Map<String, dynamic>>? invoicesOfProductData;

  final Map<String, double> _availableQuantities = {};
  final bool _isLoadingAvailableQty = false;

  Map<String, double> get availableQuantities => _availableQuantities;
  bool get isLoadingAvailableQty => _isLoadingAvailableQty;

  bool _isCheckingReceipt = false;
  bool get isCheckingReceipt => _isCheckingReceipt;

  bool? _receiptExists;
  bool? get receiptExists => _receiptExists;

  String? _receiptCheckMessage;
  String? get receiptCheckMessage => _receiptCheckMessage;

  List<CustomerInvoiceForDistribution>? _customerInvoicesForDistribution;
  bool _isDistributionLoading = false;
  String? _distributionErrorMessage;
  bool _isDistributionSaving = false;

  // Distribution getters
  List<CustomerInvoiceForDistribution>? get customerInvoicesForDistribution =>
      _customerInvoicesForDistribution;
  bool get isDistributionLoading => _isDistributionLoading;
  String? get distributionErrorMessage => _distributionErrorMessage;
  bool get isDistributionSaving => _isDistributionSaving;

  String? _accountClosing;
  String? get accountClosing => _accountClosing;

  // Search functionality
  void searchExpenses(String query) {
    _searchQuery = query.toLowerCase();

    if (_searchQuery.isEmpty) {
      _filteredCustomerAdvances = List.from(_allCustomerAdvances);
    } else {
      _filteredCustomerAdvances =
          _allCustomerAdvances.where((CustomerAdvances) {
            return CustomerAdvances.receiptNumber.toLowerCase().contains(
              _searchQuery,
            );
          }).toList();
    }

    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredCustomerAdvances = List.from(_allCustomerAdvances);
    notifyListeners();
  }

  void setCustomerName(int? CustomerId) {
    selectedCustomerId = CustomerId;
    notifyListeners();
  }

  void setBankName(int? bankNameId) {
    selectedBankId = bankNameId;
    notifyListeners();
  }

  void setCurrencyName(int? currencyId) {
    selectedCurrencyId = currencyId;
    notifyListeners();
  }

  void setPaymentVoucher(int? paymentVoucherId) {
    selectedPaymentVoucherId = paymentVoucherId;
    notifyListeners();
  }

  void clearSelections() {
    selectedCustomerId = null;
    selectedBankId = null;
    selectedCurrencyId = null;
    selectedPaymentVoucherId = null;

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

  Future<void> getCustomerAdvance({bool loadMore = false}) async {
    if (!await _checkToken()) return;

    isLoading = true;
    errorMessage = null; // Clear previous errors
    notifyListeners();

    try {
      // Add retry mechanism with exponential backoff
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          final customerAdvance = await restApi.getCustomerAdvance(
            currentPage,
            totalPages,
            _getAuthHeader(),
          );

          if (customerAdvance is Map<String, dynamic>) {
            if (customerAdvance['IsSuccess'] == true) {
              final data = customerAdvance['Data'] as List<dynamic>?;
              if (data != null) {
                final newCustomerAdvanceData =
                    data.map((json) => CustomerAdvance.fromJson(json)).toList();
                if (loadMore) {
                  _allCustomerAdvances.addAll(newCustomerAdvanceData);
                } else {
                  _allCustomerAdvances =
                      newCustomerAdvanceData; // Replace list on initial load
                }
                searchExpenses(_searchQuery);
                hasMore = data.length == totalPages;

                // Success - break out of retry loop
                break;
              } else {
                errorMessage = customerAdvance['Message'] as String?;
              }
            } else {
              debugPrint('API call failed: ${customerAdvance['Message']}');
              errorMessage =
                  customerAdvance['Message'] as String? ?? 'API call failed';
            }
          } else {
            debugPrint('Unexpected API response format');
            errorMessage = 'Unexpected API response format';
          }

          // If we get here without success, break to avoid infinite retry
          break;
        } catch (e) {
          retryCount++;

          if (e is DioException && _shouldRetry(e) && retryCount < maxRetries) {
            debugPrint('Retry attempt $retryCount for error: ${e.message}');
            await Future.delayed(
              Duration(seconds: retryCount * 2),
            ); // Exponential backoff
            continue;
          } else {
            // Final attempt failed or non-retryable error
            throw e;
          }
        }
      }
    } catch (e) {
      _handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Determine if error should trigger a retry
  bool _shouldRetry(DioException e) {
    // Retry on network errors, timeouts, and DNS issues
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError ||
        (e.message?.contains('Failed host lookup') ?? false) ||
        (e.message?.contains('SocketException') ?? false) ||
        (e.response?.statusCode == 502) ||
        (e.response?.statusCode == 503) ||
        (e.response?.statusCode == 504);
  }

  void loadMore() {
    if (hasMore && !isLoading) {
      currentPage++;
      getCustomerAdvance(loadMore: true);
    }
  }

  Future<void> refresh() async {
    currentPage = 1;
    hasMore = true;
    errorMessage = null; // Clear errors on refresh
    _allCustomerAdvances.clear();
    _filteredCustomerAdvances.clear();
    _searchQuery = '';
    await getCustomerAdvance(loadMore: false);
  }

  Future<void> getCustomerAdvanceDetail(int id) async {
    if (!await _checkToken()) return;

    _isDetailLoading = true;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      final CustomerDetailData = await restApi.getCustomerAdvanceDetail(
        id: id,
        token: _getAuthHeader(),
      );

      if (CustomerDetailData['IsSuccess'] == true) {
        final data = CustomerDetailData['Data'] as Map<String, dynamic>;

        // Handle the API response structure properly
        if (data.containsKey('customer_advance')) {
          final customerAdvanceData =
              data['customer_advance'] as Map<String, dynamic>;

          // Create the CustomerAdvanceWithDetails object
          final customerAdvance = CustomerAdvance.fromJson(customerAdvanceData);

          // Create details list - empty if not provided in response
          final List<CustomerAdvanceDetail> details = [];

          // Fix: Look for 'customer_advance_detail' instead of 'details'
          if (data.containsKey('customer_advance_detail') &&
              data['customer_advance_detail'] is List) {
            final detailsList = data['customer_advance_detail'] as List;
            details.addAll(
              detailsList
                  .map((detail) => CustomerAdvanceDetail.fromJson(detail))
                  .toList(),
            );
          }

          // Create the wrapper object
          _customerAdvanceDetail = CustomerAdvanceWithDetails(
            customerAdvance: customerAdvance,
            details: details,
          );

          debugPrint('Customer advance detail loaded successfully');
        } else {
          _detailErrorMessage =
              'Invalid response format: customer_advance not found';
          debugPrint('API response missing customer_advance field');
        }
      } else {
        _detailErrorMessage =
            CustomerDetailData['Message'] ?? 'Failed to fetch Customer detail';
        debugPrint('API call failed: $_detailErrorMessage');
      }
    } catch (e) {
      _detailErrorMessage = _getErrorMessage(e);
      debugPrint('Customer detail error: $_detailErrorMessage');
      debugPrint('Exception details: $e');
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }

  void clearCustomerAdvanceDetail() {
    _customerAdvanceDetail = null;
    _detailErrorMessage = null;
    notifyListeners();
  }

  Future<void> getCustomerAdvanceBaseData() async {
    if (!await _checkToken()) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final customerAdvanceBaseData = await restApi.getCustomerAdvanceBaseList(
        token: _getAuthHeader(),
      );

      if (customerAdvanceBaseData['IsSuccess'] == true) {
        customerName = List<Map<String, dynamic>>.from(
          customerAdvanceBaseData['Data']['customers'] ?? [],
        );

        bankName = List<Map<String, dynamic>>.from(
          customerAdvanceBaseData['Data']['banks'] ?? [],
        );
        currencyName = List<Map<String, dynamic>>.from(
          customerAdvanceBaseData['Data']['currencies'],
        );
        nextPaymentVoucher =
            customerAdvanceBaseData['Data']['next_payment_voucher'];

        debugPrint('Base data fetched successfully');
      } else {
        print('API call failed: ${customerAdvanceBaseData['Message']}');
        errorMessage =
            customerAdvanceBaseData['Message'] ?? 'Failed to fetch base data';
      }
    } catch (e) {
      _handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearInvoicesOfProduct() {
    invoicesOfProductData = null;
    notifyListeners();
  }

  Future<bool> postCustomerAdvanceRegistration({
    int? customerId,
    String? receiptNumber,
    String? paymentType,
    int? bankId,
    String? accountNumber,
    String? chequeNumber,
    String? transferDate,
    String? amount,
    int? currencyId,
    String? sumOf,
    String? receiverName,
    String? description,
    List<MultipartFile>? customerAdvanceImage,
  }) async {
    if (!await _checkToken()) return false;

    try {
      final response = await restApi.postCustomerAdvance(
        token: _getAuthHeader(),
        customerId: customerId,
        receiptNumber: receiptNumber,
        paymentType: paymentType,
        bankId: bankId,
        accountNumber: accountNumber,
        chequeNumber: chequeNumber,
        transferDate: transferDate,
        amount: amount,
        currencyId: currencyId,
        sumOf: sumOf,
        receiverName: receiverName,
        description: description,
        files: customerAdvanceImage,
      );

      if (response != null && response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          getCustomerAdvance();

          notifyListeners();
        }
        return true;
      } else if (response is int) {
        savedCustomerAdvanceId = response.toString();
        return true;
      } else {
        errorMessage = 'Unexpected response format';
        return false;
      }
    } catch (e) {
      errorMessage = 'Error saving Customer advance: ${e.toString()}';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // In your SalesController class
  Future<double?> postAvailableQtyForInvoice(String? invoiceNumber) async {
    if (invoiceNumber == null || invoiceNumber.isEmpty) return null;
    if (!await _checkToken()) return null;

    try {
      final response = await restApi.postAvailableQtyForInvoiceInventory(
        token: _getAuthHeader(),
        fromInvoice: invoiceNumber,
      );

      // Fix: Access the nested Debit field inside Data
      if (response['IsSuccess'] == true &&
          response['Data'] != null &&
          response['Data']['Debit'] != null) {
        return double.tryParse(response['Data']['Debit'].toString());
      }
      return null;
    } catch (e) {
      debugPrint('Error getting available quantity: $e');
      return null;
    }
  }

  Future<bool> checkCustomerAdvanceReferenceExist(String? receiptNumber) async {
    if (receiptNumber == null || receiptNumber.isEmpty) {
      _receiptExists = null;
      _receiptCheckMessage = null;
      notifyListeners();
      return false;
    }

    _isCheckingReceipt = true;
    _receiptExists = null;
    _receiptCheckMessage = null;
    notifyListeners();

    if (!await _checkToken()) {
      _isCheckingReceipt = false;
      _receiptCheckMessage = 'Authentication failed';
      notifyListeners();
      return false;
    }

    try {
      final response = await restApi.postCheckCustomerAdvanceReferenceExist(
        token: _getAuthHeader(),
        receiptNumber: receiptNumber,
      );

      _isCheckingReceipt = false;

      if (response['IsSuccess'] == true) {
        final data = response['Data'];

        if (data == "false" || data == false) {
          _receiptExists = false;
          _receiptCheckMessage = 'Receipt number is available';
        } else {
          _receiptExists = true;
          _receiptCheckMessage =
              'Receipt number already exists. Please use a different number.';
        }
      } else {
        _receiptExists = null;
        _receiptCheckMessage =
            response['Message'] ?? 'Failed to check receipt number';
      }

      notifyListeners();
      return _receiptExists == true;
    } catch (e) {
      _isCheckingReceipt = false;
      _receiptExists = null;
      _receiptCheckMessage = 'Error checking invoice number: $e';
      notifyListeners();
      debugPrint('Error checking invoice existence: $e');
      return false;
    }
  }

  // Clear invoice check state
  void clearReceiptCheck() {
    _receiptExists = null;
    _receiptCheckMessage = null;
    _isCheckingReceipt = false;
    notifyListeners();
  }

  Future<void> deleteCustomerAdvance(int? id, String? descriptionText) async {
    if (!await _checkToken()) {
      debugPrint("Token check failed");
      return;
    }

    // Show loading state
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      debugPrint("Calling restApi.deleteSupplierAdvance...");

      final response = await restApi.deleteCustomerAdvance(
        token: _getAuthHeader(),
        id: id,
        deleteDescription: descriptionText,
      );

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          debugPrint("Delete successful, refreshing supplier advance list...");
          await getCustomerAdvance();
          showSuccessSnack('Supplier advance deleted successfully');
        } else {
          // Handle different types of errors
          String errorMsg = 'Failed to delete supplier advance';

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
                response['Message'] as String? ??
                'Failed to delete Customer advance';
          }

          errorMessage = errorMsg;
          debugPrint("Delete failed: $errorMessage");
          showErrorSnack(errorMessage.toString());
        }
      } else {
        debugPrint("Delete completed, refreshing Customer advance list...");
        await getCustomerAdvance();
        showSuccessSnack('Customer advance deleted successfully');
      }
    } catch (e) {
      debugPrint("Delete API Exception: $e");
      _handleApiError(e);
      showErrorSnack('Failed to delete Customer advance: ${e.toString()}');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getCustomerAdvancePush(int id) async {
    if (!await _checkToken()) return;

    _isPushLoading = true;
    _pushErrorMessage = null;
    notifyListeners();

    try {
      final pushCustomerAdvance = await restApi.getCustomerAdvancePush(
        id: id,
        token: _getAuthHeader(),
      );

      if (pushCustomerAdvance['IsSuccess'] == true) {
        final data = pushCustomerAdvance['Data'];
      } else {
        _pushErrorMessage =
            pushCustomerAdvance['Message'] ?? 'Failed to fetch customer detail';
        debugPrint('API call failed: $_pushErrorMessage');
      }
    } catch (e) {
      _pushErrorMessage = _getErrorMessage(e);
      debugPrint('Customer detail error: $_pushErrorMessage');
    } finally {
      _isPushLoading = false;
      notifyListeners();
    }
  }

  Future<void> getCustomerInvoicesForDistribution(
    int customerId,
    int currencyId,
  ) async {
    if (!await _checkToken()) return;

    _isDistributionLoading = true;
    _distributionErrorMessage = null;
    _customerInvoicesForDistribution = null;
    notifyListeners();

    try {
      final response = await restApi.postCustomerAdvanceDisburse(
        customerId: customerId,
        currencyId: currencyId,
        token: _getAuthHeader(),
      );

      if (response['IsSuccess'] == true) {
        final parsedData = CustomerInvoiceForDistributionData.fromJson(
          response['Data'] ?? {},
        );
        _customerInvoicesForDistribution = parsedData.sales;
        _accountClosing = parsedData.accountClosing;
      } else {
        _distributionErrorMessage =
            response['Message'] ?? 'Failed to fetch invoices for distribution';
      }
    } catch (e) {
      _distributionErrorMessage = _getErrorMessage(e);
    } finally {
      _isDistributionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> postCustomerAdvanceDistributionSave({
    required int customerAdvanceId,
    required List<int> selectedInvoiceIds,
  }) async {
    if (!await _checkToken()) {
      debugPrint('=== DEBUG: Token check failed ===');
      return false;
    }

    _isDistributionSaving = true;
    _distributionErrorMessage = null;
    notifyListeners();

    try {
      final response = await restApi.postCustomerAdvanceSaveDisburse(
        token: _getAuthHeader(),
        body: {
          "customer_advance_id": customerAdvanceId,
          "orders": selectedInvoiceIds,
        },
      );

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          final message =
              response['Data'] as String? ?? 'Distribution completed.';
          showSuccessSnack(message);
          await Future.delayed(const Duration(seconds: 2));
          await getCustomerAdvance();
          return true;
        } else {
          _distributionErrorMessage =
              response['Data'] as String? ??
              response['Message'] as String? ??
              'Failed to distribute advance';
          debugPrint(
            'Distribution API call failed: $_distributionErrorMessage',
          );
          return false;
        }
      } else {
        _distributionErrorMessage = 'Unexpected response format';
        debugPrint('Unexpected response format from distribution API');
        return false;
      }
    } catch (e) {
      debugPrint('=== DEBUG: Exception caught: $e ===');
      _distributionErrorMessage = _getErrorMessage(e);
      debugPrint('Distribution error: $_distributionErrorMessage');
      return false;
    } finally {
      _isDistributionSaving = false;
      notifyListeners();
    }
  }

  // Get user-friendly error message
  String _getErrorMessage(dynamic e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          return 'Connection timeout. Please check your internet connection.';
        case DioExceptionType.receiveTimeout:
          return 'Server response timeout. Please try again.';
        case DioExceptionType.sendTimeout:
          return 'Request timeout. Please try again.';
        case DioExceptionType.connectionError:
          if (e.message?.contains('Failed host lookup') ?? false) {
            return 'Cannot connect to server. Please check your internet connection or try again later.';
          }
          return 'Connection error. Please check your internet connection.';
        case DioExceptionType.badResponse:
          if (e.response?.statusCode == 404) {
            return 'Service not found. Please contact support.';
          } else if (e.response?.statusCode == 500) {
            return 'Server error. Please try again later.';
          }
          return 'Server error (${e.response?.statusCode}). Please try again.';
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        default:
          return 'Network error. Please check your connection and try again.';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }

  // Standardized error handling
  dynamic _handleApiError(dynamic e) {
    if (e is DioException) {
      debugPrint("Dio Exception: ${e.message}");
      debugPrint("Dio Exception Type: ${e.type}");

      // Handle redirect to login (authentication failure)
      if (e.response?.statusCode == 302 ||
          e.response?.statusCode == 401 ||
          (e.response?.data is String &&
              (e.response?.data as String).contains('login'))) {
        debugPrint("Authentication failed - redirected to login page");
        errorMessage = 'Authentication failed. Please log in again.';
        AuthRepo.handleAuthError();
        return false;
      }

      // Log detailed response information for debugging
      if (e.response != null) {
        debugPrint('Response status: ${e.response?.statusCode}');
        debugPrint('Response headers: ${e.response?.headers}');
        debugPrint('Response data: ${e.response?.data}');
      }

      // Set user-friendly error message
      errorMessage = _getErrorMessage(e);
    } else {
      debugPrint("Error: $e");
      errorMessage = 'An unexpected error occurred. Please try again.';
    }
    return false;
  }
}
