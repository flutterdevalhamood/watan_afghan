import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sample/src/models/purchase_model.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class SalesController with ChangeNotifier {
  bool isLoading = false;
  int currentPage = 1;
  final int totalPages = 10;
  bool hasMore = true;
  String? errorMessage;
  int? id;

  List<Purchase> _allPurchases = [];
  List<Purchase> _filteredPurchases = [];
  String _searchQuery = '';

  // Detail properties
  PurchaseDetail? _purchaseDetail;
  bool _isDetailLoading = false;
  String? _detailErrorMessage;

  // Getters
  List<Purchase> get purchases => _filteredPurchases;
  List<Purchase> get allPurchases => _allPurchases;
  String get searchQuery => _searchQuery;
  bool get hasExpenses => _filteredPurchases.isNotEmpty;

  // Detail getters
  PurchaseDetail? get purchaseDetail => _purchaseDetail;
  bool get isDetailLoading => _isDetailLoading;
  String? get detailErrorMessage => _detailErrorMessage;

  // List<Map<String, dynamic>>? expenseDetail;
  List<Map<String, dynamic>>? productType;
  List<Map<String, dynamic>>? currencyType;
  List<Map<String, dynamic>>? unitType;
  List<Map<String, dynamic>>? supplier;

  int? selectedProductTypeId;
  int? selectedCurrencyTypeId;
  int? selectedUnitTypeId;
  int? selectedSupplierId;

  String? savedPurchaseId;

  // Search functionality
  void searchExpenses(String query) {
    _searchQuery = query.toLowerCase();

    if (_searchQuery.isEmpty) {
      _filteredPurchases = List.from(_allPurchases);
    } else {
      _filteredPurchases =
          _allPurchases.where((purchase) {
            return purchase.InvoiceNumber.toLowerCase().contains(_searchQuery);
          }).toList();
    }

    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredPurchases = List.from(_allPurchases);
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

  void setSupplier(int? supplierId) {
    selectedSupplierId = supplierId;
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

  Future<void> getPurchaseData({bool loadMore = false}) async {
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
          final purchase = await restApi.getPurchaseData(
            currentPage,
            totalPages,
            _getAuthHeader(),
          );

          if (purchase is Map<String, dynamic>) {
            if (purchase['IsSuccess'] == true) {
              final data = purchase['Data'] as List<dynamic>?;
              if (data != null) {
                final newPurchaseData =
                    data.map((json) => Purchase.fromJson(json)).toList();
                if (loadMore) {
                  _allPurchases.addAll(newPurchaseData);
                } else {
                  _allPurchases =
                      newPurchaseData; // Replace list on initial load
                }
                searchExpenses(_searchQuery);
                hasMore = data.length == totalPages;

                // Success - break out of retry loop
                break;
              } else {
                errorMessage = purchase['Message'] as String?;
              }
            } else {
              debugPrint('API call failed: ${purchase['Message']}');
              errorMessage =
                  purchase['Message'] as String? ?? 'API call failed';
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
      getPurchaseData(loadMore: true);
    }
  }

  Future<void> refresh() async {
    currentPage = 1;
    hasMore = true;
    errorMessage = null; // Clear errors on refresh
    _allPurchases.clear();
    _filteredPurchases.clear();
    await getPurchaseData(loadMore: false);
  }

  Future<void> getPurchaseDetail(int purchaseId) async {
    if (!await _checkToken()) return;

    _isDetailLoading = true;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      final purchaseDetailData = await restApi.getPurchaseDetail(
        id: purchaseId,
        token: _getAuthHeader(),
      );

      if (purchaseDetailData['IsSuccess'] == true) {
        final data = purchaseDetailData['Data'] as Map<String, dynamic>;
        final purchaseId = purchaseDetailData['Data']['id'];
        _purchaseDetail = PurchaseDetail.fromJson(data);
        debugPrint('Supplier detail fetched: ${purchaseDetail?.purchase.id}');
      } else {
        _detailErrorMessage =
            purchaseDetailData['Message'] ?? 'Failed to fetch supplier detail';
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

  void clearPurchaseDetail() {
    _purchaseDetail = null;
    _detailErrorMessage = null;
    notifyListeners();
  }

  Future<void> getPurchaseBaseData() async {
    if (!await _checkToken()) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final purchaseBaseData = await restApi.getPurchaseBaseList(
        token: _getAuthHeader(),
      );

      if (purchaseBaseData['IsSuccess'] == true) {
        productType = List<Map<String, dynamic>>.from(
          purchaseBaseData['Data']['product'] ?? [],
        );
        currencyType = List<Map<String, dynamic>>.from(
          purchaseBaseData['Data']['currency'] ?? [],
        );
        unitType = List<Map<String, dynamic>>.from(
          purchaseBaseData['Data']['unit'],
        );
        supplier = List<Map<String, dynamic>>.from(
          purchaseBaseData['Data']['supplier'],
        );

        debugPrint('Base data fetched successfully');
      } else {
        debugPrint('API call failed: ${purchaseBaseData['Message']}');
        errorMessage =
            purchaseBaseData['Message'] ?? 'Failed to fetch base data';
      }
    } catch (e) {
      _handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> postPurchaseRegistration({
    int? supplierId,
    int? currencyId,
    String? purchaseDate,
    String? invoiceNumber,
    String? finalTotalBeforeTax,
    String? totalTax,
    String? grandTotal,
    String? customerNote,
    String? productDetails,
  }) async {
    if (!await _checkToken()) return false;

    try {
      final response = await restApi.registerPurchase(
        token: _getAuthHeader(),
        supplierId: supplierId,
        currencyId: currencyId,
        purchaseDate: purchaseDate,
        invoiceNumber: invoiceNumber,
        finalTotalBeforeTax: finalTotalBeforeTax,
        totalTax: totalTax,
        grandTotal: grandTotal,
        customerNote: customerNote,
        productDetails: productDetails,
      );

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          // Check if the response contains the ID directly or in a Data field
          if (response['Data'] != null) {
            // Case 1: ID is in the Data field (as object or direct value)
            if (response['Data'] is Map) {
              savedPurchaseId = response['Data']['id'];
            } else if (response['Data'] is int) {
              savedPurchaseId = response['Data'];
            }
          }
        }
        return true;
      } else if (response is int) {
        // Case 3: API returns just the ID as integer
        savedPurchaseId = response.toString();
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

  Future<void> deletePurchases(int? id, String? descriptionText) async {
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

      final response = await restApi.deletePurchase(
        token: _getAuthHeader(),
        id: id,
        deleteDescription: descriptionText,
      );

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          debugPrint("Delete successful, refreshing purchase list...");
          await getPurchaseData();
        } else {
          errorMessage =
              response['Message'] ?? 'Failed to delete purchase data';
          debugPrint("Delete failed: $errorMessage");
        }
      } else {
        debugPrint("Delete completed, refreshing purchase list...");
        await getPurchaseData();
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
