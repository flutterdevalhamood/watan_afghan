import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:sample/src/repo/auth_repo.dart';

import '../data/rest_client.dart';

class ReportsController with ChangeNotifier {
  final token = AuthRepo.token;

  String? salesReportUrl;
  String? purchaseReportUrl;
  String? expenseReportUrl;
  String? landscapeExpenseReportUrl;
  String? cashReportUrl;
  String? customerStatementUrl;
  String? supplierStatementUrl;
  String? errorMessage;

  Future<bool> postSalesReports(
    String? fromDate,
    String? toDate,
    int? currencyId,
  ) async {
    if (!await _checkToken()) return false;

    try {
      final salesReportsData = await restApi.postSalesTransactionReport(
        token: _getAuthHeader(),
        fromDate: fromDate,
        toDate: toDate,
        currencyId: currencyId,
      );

      print('Full salesReportsData: $salesReportsData');

      if (salesReportsData['IsSuccess'] == true) {
        final data = salesReportsData['Data'];

        // Handle different data types
        if (data is String && data.isNotEmpty) {
          // Case 1: Data is a direct URL string
          salesReportUrl = data;
        } else if (data is Map && data.containsKey('url')) {
          // Case 2: Data is an object with url property
          salesReportUrl = data['url']?.toString();
        } else {
          // Case 3: Data is null, false, or doesn't contain expected format
          debugPrint('No valid URL found in response. Data: $data');
          errorMessage = 'No report URL received from server';
          return false;
        }

        // Validate that we got a valid URL
        if (salesReportUrl == null || salesReportUrl!.isEmpty) {
          debugPrint('Empty or null URL received');
          errorMessage = 'Invalid report URL received';
          return false;
        }

        print('salesReportUrl: $salesReportUrl');
        notifyListeners();
        return true;
      } else {
        debugPrint('Report generation failed: ${salesReportsData['Message']}');
        errorMessage =
            salesReportsData['Message'] ?? 'Failed to generate report';
        return false;
      }
    } catch (e) {
      debugPrint('Exception in postSalesReports: $e');
      errorMessage = 'An error occurred while generating the report';
      return _handleApiError(e);
    }
  }

