import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sample/src/models/expense_model.dart';
import 'package:sample/src/util/snack.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class ExpenseController with ChangeNotifier {
  bool isLoading = false;
  int currentPage = 1;
  final int totalPages = 10;
  bool hasMore = true;
  String? errorMessage;
  int? id;

  List<Expense> _allExpenses = [];
  List<Expense> _filteredExpenses = [];
  String _searchQuery = '';

  // Detail properties
  ExpenseDetail? _expenseDetail;
  bool _isDetailLoading = false;
  String? _detailErrorMessage;

  // Getters
  List<Expense> get expenses => _filteredExpenses;
  List<Expense> get allExpenses => _allExpenses;
  String get searchQuery => _searchQuery;
  bool get hasExpenses => _filteredExpenses.isNotEmpty;

  // Detail getters
  ExpenseDetail? get expenseDetail => _expenseDetail;
  bool get isDetailLoading => _isDetailLoading;
  String? get detailErrorMessage => _detailErrorMessage;

  bool get hasData => _allExpenses.isNotEmpty;

  // List<Map<String, dynamic>>? expenseDetail;
  List<Map<String, dynamic>>? expenseCategory;
  List<Map<String, dynamic>>? employeeType;
  List<Map<String, dynamic>>? supplierType;
  List<Map<String, dynamic>>? banks;
  List<Map<String, dynamic>>? paymentType;
  List<Map<String, dynamic>>? currency;

  int? selectedPaymentTypeId;
  int? selectedSupplierTypeId;
  int? selectedEmployeeTypeId;
  int? selectedEmployeeId;
  int? selectedCurrencyTypeId;
  int? selectedExpenseTypeId;
  int? selectedBankTypeId;

  int? savedExpenseId;

  // Search functionality
  void searchExpenses(String query) {
    _searchQuery = query.toLowerCase();

    if (_searchQuery.isEmpty) {
      _filteredExpenses = List.from(_allExpenses);
    } else {
      _filteredExpenses =
          _allExpenses.where((expense) {
            return expense.referenceNumber.toLowerCase().contains(_searchQuery);
          }).toList();
    }

    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredExpenses = List.from(_allExpenses);
    notifyListeners();
  }

  void setPaymentType(int? paymentTypeId) {
    selectedPaymentTypeId = paymentTypeId;
    notifyListeners();
  }

  void setSupplierType(int? supplierTypeId) {
    selectedSupplierTypeId = supplierTypeId;
    notifyListeners();
  }

  void setEmployeeType(int? employeeTypeId) {
    selectedEmployeeTypeId = employeeTypeId;
    notifyListeners();
  }

  void setEmployee(int? employeeId) {
    selectedEmployeeId = employeeId;
    notifyListeners();
  }

  void setCurrencyType(int? currencyTypeId) {
    selectedCurrencyTypeId = currencyTypeId;
    notifyListeners();
  }

  void setExpenseType(int? expenseTypeId) {
    selectedExpenseTypeId = expenseTypeId;
    notifyListeners();
  }

  void setBankType(int? bankTypeId) {
    selectedBankTypeId = bankTypeId;
    notifyListeners();
  }

  void clearSelections() {
    selectedPaymentTypeId = null;
    selectedSupplierTypeId = null;
    selectedEmployeeTypeId = null;
    selectedEmployeeId = null;
    selectedCurrencyTypeId = null;
    selectedExpenseTypeId = null;
    selectedBankTypeId = null;
    savedExpenseId = null;
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

  Future<void> getExpenseData({bool loadMore = false}) async {
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
          final expense = await restApi.getExpense(
            currentPage,
            totalPages,
            _getAuthHeader(),
          );

          if (expense is Map<String, dynamic>) {
            if (expense['IsSuccess'] == true) {
              final data = expense['Data'] as List<dynamic>?;
              if (data != null) {
                final newExpenseData =
                    data.map((json) => Expense.fromJson(json)).toList();
                if (loadMore) {
                  _allExpenses.addAll(newExpenseData);
                } else {
                  _allExpenses = newExpenseData; // Replace list on initial load
                }
                searchExpenses(_searchQuery);
                hasMore = data.length == totalPages;

                // Success - break out of retry loop
                break;
              } else {
                errorMessage = expense['Message'] as String?;
              }
            } else {
              debugPrint('API call failed: ${expense['Message']}');
              errorMessage = expense['Message'] as String? ?? 'API call failed';
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
      getExpenseData(loadMore: true);
    }
  }

  Future<void> refresh() async {
    currentPage = 1;
    hasMore = true;
    errorMessage = null; // Clear errors on refresh
    _allExpenses.clear();
    _filteredExpenses.clear();
    _searchQuery = '';
    await getExpenseData(loadMore: false);
  }

  Future<void> getExpenseDetail(int expenseId) async {
    if (!await _checkToken()) return;

    _isDetailLoading = true;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      final expenseDetailData = await restApi.getExpenseDetail(
        id: expenseId,
        token: _getAuthHeader(),
      );

      if (expenseDetailData['IsSuccess'] == true) {
        final data = expenseDetailData['Data'] as Map<String, dynamic>;
        final expenseId = expenseDetailData['Data']['id'];
        _expenseDetail = ExpenseDetail.fromJson(data);
        debugPrint('Supplier detail fetched: ${expenseDetail?.id}');
      } else {
        _detailErrorMessage =
            expenseDetailData['Message'] ?? 'Failed to fetch supplier detail';
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

  void clearExpenseDetail() {
    _expenseDetail = null;
    _detailErrorMessage = null;
    notifyListeners();
  }

  Future<void> getExpenseBaseData() async {
    if (!await _checkToken()) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final expenseBaseData = await restApi.getExpenseBaseList(
        token: _getAuthHeader(),
      );

      if (expenseBaseData['IsSuccess'] == true) {
        expenseCategory = List<Map<String, dynamic>>.from(
          expenseBaseData['Data']['expense_category'] ?? [],
        );
        employeeType = List<Map<String, dynamic>>.from(
          expenseBaseData['Data']['employee'] ?? [],
        );
        supplierType = List<Map<String, dynamic>>.from(
          expenseBaseData['Data']['supplier'],
        );
        banks = List<Map<String, dynamic>>.from(
          expenseBaseData['Data']['banks'],
        );
        paymentType = List<Map<String, dynamic>>.from(
          expenseBaseData['Data']['payment_type'],
        );
        currency = List<Map<String, dynamic>>.from(
          expenseBaseData['Data']['currency'],
        );
        debugPrint('Base data fetched successfully');
      } else {
        debugPrint('API call failed: ${expenseBaseData['Message']}');
        errorMessage =
            expenseBaseData['Message'] ?? 'Failed to fetch base data';
      }
    } catch (e) {
      _handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> postExpenseRegistration({
    int? supplierId,
    int? employeeId,
    String? expenseDate,
    String? referenceNumber,
    int? currencyId,
    String? total,
    String? subTotal,
    String? totalVat,
    String? grandTotal,
    String? expenseDetail,
    String? paymentType,
    int? bankId,
    String? transferDate,
    String? chequeNumber,
  }) async {
    if (!await _checkToken()) return false;

    try {
      final response = await restApi.postExpenseRegistration(
        token: _getAuthHeader(),
        supplierId: supplierId,
        employeeId: employeeId,
        expenseDate: expenseDate,
        referenceNumber: referenceNumber,
        currencyId: currencyId,
        total: total,
        subTotal: subTotal,
        totalVat: totalVat,
        grandTotal: grandTotal,
        expenseDetail: expenseDetail,
        paymentType: paymentType,
        bankId: bankId,
        transferDate: transferDate,
        chequeNumber: chequeNumber,
      );

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          // Check if the response contains the ID directly or in a Data field
          if (response['Data'] != null) {
            // Case 1: ID is in the Data field (as object or direct value)
            if (response['Data'] is Map) {
              savedExpenseId = response['Data']['id'];
            } else if (response['Data'] is int) {
              savedExpenseId = response['Data'];
            }
          } else if (response['id'] != null) {
            // Case 2: ID is at root level
            savedExpenseId = response['id'];
          }

          if (savedExpenseId != null) {
            return true;
          } else {
            errorMessage = 'Expense saved but no ID returned';
            return false;
          }
        } else {
          errorMessage = response['Message'] ?? 'Failed to save expense';
          return false;
        }
      } else if (response is int) {
        // Case 3: API returns just the ID as integer
        savedExpenseId = response;
        return true;
      } else {
        errorMessage = 'Unexpected response format';
        return false;
      }
    } catch (e) {
      errorMessage = 'Error saving expense: ${e.toString()}';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteExpenses(int? id, String? descriptionText) async {
    if (!await _checkToken()) {
      debugPrint("Token check failed");
      return;
    }

    // Show loading state
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      debugPrint("Calling restApi.deleteExpense...");

      final response = await restApi.deleteExpense(
        token: _getAuthHeader(),
        id: id,
        description: descriptionText,
      );

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          debugPrint("Delete successful, refreshing expense list...");
          await getExpenseData();
          showSuccessSnack('Transaction deleted successfully');
        } else {
          // Handle different types of errors
          String errorMsg = 'Failed to delete expense data';

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
                'Failed to delete expense data';
          }

          errorMessage = errorMsg;
          debugPrint("Delete failed: $errorMessage");
          showErrorSnack(errorMessage.toString());
        }
      } else {
        debugPrint("Delete completed, refreshing expense list...");
        await getExpenseData();
        showErrorSnack(errorMessage.toString());
      }
    } catch (e) {
      debugPrint("Delete API Exception: $e");
      _handleApiError(e);
      showErrorSnack('Failed to delete expense: ${e.toString()}');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> postExpenseDocumentUpload({
    int? id,
    List<MultipartFile>? files,
  }) async {
    try {
      final postExpenseDocumentUploadData = await restApi
          .postExpenseDocumentsUpload(
            token: _getAuthHeader(),
            id: id,
            files: files,
          );

      if (postExpenseDocumentUploadData['IsSuccess'] == true) {
        getExpenseData();
        return true;
      } else {
        print('API call failed: ${postExpenseDocumentUploadData['Message']}');
        return false;
      }
    } catch (e) {
      if (e is DioException) {
        print("Dio Exception $e");
      }
      return false;
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
