import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sample/src/screens/supplier/supplier_model.dart';
import 'package:sample/src/util/snack.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class SupplierController with ChangeNotifier {
  bool isLoading = false;
  int currentPage = 1;
  final int totalPages = 10;
  bool hasMore = true;
  String? errorMessage;
  int? id;

  List<Map<String, dynamic>>? supplierDetail;
  List<Map<String, dynamic>>? companyType;
  List<Map<String, dynamic>>? paymentType;
  List<Map<String, dynamic>>? countries;
  List<Supplier> _allSuppliers = [];
  List<Supplier> _filteredSuppliers = [];
  String _searchQuery = '';

  List<Supplier> get suppliers => _filteredSuppliers;
  String get searchQuery => _searchQuery;
  bool get isEmpty => _filteredSuppliers.isEmpty && !isLoading;
  bool get hasData => _allSuppliers.isNotEmpty;

  List<Map<String, dynamic>>? _supplierDetail;
  bool _isDetailLoading = false;
  String? _detailErrorMessage;

  List<Map<String, dynamic>>? get supplierDetailData => _supplierDetail;
  bool get isDetailLoading => _isDetailLoading;
  String? get detailErrorMessage => _detailErrorMessage;

  // Search functionality
  void searchSuppliers(String query) {
    _searchQuery = query.toLowerCase();

    if (_searchQuery.isEmpty) {
      _filteredSuppliers = List.from(_allSuppliers);
    } else {
      _filteredSuppliers =
          _allSuppliers.where((customer) {
            return customer.name.toLowerCase().contains(_searchQuery) ||
                customer.mobile.toLowerCase().contains(_searchQuery);
          }).toList();
    }

    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredSuppliers = List.from(_allSuppliers);
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

  Future<void> getSupplierData({bool loadMore = false}) async {
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
          final supplier = await restApi.getSupplier(
            currentPage,
            totalPages,
            _getAuthHeader(),
          );

          if (supplier is Map<String, dynamic>) {
            if (supplier['IsSuccess'] == true) {
              final data = supplier['Data'] as List<dynamic>?;
              if (data != null) {
                final newSupplierData =
                    data.map((json) => Supplier.fromJson(json)).toList();
                if (loadMore) {
                  _allSuppliers.addAll(newSupplierData);
                } else {
                  _allSuppliers =
                      newSupplierData; // Replace list on initial load
                }
                searchSuppliers(_searchQuery);
                hasMore = data.length == totalPages;

                // Success - break out of retry loop
                break;
              } else {
                errorMessage = supplier['Message'] as String?;
              }
            } else {
              debugPrint('API call failed: ${supplier['Message']}');
              errorMessage =
                  supplier['Message'] as String? ?? 'API call failed';
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
      getSupplierData(loadMore: true);
    }
  }

  void refresh() {
    currentPage = 1;
    hasMore = true;
    errorMessage = null; // Clear errors on refresh
    _allSuppliers.clear();
    _filteredSuppliers.clear();
    _searchQuery = '';
    getSupplierData();
  }

  Future<void> getSupplierDetail(int supplierId) async {
    if (!await _checkToken()) return;

    _isDetailLoading = true;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      final supplierDetailData = await restApi.getSupplierDetail(
        id: supplierId,
        token: _getAuthHeader(),
      );

      if (supplierDetailData['IsSuccess'] == true) {
        final data = supplierDetailData['Data'] as Map<String, dynamic>;
        supplierDetail = [data];
        debugPrint('Supplier detail fetched: ${supplierDetail?.length}');
      } else {
        _detailErrorMessage =
            supplierDetailData['Message'] ?? 'Failed to fetch supplier detail';
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

  Future<void> getSupplierBaseData() async {
    if (!await _checkToken()) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final supplierBaseData = await restApi.getSupplierBaseList(
        token: _getAuthHeader(),
      );

      if (supplierBaseData['IsSuccess'] == true) {
        companyType = List<Map<String, dynamic>>.from(
          supplierBaseData['Data']['company_type'],
        );
        paymentType = List<Map<String, dynamic>>.from(
          supplierBaseData['Data']['payment_type'],
        );
        countries = List<Map<String, dynamic>>.from(
          supplierBaseData['Data']['countries'],
        );
        debugPrint('Base data fetched successfully');
      } else {
        debugPrint('API call failed: ${supplierBaseData['Message']}');
        errorMessage =
            supplierBaseData['Message'] ?? 'Failed to fetch base data';
      }
    } catch (e) {
      _handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<SupplierRegistrationResult> postSupplierRegistration({
    String? name,
    String? trnNumber,
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
    if (!await _checkToken()) {
      return SupplierRegistrationResult(
        success: false,
        message: 'Authentication failed',
      );
    }

    try {
      final response = await restApi.postSupplierRegistration(
        token: _getAuthHeader(),
        name: name,
        trnNumber: trnNumber,
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
        await getSupplierData();
        debugPrint("Supplier registration posted successfully!");
        return SupplierRegistrationResult(success: true);
      } else if (response is Map<String, dynamic>) {
        final errorMessage = response['Message'] as String? ?? 'Unknown error';
        debugPrint("Supplier registration failed: $errorMessage");

        // Check for duplicate name error
        bool isDuplicate =
            errorMessage.toLowerCase().contains('duplicate') ||
            errorMessage.toLowerCase().contains('already exists') ||
            errorMessage.toLowerCase().contains('name already') ||
            errorMessage.toLowerCase().contains('SUPPLIER AVAILABLE') ||
            errorMessage.toLowerCase().contains(' SAME TRN NUMBER') ||
            response['StatusCode'] == 401;

        // this.errorMessage = errorMessage;

        return SupplierRegistrationResult(
          success: false,
          message: errorMessage,
          isDuplicateName: isDuplicate,
        );
      } else {
        debugPrint("Unknown response format");
        // errorMessage = 'Unexpected response format';
        return SupplierRegistrationResult(
          success: false,
          message: 'Unexpected response format',
        );
      }
    } catch (e) {
      _handleApiError(e);
      // final errorMsg = _getErrorMessage(e);
      // errorMessage = errorMsg;
      return SupplierRegistrationResult(
        success: false,
        message: errorMessage ?? 'An error occurred',
      );
    }
  }

  Future<void> deleteSupplier(int? id, String? descriptionText) async {
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

      final response = await restApi.deleteSupplier(
        token: _getAuthHeader(),
        id: id,
        description: descriptionText,
      );

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          debugPrint("Delete successful, refreshing supplier list...");
          await getSupplierData();
          showSuccessSnack('Supplier deleted successfully');
        } else {
          // Handle different types of errors
          String errorMsg = 'Failed to delete supplier';

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
                response['Message'] as String? ?? 'Failed to delete supplier';
          }

          errorMessage = errorMsg;
          debugPrint("Delete failed: $errorMessage");
          showErrorSnack(errorMessage.toString());
        }
      } else {
        debugPrint("Delete completed, refreshing supplier list...");
        await getSupplierData();
        showErrorSnack(errorMessage.toString());
      }
    } catch (e) {
      debugPrint("Delete API Exception: $e");
      _handleApiError(e);
      showErrorSnack(errorMessage.toString());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Future<void> deleteSupplier(int? id, String? descriptionText) async {
  //   if (!await _checkToken()) {
  //     debugPrint("Token check failed");
  //     return;
  //   }
  //
  //   // Show loading state
  //   isLoading = true;
  //   errorMessage = null;
  //   notifyListeners();
  //
  //   try {
  //     debugPrint("Calling restApi.deleteSupplier...");
  //
  //     final response = await restApi.deleteSupplier(
  //       token: _getAuthHeader(),
  //       id: id,
  //       description: descriptionText,
  //     );
  //
  //     if (response is Map<String, dynamic>) {
  //       if (response['IsSuccess'] == true) {
  //         debugPrint("Delete successful, refreshing supplier list...");
  //         await getSupplierData();
  //         showSuccessSnack('Supplier deleted successfully');
  //       } else {
  //         errorMessage = response['Message'] ?? 'Failed to delete supplier';
  //         debugPrint("Delete failed: $errorMessage");
  //         showErrorSnack(errorMessage.toString());
  //       }
  //     } else {
  //       debugPrint("Delete completed, refreshing supplier list...");
  //       await getSupplierData();
  //       showErrorSnack(errorMessage.toString());
  //     }
  //   } catch (e) {
  //     debugPrint("Delete API Exception: $e");
  //     _handleApiError(e);
  //     showErrorSnack(errorMessage.toString());
  //   } finally {
  //     isLoading = false;
  //     notifyListeners();
  //   }
  // }

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

class SupplierRegistrationResult {
  final bool success;
  final String? message;
  final bool isDuplicateName;

  SupplierRegistrationResult({
    required this.success,
    this.message,
    this.isDuplicateName = false,
  });
}
