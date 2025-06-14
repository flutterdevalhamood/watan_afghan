import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sample/src/models/Sales_detail_model.dart';
import 'package:sample/src/models/sales_model.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class SalesController with ChangeNotifier {
  bool isLoading = false;
  int currentPage = 1;
  final int totalPages = 10;
  bool hasMore = true;
  String? errorMessage;
  int? id;

  List<Sales> _allSales = [];
  List<Sales> _filteredSales = [];
  String _searchQuery = '';

  // Detail properties
  SalesData? _salesDetail;
  bool _isDetailLoading = false;
  String? _detailErrorMessage;

  // Getters
  List<Sales> get sales => _filteredSales;
  List<Sales> get allSales => _allSales;
  String get searchQuery => _searchQuery;
  bool get hasExpenses => _filteredSales.isNotEmpty;

  // Detail getters
  SalesData? get salesDetail => _salesDetail;
  bool get isDetailLoading => _isDetailLoading;
  String? get detailErrorMessage => _detailErrorMessage;

  bool _isLoadingInvoices = false;
  bool get isLoadingInvoices => _isLoadingInvoices;

  // List<Map<String, dynamic>>? expenseDetail;
  List<Map<String, dynamic>>? productType;
  List<Map<String, dynamic>>? currencyType;
  List<Map<String, dynamic>>? unitType;
  List<Map<String, dynamic>>? customer;

  int? selectedProductTypeId;
  int? selectedCurrencyTypeId;
  int? selectedUnitTypeId;
  int? selectedCustomerId;

  String? savedSalesId;
  List<Map<String, dynamic>>? invoicesOfProductData;

  Map<String, double> _availableQuantities = {};
  bool _isLoadingAvailableQty = false;

  Map<String, double> get availableQuantities => _availableQuantities;
  bool get isLoadingAvailableQty => _isLoadingAvailableQty;

  bool _isCheckingInvoice = false;
  bool get isCheckingInvoice => _isCheckingInvoice;

  bool? _invoiceExists;
  bool? get invoiceExists => _invoiceExists;

  String? _invoiceCheckMessage;
  String? get invoiceCheckMessage => _invoiceCheckMessage;

  // Search functionality
  void searchExpenses(String query) {
    _searchQuery = query.toLowerCase();

    if (_searchQuery.isEmpty) {
      _filteredSales = List.from(_allSales);
    } else {
      _filteredSales =
          _allSales.where((sales) {
            return sales.InvoiceNumber.toLowerCase().contains(_searchQuery);
          }).toList();
    }

    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredSales = List.from(_allSales);
    notifyListeners();
  }

  void setProductType(int? productTypeId) {
    selectedProductTypeId = productTypeId;
    notifyListeners();
  }

  void setCurrencyType(int? currencyTypeId) {
    selectedCurrencyTypeId = currencyTypeId;
    notifyListeners();
  }

  void setUnitType(int? unitTypeId) {
    selectedUnitTypeId = unitTypeId;
    notifyListeners();
  }

  void setCustomer(int? customerId) {
    selectedCustomerId = customerId;
    notifyListeners();
  }

  void clearSelections() {
    selectedProductTypeId = null;
    selectedCurrencyTypeId = null;
    selectedUnitTypeId = null;
    selectedCustomerId = null;
    invoicesOfProductData = null;
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

  Future<void> getSalesData({bool loadMore = false}) async {
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
          final sales = await restApi.getSalesData(
            currentPage,
            totalPages,
            _getAuthHeader(),
          );

          if (sales is Map<String, dynamic>) {
            if (sales['IsSuccess'] == true) {
              final data = sales['Data'] as List<dynamic>?;
              if (data != null) {
                final newSalesData =
                    data.map((json) => Sales.fromJson(json)).toList();
                if (loadMore) {
                  _allSales.addAll(newSalesData);
                } else {
                  _allSales = newSalesData; // Replace list on initial load
                }
                searchExpenses(_searchQuery);
                hasMore = data.length == totalPages;

                // Success - break out of retry loop
                break;
              } else {
                errorMessage = sales['Message'] as String?;
              }
            } else {
              debugPrint('API call failed: ${sales['Message']}');
              errorMessage = sales['Message'] as String? ?? 'API call failed';
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
      getSalesData(loadMore: true);
    }
  }

  Future<void> refresh() async {
    currentPage = 1;
    hasMore = true;
    errorMessage = null; // Clear errors on refresh
    _allSales.clear();
    _filteredSales.clear();
    await getSalesData(loadMore: false);
  }

  Future<void> getSalesDetail(int salesId) async {
    if (!await _checkToken()) return;

    _isDetailLoading = true;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      final salesDetailData = await restApi.getSalesDetail(
        id: salesId,
        token: _getAuthHeader(),
      );

      if (salesDetailData['IsSuccess'] == true) {
        final data = salesDetailData['Data'] as Map<String, dynamic>;
        final salesId = salesDetailData['Data']['id'];
        _salesDetail = SalesData.fromJson(data);
        debugPrint('Supplier detail fetched: ${salesDetail?.sale?.id}');
      } else {
        _detailErrorMessage =
            salesDetailData['Message'] ?? 'Failed to fetch supplier detail';
        debugPrint('API call failed: $_detailErrorMessage');
      }
    } catch (e) {
      _detailErrorMessage = _getErrorMessage(e);
      debugPrint('Supplier detail error: $_detailErrorMessage');
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }

  void clearSalesDetail() {
    _salesDetail = null;
    _detailErrorMessage = null;
    notifyListeners();
  }

  Future<void> getSalesBaseData() async {
    if (!await _checkToken()) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final salesBaseData = await restApi.getSalesBaseList(
        token: _getAuthHeader(),
      );

      if (salesBaseData['IsSuccess'] == true) {
        productType = List<Map<String, dynamic>>.from(
          salesBaseData['Data']['products'] ?? [],
        );

        currencyType = List<Map<String, dynamic>>.from(
          salesBaseData['Data']['currency'] ?? [],
        );
        unitType = List<Map<String, dynamic>>.from(
          salesBaseData['Data']['units'],
        );
        customer = List<Map<String, dynamic>>.from(
          salesBaseData['Data']['customers'],
        );

        debugPrint('Base data fetched successfully');
      } else {
        debugPrint('API call failed: ${salesBaseData['Message']}');
        errorMessage = salesBaseData['Message'] ?? 'Failed to fetch base data';
      }
    } catch (e) {
      _handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getInvoicesOfProduct(int selectedProductTypeId) async {
    if (!await _checkToken()) return;

    // Use separate loading state for invoices to avoid affecting main screen
    _isLoadingInvoices = true;
    // Don't set main errorMessage to null here to avoid clearing other errors

    // Clear previous invoices data
    invoicesOfProductData = null;
    notifyListeners();

    try {
      final invoicesOfProductResponse = await restApi
          .getAllInvoicesOfProductFromInventory(
            id: selectedProductTypeId,
            token: _getAuthHeader(),
          );

      if (invoicesOfProductResponse['IsSuccess'] == true) {
        // Handle the API response which returns array of strings (invoice numbers)
        final invoiceNumbers = List<String>.from(
          invoicesOfProductResponse['Data'] ?? [],
        );

        // Convert string array to Map format for dropdown compatibility
        invoicesOfProductData =
            invoiceNumbers.asMap().entries.map((entry) {
              return {
                'id': entry.key.toString(), // Use index as ID
                'invoice_number': entry.value, // The actual invoice number
                'display_name':
                    entry.value, // Display name same as invoice number
              };
            }).toList();

        debugPrint(
          'Invoices data fetched successfully: ${invoicesOfProductData?.length} invoices',
        );
        debugPrint('Invoice numbers: ${invoiceNumbers.join(', ')}');
      } else {
        debugPrint('API call failed: ${invoicesOfProductResponse['Message']}');
        // Don't set main errorMessage here to avoid affecting main screen
        invoicesOfProductData = []; // Set empty list on failure
      }
    } catch (e) {
      debugPrint('Error fetching invoices: $e');
      invoicesOfProductData = []; // Set empty list on error
      // Don't call _handleApiError here as it might affect main loading state
    } finally {
      _isLoadingInvoices = false;
      notifyListeners();
    }
  }

  void clearInvoicesOfProduct() {
    invoicesOfProductData = null;
    notifyListeners();
  }

  Future<bool> postSalesRegistration({
    int? customerId,
    int? currencyId,
    String? saleDate,
    String? invoiceNumber,
    String? finalTotalBeforeTax,
    String? totalTax,
    String? grandTotal,
    String? customerNote,
    String? productDetails,
  }) async {
    if (!await _checkToken()) return false;

    try {
      final response = await restApi.registerSales(
        token: _getAuthHeader(),
        customerId: customerId,
        currencyId: currencyId,
        saleDate: saleDate,
        invoiceNumber: invoiceNumber,
        finalTotalBeforeTax: finalTotalBeforeTax,
        totalTax: totalTax,
        grandTotal: grandTotal,
        customerNote: customerNote,
        productDetails: productDetails,
      );

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          if (response['Data'] != null) {
            if (response['Data'] is Map) {
              savedSalesId = response['Data']['id'];
            } else if (response['Data'] is int) {
              savedSalesId = response['Data'];
            }
          }
        }
        return true;
      } else if (response is int) {
        savedSalesId = response.toString();
        return true;
      } else {
        errorMessage = 'Unexpected response format';
        return false;
      }
    } catch (e) {
      errorMessage = 'Error saving purchase: ${e.toString()}';
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

      if (response['IsSuccess'] == true && response['Data'] != null) {
        return double.tryParse(response['Data']?.toString() ?? '0');
      }
      return null;
    } catch (e) {
      debugPrint('Error getting available quantity: $e');
      return null;
    }
  }

  Future<bool> checkInvoiceExists(String? invoiceNumber) async {
    if (invoiceNumber == null || invoiceNumber.isEmpty) {
      _invoiceExists = null;
      _invoiceCheckMessage = null;
      notifyListeners();
      return false;
    }

    _isCheckingInvoice = true;
    _invoiceExists = null;
    _invoiceCheckMessage = null;
    notifyListeners();

    if (!await _checkToken()) {
      _isCheckingInvoice = false;
      _invoiceCheckMessage = 'Authentication failed';
      notifyListeners();
      return false;
    }

    try {
      final response = await restApi.postCheckSalesInvoiceExist(
        token: _getAuthHeader(),
        invoiceNumber: invoiceNumber,
      );

      _isCheckingInvoice = false;

      if (response['IsSuccess'] == true) {
        // Check if the response data indicates invoice exists
        // Based on your API response, it returns "false" as string when invoice doesn't exist
        final data = response['Data'];

        if (data == "false" || data == false) {
          _invoiceExists = false;
          _invoiceCheckMessage = 'Invoice number is available';
        } else {
          _invoiceExists = true;
          _invoiceCheckMessage =
              'Invoice number already exists. Please use a different number.';
        }
      } else {
        _invoiceExists = null;
        _invoiceCheckMessage =
            response['Message'] ?? 'Failed to check invoice number';
      }

      notifyListeners();
      return _invoiceExists == true;
    } catch (e) {
      _isCheckingInvoice = false;
      _invoiceExists = null;
      _invoiceCheckMessage = 'Error checking invoice number: $e';
      notifyListeners();
      debugPrint('Error checking invoice existence: $e');
      return false;
    }
  }

  // Clear invoice check state
  void clearInvoiceCheck() {
    _invoiceExists = null;
    _invoiceCheckMessage = null;
    _isCheckingInvoice = false;
    notifyListeners();
  }

  Future<void> deleteSales(int? id, String? descriptionText) async {
    if (!await _checkToken()) {
      debugPrint("Token check failed");
      return;
    }

    // Show loading state
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      debugPrint("Calling restApi.deleteSupplier...");

      final response = await restApi.deleteSales(
        token: _getAuthHeader(),
        id: id,
        deleteDescription: descriptionText,
      );

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          debugPrint("Delete successful, refreshing purchase list...");
          await getSalesData();
        } else {
          errorMessage =
              response['Message'] ?? 'Failed to delete purchase data';
          debugPrint("Delete failed: $errorMessage");
        }
      } else {
        debugPrint("Delete completed, refreshing purchase list...");
        await getSalesData();
      }
    } catch (e) {
      debugPrint("Delete API Exception: $e");
      _handleApiError(e);
    } finally {
      isLoading = false;
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
