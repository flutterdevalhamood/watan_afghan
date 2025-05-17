import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class CurrencyConversionController with ChangeNotifier {
  bool isLoading = false;
  int currentPage = 1;
  final int totalPages = 10;
  bool hasMore = true;
  String? errorMessage;
  int? id;
  List<Map<String, dynamic>>? conversionData;
  List<Map<String, dynamic>>? currencyData;
  List<Map<String, dynamic>>? investorData;
  List<Map<String, dynamic>>? banksData;
  List<Map<String, dynamic>>? currencyConversionData;
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

  Future<void> getCurrencyConversion({bool loadMore = false}) async {
    if (!await _checkToken()) return;

    isLoading = true;
    notifyListeners();

    try {
      final currencyConversion = await restApi.getCurrencyConversion(
        currentPage,
        totalPages,
        _getAuthHeader(),
      );

      if (currencyConversion is Map<String, dynamic>) {
        if (currencyConversion['IsSuccess'] == true) {
          final data = currencyConversion['Data'] as List<dynamic>?;
          if (data != null) {
            final newCurrencyConversionData =
                data.map((v) => v as Map<String, dynamic>).toList();
            if (loadMore) {
              currencyConversionData ??= [];
              currencyConversionData!.addAll(
                newCurrencyConversionData,
              ); // Append to existing list
            } else {
              currencyConversionData =
                  newCurrencyConversionData; // Replace list on initial load
            }
            hasMore = data.length == totalPages;
          } else {
            hasMore = false;
          }
        } else {
          debugPrint('API call failed: ${currencyConversion['Message']}');
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
      getCurrencyConversion(loadMore: true);
    }
  }

  Future<void> getCurrencyConversionDetail() async {
    if (!await _checkToken()) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (id == null) {
        throw Exception("Customer ID is required");
      }

      final currencyConversionDetailData = await restApi
          .getCurrencyConversionDetail(id: id, token: _getAuthHeader());

      if (currencyConversionDetailData['IsSuccess'] == true) {
        final data =
            currencyConversionDetailData['Data'] as Map<String, dynamic>;
        conversionData = [data];
      } else {
        errorMessage =
            currencyConversionDetailData['Message'] ??
            'Failed to fetch conversion data';
      }
    } catch (e) {
      _handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getCurrencyBaseData() async {
    if (!await _checkToken()) return;

    isLoading = true;
    notifyListeners();

    try {
      final currencyBaseData = await restApi.getCurrencyConversionBaseList(
        token: _getAuthHeader(),
      );

      if (currencyBaseData['IsSuccess'] == true) {
        currencyData = List<Map<String, dynamic>>.from(
          currencyBaseData['Data']['currencies'],
        );
      } else {
        debugPrint('API call failed: ${currencyBaseData['Message']}');
        errorMessage =
            currencyBaseData['Message'] ?? 'Failed to fetch base data';
      }
    } catch (e) {
      _handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> postCurrencyConversion({
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

  Future<void> deleteCurrencyConversion(
    int? id,
    String? descriptionText,
  ) async {
    if (!await _checkToken()) return;

    try {
      await restApi.deleteCurrencyConversion(
        token: _getAuthHeader(),
        id: id,
        description: descriptionText,
      );
      await getCurrencyConversion();
    } catch (e) {
      _handleApiError(e);
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
