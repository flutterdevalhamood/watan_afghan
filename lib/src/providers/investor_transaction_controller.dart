import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sample/src/util/snack.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class InvestorTransactionController with ChangeNotifier {
  bool isLoading = false;
  int currentPage = 1;
  final int totalPages = 10;
  bool hasMore = true;
  String? errorMessage;
  int? id;
  List<Map<String, dynamic>>? transactionData;
  List<Map<String, dynamic>>? currencyData;
  List<Map<String, dynamic>>? investorData;
  List<Map<String, dynamic>>? banksData;
  List<Map<String, dynamic>>? investorTransactionData;
  String? reportUrl;

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

  Future<void> getInvestorTransaction({bool loadMore = false}) async {
    if (!await _checkToken()) return;

    isLoading = true;
    notifyListeners();

    try {
      final investorTransaction = await restApi.getInvestorTransaction(
        currentPage,
        totalPages,
        _getAuthHeader(),
      );

      if (investorTransaction is Map<String, dynamic>) {
        if (investorTransaction['IsSuccess'] == true) {
          final data = investorTransaction['Data'] as List<dynamic>?;
          if (data != null) {
            final newInvestorTransactionData =
                data.map((v) => v as Map<String, dynamic>).toList();
            if (loadMore) {
              investorTransactionData ??= [];
              investorTransactionData!.addAll(
                newInvestorTransactionData,
              ); // Append to existing list
            } else {
              investorTransactionData =
                  newInvestorTransactionData; // Replace list on initial load
            }
            hasMore = data.length == totalPages;
          } else {
            hasMore = false;
          }
        } else {
          debugPrint('API call failed: ${investorTransaction['Message']}');
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
      getInvestorTransaction(loadMore: true);
    }
  }

  Future<void> getInvestorTransactionDetail() async {
    if (!await _checkToken()) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (id == null) {
        throw Exception("Customer ID is required");
      }

      final transactionDetailData = await restApi.getInvestorTransactionDetail(
        id: id,
        token: _getAuthHeader(),
      );

      if (transactionDetailData['IsSuccess'] == true) {
        final data = transactionDetailData['Data'] as Map<String, dynamic>;
        transactionData = [data];
        debugPrint('Assigned units fetched: ${transactionData?.length}');
      } else {
        errorMessage =
            transactionDetailData['Message'] ??
            'Failed to fetch assigned units';
        debugPrint('API call failed: $errorMessage');
      }
    } catch (e) {
      _handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getInvestorBaseData() async {
    if (!await _checkToken()) return;

    isLoading = true;
    notifyListeners();

    try {
      final investorBaseData = await restApi.getInvestorTransactionBaseList(
        token: _getAuthHeader(),
      );

      if (investorBaseData['IsSuccess'] == true) {
        currencyData = List<Map<String, dynamic>>.from(
          investorBaseData['Data']['currencies'],
        );
        investorData = List<Map<String, dynamic>>.from(
          investorBaseData['Data']['investors'],
        );
        banksData = List<Map<String, dynamic>>.from(
          investorBaseData['Data']['banks'],
        );
        debugPrint('Base data fetched successfully');
      } else {
        debugPrint('API call failed: ${investorBaseData['Message']}');
        errorMessage =
            investorBaseData['Message'] ?? 'Failed to fetch base data';
      }
    } catch (e) {
      _handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> postInvestorTransaction({
    String? transactionType,
    String? totalAmount,
    int? investorId,
    String? paymentType,
    int? bankId,
    String? accountNumber,
    String? transferDate,
    String? referenceNumber,
    String? personName,
    String? description,
    String? currencyId,
    String? isIncome,
  }) async {
    if (!await _checkToken()) return false;

    // Debug logging
    debugPrint("Posting transaction with payment type: $paymentType");
    debugPrint("Transaction type: $transactionType");
    debugPrint("Investor ID: $investorId");

    try {
      final response = await restApi.postInvestorTransaction(
        token: _getAuthHeader(),
        transactionType:
            transactionType
                ?.toLowerCase(), // Ensure lowercase to match API expectations
        totalAmount: totalAmount,
        investorId: investorId,
        paymentType:
            paymentType
                ?.toLowerCase(), // Ensure lowercase to match API expectations
        bankId: bankId,
        accountNumber: accountNumber,
        transferDate: transferDate,
        referenceNumber: referenceNumber,
        personName: personName,
        description: description,
        currencyId: currencyId,
        isIncome: isIncome,
      );

      // Check response
      if (response is Map<String, dynamic> && response['IsSuccess'] == true) {
        debugPrint("Transaction posted successfully!");
        getInvestorTransaction();
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

  Future<void> deleteInvestorTransaction(
    int? id,
    String? descriptionText,
  ) async {
    if (!await _checkToken()) return;

    try {
      final response = await restApi.deleteInvestorTransaction(
        token: _getAuthHeader(),
        id: id,
        description: descriptionText,
      );
      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          debugPrint(
            "Delete successful, refreshing investor transaction list...",
          );
          await getInvestorTransaction();
          showSuccessSnack('Transaction deleted successfully');
        } else {
          // Handle different types of errors
          String errorMsg = 'Failed to delete investor transaction data';

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
                'Failed to delete investor transaction data';
          }

          errorMessage = errorMsg;
          debugPrint("Delete failed: $errorMessage");
          showErrorSnack(errorMessage.toString());
        }
      } else {
        debugPrint("Delete completed, refreshing investor transaction list...");
        await getInvestorTransaction();
        showErrorSnack(errorMessage.toString());
      }
    } catch (e) {
      debugPrint("Delete API Exception: $e");
      _handleApiError(e);
      showErrorSnack('Failed to delete investor transaction: ${e.toString()}');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> postInvestorTransactionReports(
    String? fromDate,
    String? toDate,
    int? investorId,
    int? currencyId,
  ) async {
    if (!await _checkToken()) return false;

    try {
      final reportsData = await restApi.postInvestorTransactionReport(
        token: _getAuthHeader(),
        fromDate: fromDate,
        toDate: toDate,
        investorId: investorId,
        currencyId: currencyId,
      );
      if (reportsData['IsSuccess'] == true) {
        reportUrl = reportsData['Data']?['url'];
        notifyListeners();
        debugPrint('Report URL: $reportUrl');
        return true;
      } else {
        debugPrint('Fetch reports data failed: ${reportsData['Message']}');
        errorMessage = reportsData['Message'] ?? 'Failed to generate report';
        return false;
      }
    } catch (e) {
      return _handleApiError(e);
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
