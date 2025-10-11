import 'package:dio/dio.dart';
import 'package:sample/src/providers/base_controller.dart';
import 'package:sample/src/repo/auth_repo.dart';

import '../data/rest_client.dart';

class ReportsController extends BaseController {
  final token = AuthRepo.token;

  String? salesReportUrl;
  String? purchaseReportUrl;
  String? expenseReportUrl;
  String? landscapeExpenseReportUrl;
  String? cashReportUrl;
  String? customerStatementUrl;
  String? supplierStatementUrl;
  String? currentStockReportWithValuesUrl;
  String? currentStockReportWithoutValuesUrl;
  String? errorMessage;

  Future<bool> postSalesReports(
    String? fromDate,
    String? toDate,
    int? currencyId,
  ) async {
    if (!await checkToken()) return false;

    try {
      final salesReportsData = await restApi.postSalesTransactionReport(
        token: getAuthHeader(),
        fromDate: fromDate,
        toDate: toDate,
        currencyId: currencyId,
      );

      if (salesReportsData['IsSuccess'] == true) {
        final data = salesReportsData['Data'];

        if (data is String && data.isNotEmpty) {
          salesReportUrl = data;
        } else if (data is Map && data.containsKey('url')) {
          salesReportUrl = data['url']?.toString();
        } else {
          errorMessage = 'No report URL received from server';
          return false;
        }

        // Validate that we got a valid URL
        if (salesReportUrl == null || salesReportUrl!.isEmpty) {
          errorMessage = 'Invalid report URL received';
          return false;
        }

        notifyListeners();
        return true;
      } else {
        errorMessage =
            salesReportsData['Message'] ?? 'Failed to generate report';
        return false;
      }
    } catch (e) {
      errorMessage = 'An error occurred while generating the report';
      return handleApiError(e);
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

        return true;
      } else {
        return false;
      }
    } catch (e) {
      if (e is DioException) {}
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

        return true;
      } else {
        return false;
      }
    } catch (e) {
      if (e is DioException) {}
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

        return true;
      } else {
        return false;
      }
    } catch (e) {
      if (e is DioException) {}
      return false;
    }
  }

  Future<bool> postCashReports(
    String? fromDate,
    String? toDate,
    int? currencyId,
  ) async {
    if (!await checkToken()) return false;

    try {
      final cashReportsData = await restApi.postCashReportsData(
        token: getAuthHeader(),
        fromDate: fromDate,
        toDate: toDate,
        currencyId: currencyId,
      );

      if (cashReportsData['IsSuccess'] == true) {
        final data = cashReportsData['Data'];

        errorMessage = null;

        if (data is Map<String, dynamic> && data.containsKey('url')) {
          // This is the expected structure: {"Data": {"url": "..."}}
          cashReportUrl = data['url']?.toString();
        } else if (data is String && data.isNotEmpty) {
          // Fallback: if Data is directly a URL string
          cashReportUrl = data;
        } else {
          errorMessage = 'Invalid response format from server';
          return false;
        }

        // Validate the URL
        if (cashReportUrl == null || cashReportUrl!.isEmpty) {
          errorMessage = 'Invalid report URL received';
          return false;
        }

        // Additional URL validation
        if (!cashReportUrl!.startsWith('http')) {
          errorMessage = 'Invalid URL format received';
          return false;
        }

        notifyListeners();
        return true;
      } else {
        errorMessage =
            cashReportsData['Message'] ?? 'Failed to generate report';
        return false;
      }
    } catch (e) {
      errorMessage = 'An error occurred while generating the report';
      return handleApiError(e);
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

        return true;
      } else {
        return false;
      }
    } catch (e) {
      if (e is DioException) {}
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

        return true;
      } else {
        return false;
      }
    } catch (e) {
      if (e is DioException) {}
      return false;
    }
  }

  Future<bool> getCurrentStockReportWithValues() async {
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      final stockReportWithValues = await restApi
          .getCurrentStockReportWithValues(token: getAuthHeader());

      if (stockReportWithValues['IsSuccess'] == true) {
        currentStockReportWithValuesUrl = stockReportWithValues['Data']?['url'];
        notifyListeners();

        return true;
      } else {
        errorMessage =
            stockReportWithValues['Message'] ?? 'Failed to fetch data';
        return false;
      }
    } catch (e) {
      handleApiError(e);
      return false;
    }
  }

  Future<bool> getCurrentStockReportWithoutValues() async {
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      final stockReportWithoutValues = await restApi
          .getCurrentStockReportWithoutValues(token: getAuthHeader());

      if (stockReportWithoutValues['IsSuccess'] == true) {
        currentStockReportWithoutValuesUrl =
            stockReportWithoutValues['Data']?['url'];
        notifyListeners();

        return true;
      } else {
        errorMessage =
            stockReportWithoutValues['Message'] ?? 'Failed to fetch data';
        return false;
      }
    } catch (e) {
      handleApiError(e);
      return false;
    }
  }
}