  Future<bool> postPurchaseReportsData(
    String? fromDate,
    String? toDate,
    int? currencyId,
    String? supplierId,
  ) async {
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      final purchaseReportsData = await restApi.postPurchaseReportsData(
        token: 'Bearer $token',
        fromDate: fromDate,
        toDate: toDate,
        currencyId: currencyId,
        supplierId: supplierId,
      );
      if (purchaseReportsData['IsSuccess'] == true) {
        purchaseReportUrl = purchaseReportsData['Data']?['url'];
        notifyListeners();
        print('purchaseReportUrl $purchaseReportUrl');
        return true;
      } else {
        print(
          'Fetch purchase reports data failed: ${purchaseReportsData['Message']}',
        );
        return false;
      }
    } catch (e) {
      print('Exception: $e');
      if (e is DioException) {
        // Handle Dio-specific errors
        print('Dio error: ${e.message}');
      }
      return false;
    }
  }

  Future<bool> postExpenseReportsData(
    String? fromDate,
    String? toDate,
    String? category,
    String? filter,
    int? currencyId,
  ) async {
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      final expenseReportsData = await restApi.postExpenseReportsData(
        token: 'Bearer $token',
        fromDate: fromDate,
        toDate: toDate,
        category: category,
        filter: filter,
        currencyId: currencyId,
      );
      if (expenseReportsData['IsSuccess'] == true) {
        expenseReportUrl = expenseReportsData['Data']?['url'];
        notifyListeners();
        print('expenseReportUrl $expenseReportUrl');
        return true;
      } else {
        print(
          'Fetch expense reports data failed: ${expenseReportsData['Message']}',
        );
        return false;
      }
    } catch (e) {
      print('Exception: $e');
      if (e is DioException) {
        // Handle Dio-specific errors
        print('Dio error: ${e.message}');
      }
      return false;
    }
  }

  Future<bool> postLandscapeExpenseReportsData(
    String? fromDate,
    String? toDate,
    String? category,
    String? filter,
    int? currencyId,
  ) async {
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      final landscapeExpenseReportsData = await restApi
          .postLandscapeExpenseReportsData(
            token: 'Bearer $token',
            fromDate: fromDate,
            toDate: toDate,
            category: category,
            filter: filter,
            currencyId: currencyId,
          );
      if (landscapeExpenseReportsData['IsSuccess'] == true) {
        landscapeExpenseReportUrl = landscapeExpenseReportsData['Data']?['url'];
        notifyListeners();
        print('landscapeExpenseReportUrl $landscapeExpenseReportUrl');
        return true;
      } else {
        print(
          'Fetch landscape expense reports data failed: ${landscapeExpenseReportsData['Message']}',
        );
        return false;
      }
    } catch (e) {
      print('Exception: $e');
      if (e is DioException) {
        // Handle Dio-specific errors
        print('Dio error: ${e.message}');
      }
      return false;
    }
  }

  Future<bool> postCashReports(
    String? fromDate,
    String? toDate,
    int? currencyId,
  ) async {
    if (!await _checkToken()) return false;

    try {
      final cashReportsData = await restApi.postCashReportsData(
        token: _getAuthHeader(),
        fromDate: fromDate,
        toDate: toDate,
        currencyId: currencyId,
      );

      print('Full cashReportsData: $cashReportsData');

      if (cashReportsData['IsSuccess'] == true) {
        final data = cashReportsData['Data'];

        // Clear any previous error messages
        errorMessage = null;

        // Handle the response structure properly
        if (data is Map<String, dynamic> && data.containsKey('url')) {
          // This is the expected structure: {"Data": {"url": "..."}}
          cashReportUrl = data['url']?.toString();
        } else if (data is String && data.isNotEmpty) {
          // Fallback: if Data is directly a URL string
          cashReportUrl = data;
        } else {
          debugPrint('Unexpected data structure. Data: $data');
          debugPrint('Data type: ${data.runtimeType}');
          errorMessage = 'Invalid response format from server';
          return false;
        }

        // Validate the URL
        if (cashReportUrl == null || cashReportUrl!.isEmpty) {
          debugPrint('Empty or null URL received');
          errorMessage = 'Invalid report URL received';
          return false;
        }

        // Additional URL validation
        if (!cashReportUrl!.startsWith('http')) {
          debugPrint('Invalid URL format: $cashReportUrl');
          errorMessage = 'Invalid URL format received';
          return false;
        }

        print('cashReportUrl: $cashReportUrl');
        notifyListeners();
        return true;
      } else {
        debugPrint('Report generation failed: ${cashReportsData['Message']}');
        errorMessage =
            cashReportsData['Message'] ?? 'Failed to generate report';
        return false;
      }
    } catch (e) {
      debugPrint('Exception in postCashReports: $e');
      errorMessage = 'An error occurred while generating the report';
      return _handleApiError(e);
    }
  }

  //statements
  Future<bool> postCustomerStatement(
    String? fromDate,
    String? toDate,
    int? currencyId,
    int? customerId,
  ) async {
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      final customerStatementData = await restApi.postPrintCustomerStatement(
        token: 'Bearer $token',
        fromDate: fromDate,
        toDate: toDate,
        currencyId: currencyId,
        customerId: customerId,
      );
      if (customerStatementData['IsSuccess'] == true) {
        customerStatementUrl = customerStatementData['Data']?['url'];
        notifyListeners();
        print('customerStatementUrl $customerStatementUrl');
        return true;
      } else {
        print(
          'Fetch customer statement data failed: ${customerStatementData['Message']}',
        );
        return false;
      }
    } catch (e) {
      print('Exception: $e');
      if (e is DioException) {
        // Handle Dio-specific errors
        print('Dio error: ${e.message}');
      }
      return false;
    }
  }

  Future<bool> postSupplierStatement(
    String? fromDate,
    String? toDate,
    int? currencyId,
    int? supplierId,
  ) async {
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      final supplierStatementData = await restApi.postPrintSupplierStatement(
        token: 'Bearer $token',
        fromDate: fromDate,
        toDate: toDate,
        currencyId: currencyId,
        supplierId: supplierId,
      );
      if (supplierStatementData['IsSuccess'] == true) {
        supplierStatementUrl = supplierStatementData['Data']?['url'];
        notifyListeners();
        print('supplierStatementUrl $supplierStatementUrl');
        return true;
      } else {
        print(
          'Fetch Supplier statement data failed: ${supplierStatementData['Message']}',
        );
        return false;
      }
    } catch (e) {
      print('Exception: $e');
      if (e is DioException) {
        // Handle Dio-specific errors
        print('Dio error: ${e.message}');
      }
      return false;
    }
  }

  String _getAuthHeader() {
    return 'Bearer ${AuthRepo.token}';
  }

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
}
