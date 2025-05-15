import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class InvestorTransactionController with ChangeNotifier {
  List<Map<String, dynamic>>? unitData;

  bool isLoading = false;
  final token = AuthRepo.token;
  int currentPage = 1;
  final int totalPages = 10;
  bool hasMore = true;
  String? errorMessage;
  int? id;
  List<Map<String, dynamic>>? transactionData;

  List<Map<String, dynamic>>? investorTransactionData;

  Future<void> getInvestorTransaction({bool loadMore = false}) async {
    isLoading = true;
    notifyListeners();
    try {
      if (token == null) {
        throw Exception("No token found");
      }
      final investorTransaction = await restApi.getInvestorTransaction(
        currentPage,
        totalPages,
        'Bearer $token',
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
          print('API call failed: ${investorTransaction['Message']}');
        }
      } else {
        print('Unexpected API response format');
      }
    } catch (e) {
      print('Exception: $e');
      if (e is DioException) {
        // Handle Dio-specific errors
        print('Dio error: ${e.message}');
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void loadMore() {
    if (hasMore && !isLoading) {}
    currentPage++;
    getInvestorTransaction(loadMore: true);
  }

  Future<void> getInvestorTransactionDetail() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (token == null) {
        throw Exception("No Token Found");
      }

      if (id == null) {
        throw Exception("Customer ID is required");
      }

      final transactionDetailData = await restApi.getInvestorTransactionDetail(
        id: id,
        token: 'Bearer $token',
      );

      if (transactionDetailData['IsSuccess'] == true) {
        final data = transactionDetailData['Data'] as Map<String, dynamic>;
        transactionData = [data];
        print('Assigned units fetched: ${transactionData?.length}');
      } else {
        errorMessage =
            transactionDetailData['Message'] ??
            'Failed to fetch assigned units';
        print('API call failed: $errorMessage');
      }
    } catch (e) {
      if (e is DioException) {
        errorMessage = 'Network error: ${e.message}';
        print('Dio Exception: $e');
      } else {
        errorMessage = 'Error: ${e.toString()}';
        print('Error: $e');
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Future<void> getFuelRefillDropdown() async {
  //   try {
  //     if (token == null) {
  //       throw Exception("No token found");
  //     }
  //     final dropDownData = await restApi.getRefillDropDown('Bearer $token');
  //     if (dropDownData['IsSuccess'] == true) {
  //       customerData = List<Map<String, dynamic>>.from(
  //         dropDownData['Data']['customer'],
  //       );
  //       refillUnitsData = List<Map<String, dynamic>>.from(
  //         dropDownData['Data']['refil_units'],
  //       );
  //       notifyListeners();
  //     } else {
  //       print('API call failed: ${dropDownData['Message']}');
  //     }
  //   } catch (e) {
  //     if (e is DioException) {
  //       print('Dio error: ${e.message}');
  //     }
  //   }
  // }

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
    try {
      await restApi.postInvestorTransaction(
        token: 'Bearer $token',
        transactionType: transactionType,
        totalAmount: totalAmount,
        investorId: investorId,
        paymentType: paymentType,
        bankId: bankId,
        accountNumber: accountNumber,
        transferDate: transferDate,
        referenceNumber: referenceNumber,
        personName: personName,
        description: description,
        currencyId: currencyId,
        isIncome: isIncome,
      );
      return true;
    } catch (e) {
      if (e is DioException) {
        print("Dio Exception $e");
      }
      return false;
    }
  }
}
