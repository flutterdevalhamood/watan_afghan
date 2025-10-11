import 'package:sample/src/providers/base_controller.dart';
import 'package:sample/src/util/snack.dart';

import '../data/rest_client.dart';

class InvestorTransactionController extends BaseController {
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

  Future<void> getInvestorTransaction({bool loadMore = false}) async {
    if (!await checkToken()) return;

    isLoading = true;
    notifyListeners();

    try {
      final investorTransaction = await restApi.getInvestorTransaction(
        currentPage,
        totalPages,
        getAuthHeader(),
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
        } else {}
      } else {}
    } catch (e) {
      handleApiError(e);
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
    if (!await checkToken()) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (id == null) {
        throw Exception("Customer ID is required");
      }

      final transactionDetailData = await restApi.getInvestorTransactionDetail(
        id: id,
        token: getAuthHeader(),
      );

      if (transactionDetailData['IsSuccess'] == true) {
        final data = transactionDetailData['Data'] as Map<String, dynamic>;
        transactionData = [data];
      } else {
        errorMessage =
            transactionDetailData['Message'] ??
            'Failed to fetch assigned units';
      }
    } catch (e) {
      handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getInvestorBaseData() async {
    if (!await checkToken()) return;

    isLoading = true;
    notifyListeners();

    try {
      final investorBaseData = await restApi.getInvestorTransactionBaseList(
        token: getAuthHeader(),
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
      } else {
        errorMessage =
            investorBaseData['Message'] ?? 'Failed to fetch base data';
      }
    } catch (e) {
      handleApiError(e);
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
    if (!await checkToken()) return false;

    try {
      final response = await restApi.postInvestorTransaction(
        token: getAuthHeader(),
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
        getInvestorTransaction();
        return true;
      } else if (response is Map<String, dynamic>) {
        errorMessage = response['Message'] ?? 'Failed to save transaction';
      } else {
        errorMessage = 'Unexpected response format';
      }
      return false;
    } catch (e) {
      return handleApiError(e);
    }
  }

  Future<void> deleteInvestorTransaction(
    int? id,
    String? descriptionText,
  ) async {
    if (!await checkToken()) return;

    try {
      final response = await restApi.deleteInvestorTransaction(
        token: getAuthHeader(),
        id: id,
        description: descriptionText,
      );
      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
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

          showErrorSnack(errorMessage.toString());
        }
      } else {
        await getInvestorTransaction();
        showErrorSnack(errorMessage.toString());
      }
    } catch (e) {
      handleApiError(e);
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
    if (!await checkToken()) return false;

    try {
      final reportsData = await restApi.postInvestorTransactionReport(
        token: getAuthHeader(),
        fromDate: fromDate,
        toDate: toDate,
        investorId: investorId,
        currencyId: currencyId,
      );
      if (reportsData['IsSuccess'] == true) {
        reportUrl = reportsData['Data']?['url'];
        notifyListeners();

        return true;
      } else {
        errorMessage = reportsData['Message'] ?? 'Failed to generate report';
        return false;
      }
    } catch (e) {
      return handleApiError(e);
    }
  }
}
