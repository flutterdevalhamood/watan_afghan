import 'package:sample/src/util/snack.dart';

import '../data/rest_client.dart';
import 'base_controller.dart';

class CurrencyConversionController extends BaseController {
  bool isLoading = false;
  int currentPage = 1;
  final int totalPages = 10;
  bool hasMore = true;
  String? errorMessage;
  int? id;
  List<Map<String, dynamic>>? conversionData;
  List<Map<String, dynamic>>? currencyData;
  List<Map<String, dynamic>>? banksData;
  List<Map<String, dynamic>>? currencyConversionData;
  String? reportUrl;

  Future<void> getCurrencyConversion({bool loadMore = false}) async {
    if (!await checkToken()) return;

    isLoading = true;
    notifyListeners();

    try {
      final currencyConversion = await restApi.getCurrencyConversion(
        currentPage,
        totalPages,
        getAuthHeader(),
      );

      if (currencyConversion is Map<String, dynamic>) {
        if (currencyConversion['IsSuccess'] == true) {
          final data = currencyConversion['Data'] as List<dynamic>?;
          if (data != null) {
            final newCurrencyConversionData =
                data.map((v) => v as Map<String, dynamic>).toList();
            if (loadMore) {
              currencyConversionData ??= [];
              currencyConversionData!.addAll(newCurrencyConversionData);
            } else {
              currencyConversionData = newCurrencyConversionData;
            }
            hasMore = data.length == totalPages;
          } else {
            hasMore = false;
          }
        }
      }
    } catch (e) {
      handleApiError(e, onError: (msg) => errorMessage = msg);
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
    if (!await checkToken()) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (id == null) {
        throw Exception("Customer ID is required");
      }

      final currencyConversionDetailData = await restApi
          .getCurrencyConversionDetail(id: id, token: getAuthHeader());

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
      handleApiError(e, onError: (msg) => errorMessage = msg);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getCurrencyBaseData() async {
    if (!await checkToken()) return;

    isLoading = true;
    notifyListeners();

    try {
      final currencyBaseData = await restApi.getCurrencyConversionBaseList(
        token: getAuthHeader(),
      );

      if (currencyBaseData['IsSuccess'] == true) {
        currencyData = List<Map<String, dynamic>>.from(
          currencyBaseData['Data']['currencies'],
        );
        banksData = List<Map<String, dynamic>>.from(
          currencyBaseData['Data']['banks'],
        );
      } else {
        errorMessage =
            currencyBaseData['Message'] ?? 'Failed to fetch base data';
      }
    } catch (e) {
      handleApiError(e, onError: (msg) => errorMessage = msg);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> postCurrencyConversion({
    String? fromPaymentType,
    int? fromCurrencyId,
    String? fromAmount,
    int? fromBankId,
    int? bankId,
    String? toPaymentType,
    int? toCurrencyId,
    String? toAmount,
    String? toBankId,
    String? referenceNumber,
    String? transactionDate,
    String? description,
  }) async {
    if (!await checkToken()) return false;

    try {
      final response = await restApi.postCurrencyConversion(
        token: getAuthHeader(),
        fromPaymentType: fromPaymentType,
        fromCurrencyId: fromCurrencyId,
        fromAmount: fromAmount,
        fromBankId: fromBankId,
        bankId: bankId,
        toPaymentType: toPaymentType,
        toCurrencyId: toCurrencyId,
        toAmount: toAmount,
        toBankId: toBankId,
        referenceNumber: referenceNumber,
        transactionDate: transactionDate,
        description: description,
      );

      if (response is Map<String, dynamic> && response['IsSuccess'] == true) {
        getCurrencyConversion();
        return true;
      } else if (response is Map<String, dynamic>) {
        errorMessage = response['Message'] ?? 'Failed to save transaction';
      } else {
        errorMessage = 'Unexpected response format';
      }
      return false;
    } catch (e) {
      return handleApiError(e, onError: (msg) => errorMessage = msg);
    }
  }

  Future<void> deleteCurrencyConversion(
    int? id,
    String? descriptionText,
  ) async {
    if (!await checkToken()) return;

    try {
      final response = await restApi.deleteCurrencyConversion(
        token: getAuthHeader(),
        id: id,
        description: descriptionText,
      );

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          await getCurrencyConversion();
          showSuccessSnack('Currency conversion deleted successfully');
        } else {
          final errorMsg = extractValidationError(
            response['Data'] as Map<String, dynamic>?,
            'Failed to delete currency conversion',
          );

          showErrorSnack(errorMsg);
        }
      } else {
        await getCurrencyConversion();
        showSuccessSnack('Currency conversion deleted successfully');
      }
    } catch (e) {
      handleApiError(
        e,
        onError: (msg) {
          showErrorSnack('Failed to delete currency conversion: $msg');
        },
      );
    }
  }
}
