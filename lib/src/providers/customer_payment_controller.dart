import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sample/src/models/customer_payment_model.dart';
import 'package:sample/src/util/snack.dart';

import '../data/rest_client.dart';
import '../models/customer_payment_disburse_model.dart';
import '../repo/auth_repo.dart';

class CustomerPaymentController with ChangeNotifier {
  bool isLoading = false;
  int currentPage = 1;
  final int totalPages = 10;
  bool hasMore = true;
  String? errorMessage;
  int? id;

  List<CustomerPayment> _allCustomerPayments = [];
  List<CustomerPayment> _filteredCustomerPayments = [];
  String _searchQuery = '';

  bool get hasData => _allCustomerPayments.isNotEmpty;

  // Detail properties
  CustomerPaymentDetail? _customerPaymentDetail;
  bool _isDetailLoading = false;
  String? _detailErrorMessage;

  bool _isPushLoading = false;
  String? _pushErrorMessage;

  // Getters
  List<CustomerPayment> get filteredCustomerPayments =>
      _filteredCustomerPayments;
  List<CustomerPayment> get allCustomerPayments => _allCustomerPayments;
  String get searchQuery => _searchQuery;
  bool get hasExpenses => _filteredCustomerPayments.isNotEmpty;

  // Detail getters
  CustomerPaymentDetail? get customerPaymentDetail => _customerPaymentDetail;
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

  String? savedCustomerPaymentId;
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

  // In SupplierPaymentController
  bool? validationTriggered;

  String? selectedBankAccountNumber;

  void setValidationTriggered(bool value) {
    validationTriggered = value;
    notifyListeners();
  }

  void clearCustomerAdvanceDetail() {
    _customerPaymentDetail = null;
    _detailErrorMessage = null;
    notifyListeners();
  }

  void clearInvoiceDistributionData() {
    _customerInvoicesForDistribution = null;
    _isDistributionLoading = false;
    _distributionErrorMessage = null;
    notifyListeners();
  }

  /// Enhanced clearSelections to also clear invoice data
  void clearSelectionsAndData() {
    selectedCustomerId = null;
    selectedBankId = null;
    selectedCurrencyId = null;
    selectedPaymentVoucherId = null;

    // Clear invoice distribution data
    _customerInvoicesForDistribution = null;
    _isDistributionLoading = false;
    _distributionErrorMessage = null;

    notifyListeners();
  }

  void setBankName(int? bankNameId) {
    selectedBankId = bankNameId;

    // Auto-fill account number when bank is selected
    if (bankNameId != null && bankName != null) {
      final selectedBank = bankName!.firstWhere(
        (bank) => bank['id'] == bankNameId,
        orElse: () => {},
      );
      selectedBankAccountNumber = selectedBank['account_number']?.toString();
    } else {
      selectedBankAccountNumber = null;
    }

    notifyListeners();
  }

  // Search functionality
  void searchExpenses(String query) {
    _searchQuery = query.toLowerCase();

    if (_searchQuery.isEmpty) {
      _filteredCustomerPayments = List.from(_allCustomerPayments);
    } else {
      _filteredCustomerPayments =
          _allCustomerPayments.where((supplierPayments) {
            return supplierPayments.referenceNumber.toLowerCase().contains(
              _searchQuery,
            );
          }).toList();
    }

    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredCustomerPayments = List.from(_allCustomerPayments);
    notifyListeners();
  }

  void setCustomerName(int? supplierId) {
    selectedCustomerId = supplierId;
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
    selectedBankAccountNumber = null;
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

  Future<void> getCustomerPayment({bool loadMore = false}) async {
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
          final customerPayment = await restApi.getCustomerPayment(
            currentPage,
            totalPages,
            _getAuthHeader(),
          );

          if (customerPayment is Map<String, dynamic>) {
            if (customerPayment['IsSuccess'] == true) {
              final data = customerPayment['Data'] as List<dynamic>?;
              if (data != null) {
                final newCustomerPaymentData =
                    data.map((json) => CustomerPayment.fromJson(json)).toList();
                if (loadMore) {
                  _allCustomerPayments.addAll(newCustomerPaymentData);
                } else {
                  _allCustomerPayments =
                      newCustomerPaymentData; // Replace list on initial load
                }
                searchExpenses(_searchQuery);
                hasMore = data.length == totalPages;

                // Success - break out of retry loop
                break;
              } else {
                errorMessage = customerPayment['Message'] as String?;
              }
            } else {
              debugPrint('API call failed: ${customerPayment['Message']}');
              errorMessage =
                  customerPayment['Message'] as String? ?? 'API call failed';
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
      getCustomerPayment(loadMore: true);
    }
  }

  Future<void> refresh() async {
    currentPage = 1;
    hasMore = true;
    errorMessage = null; // Clear errors on refresh
    _allCustomerPayments.clear();
    _filteredCustomerPayments.clear();
    _searchQuery = '';
    await getCustomerPayment(loadMore: false);
  }

  Future<void> getCustomerPaymentDetail(int id) async {
    if (!await _checkToken()) return;

    _isDetailLoading = true;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      final customerPaymentDetailData = await restApi.getCustomerPaymentDetail(
        id: id,
        token: _getAuthHeader(),
      );

      if (customerPaymentDetailData['IsSuccess'] == true) {
        final data = customerPaymentDetailData['Data'] as Map<String, dynamic>;

        _customerPaymentDetail = CustomerPaymentDetail.fromJson(data);

        debugPrint(
          'Successfully loaded customer payment detail with ${_customerPaymentDetail?.details.length ?? 0} details',
        );
      } else {
        _detailErrorMessage =
            customerPaymentDetailData['Message'] ??
            'Failed to fetch supplier detail';
        debugPrint('API call failed: $_detailErrorMessage');
      }
    } catch (e) {
      _detailErrorMessage = _getErrorMessage(e);
      debugPrint('Supplier detail error: $_detailErrorMessage');
      debugPrint('Error details: $e');
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }

  void clearCustomerPaymentDetail() {
    _customerPaymentDetail = null;
    _detailErrorMessage = null;
    notifyListeners();
  }

  Future<void> getCustomerPaymentBaseData() async {
    if (!await _checkToken()) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final customerPaymentBaseData = await restApi.getCustomerPaymentBaseList(
        token: _getAuthHeader(),
      );

      if (customerPaymentBaseData['IsSuccess'] == true) {
        customerName = List<Map<String, dynamic>>.from(
          customerPaymentBaseData['Data']['customers'] ?? [],
        );

        bankName = List<Map<String, dynamic>>.from(
          customerPaymentBaseData['Data']['banks'] ?? [],
        );
        currencyName = List<Map<String, dynamic>>.from(
          customerPaymentBaseData['Data']['currencies'],
        );
        nextPaymentVoucher =
            customerPaymentBaseData['Data']['next_payment_voucher'];

        debugPrint('Base data fetched successfully');
      } else {
        print('API call failed: ${customerPaymentBaseData['Message']}');
        errorMessage =
            customerPaymentBaseData['Message'] ?? 'Failed to fetch base data';
      }
    } catch (e) {
      _handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> postCustomerPaymentRegistration({
    required int supplierId,
    required String referenceNumber,
    required String paymentType,
    required int bankId,
    required String accountNumber,
    required String transferDate,
    required String totalAmount,
    required String paidAmount,
    required String amountInWords,
    required int currencyId,
    required String receiverName,
    required String description,
    List<MultipartFile>? paymentFiles,
  }) async {
    if (!await _checkToken()) return false;

    try {
      final response = await restApi.postSupplierPayment(
        token: _getAuthHeader(),
        supplierId: supplierId,
        referenceNumber: referenceNumber,
        paymentType: paymentType,
        bankId: bankId,
        accountNumber: accountNumber,
        transferDate: transferDate,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        amountInWords: amountInWords,
        currencyId: currencyId,
        receiverName: receiverName,
        description: description,
        files: paymentFiles,
      );

      if (response != null && response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          showSuccessSnack('Supplier payment registered successfully');
          await getCustomerPayment();
          notifyListeners();
          return true;
        } else {
          errorMessage = response['Message'] ?? 'Failed to register payment';
          showErrorSnack(errorMessage!);
          return false;
        }
      } else {
        errorMessage = 'Unexpected response format';
        return false;
      }
    } catch (e) {
      errorMessage = 'Error saving supplier payment: ${e.toString()}';
      showErrorSnack(errorMessage!);
      return false;
    }
  }

  Future<bool> checkCustomerPaymentReferenceExist(String? receiptNumber) async {
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
      final response = await restApi.postCheckCustomerPaymentReferenceExist(
        token: _getAuthHeader(),
        referenceNumber: receiptNumber,
      );

      _isCheckingReceipt = false;

      if (response['IsSuccess'] == true) {
        final data = response['Data'];

        // FIXED: Handle the response structure properly
        if (data != null && data is Map<String, dynamic>) {
          final referenceExists = data['reference_exists'];

          if (referenceExists == true) {
            _receiptExists = true;
            _receiptCheckMessage =
                'Receipt number already exists. Please use a different number.';
          } else {
            _receiptExists = false;
            _receiptCheckMessage = 'Receipt number is available';
          }
        } else {
          // Handle case where Data might be null or different structure
          _receiptExists = null;
          _receiptCheckMessage = 'Unable to validate receipt number';
        }
      } else {
        _receiptExists = null;
        _receiptCheckMessage =
            response['Message'] ?? 'Failed to check receipt number';

        // FIXED: Additional debugging for API response
        debugPrint('API Response: $response');
      }

      notifyListeners();
      return _receiptExists == true;
    } catch (e) {
      _isCheckingReceipt = false;
      _receiptExists = null;
      _receiptCheckMessage = 'Error checking receipt number: ${e.toString()}';
      notifyListeners();
      debugPrint('Error checking receipt existence: $e');

      // FIXED: Log detailed error information
      if (e is DioException) {
        debugPrint('Dio error: ${e.message}');
        debugPrint('Response: ${e.response}');
      }
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

  Future<void> deleteCustomerPayment(int? id, String? descriptionText) async {
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

      final response = await restApi.deleteCustomerPayment(
        token: _getAuthHeader(),
        id: id,
        deleteDescription: descriptionText,
      );

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          await getCustomerPayment();
          showSuccessSnack('Customer payment deleted successfully');
        } else {
          // Handle different types of errors
          String errorMsg = 'Failed to delete customer payment';

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
                'Failed to delete supplier advance';
          }

          errorMessage = errorMsg;
          showErrorSnack(errorMessage.toString());
        }
      } else {
        await getCustomerPayment();
        showSuccessSnack('Customer payment deleted successfully');
      }
    } catch (e) {
      _handleApiError(e);
      showErrorSnack('Failed to delete customer payment: ${e.toString()}');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getCustomerPaymentPush(int id) async {
    if (!await _checkToken()) return;

    _isPushLoading = true;
    _pushErrorMessage = null;
    notifyListeners();

    try {
      final pushCustomerPayment = await restApi.getCustomerPaymentPush(
        id: id,
        token: _getAuthHeader(),
      );

      if (pushCustomerPayment['IsSuccess'] == true) {
        final data = pushCustomerPayment['Data'];
      } else {
        _pushErrorMessage =
            pushCustomerPayment['Message'] ?? 'Failed to fetch customer detail';
      }
    } catch (e) {
      _pushErrorMessage = _getErrorMessage(e);
    } finally {
      _isPushLoading = false;
      notifyListeners();
    }
  }

  Future<void> getCustomerPaymentInvoicesForDistribution(
    int customerId,
    int currencyId,
  ) async {
    if (!await _checkToken()) return;

    _isDistributionLoading = true;
    _distributionErrorMessage = null;
    _customerInvoicesForDistribution = null;
    notifyListeners();

    try {
      final response = await restApi.postCustomerPaymentDisburse(
        customerId: customerId,
        currencyId: currencyId,
        token: _getAuthHeader(),
      );

      if (response['IsSuccess'] == true) {
        final data = response['Data'] as List<dynamic>?;
        if (data != null) {
          _customerInvoicesForDistribution =
              data
                  .map((json) => CustomerInvoiceForDistribution.fromJson(json))
                  .toList();
        } else {
          _customerInvoicesForDistribution = [];
        }
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
      // Handle redirect to login (authentication failure)
      if (e.response?.statusCode == 302 ||
          e.response?.statusCode == 401 ||
          (e.response?.data is String &&
              (e.response?.data as String).contains('login'))) {
        errorMessage = 'Authentication failed. Please log in again.';
        AuthRepo.handleAuthError();
        return false;
      }

      // Log detailed response information for debugging
      if (e.response != null) {
        debugPrint('Response status: ${e.response?.statusCode}');
      }

      // Set user-friendly error message
      errorMessage = _getErrorMessage(e);
    } else {
      errorMessage = 'An unexpected error occurred. Please try again.';
    }
    return false;
  }
}
