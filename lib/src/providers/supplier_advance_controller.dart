import 'package:dio/dio.dart';
import 'package:sample/src/models/supplier_advance_disburse_model.dart';
import 'package:sample/src/models/supplier_advance_model.dart';
import 'package:sample/src/providers/base_controller.dart';
import 'package:sample/src/util/snack.dart';

import '../data/rest_client.dart';

class SupplierAdvanceController extends BaseController {
  bool isLoading = false;
  int currentPage = 1;
  final int totalPages = 10;
  bool hasMore = true;
  String? errorMessage;
  int? id;

  List<SupplierAdvance> _allSupplierAdvances = [];
  List<SupplierAdvance> _filteredSupplierAdvances = [];
  String _searchQuery = '';

  bool get hasData => _allSupplierAdvances.isNotEmpty;

  // Detail properties
  SupplierAdvanceWithDetails? _supplierAdvanceDetail;
  bool _isDetailLoading = false;
  String? _detailErrorMessage;

  bool _isPushLoading = false;
  String? _pushErrorMessage;

  // Getters
  List<SupplierAdvance> get filteredSupplierAdvances =>
      _filteredSupplierAdvances;
  List<SupplierAdvance> get allSupplierAdvances => _allSupplierAdvances;
  String get searchQuery => _searchQuery;
  bool get hasExpenses => _filteredSupplierAdvances.isNotEmpty;

  // Detail getters
  SupplierAdvanceWithDetails? get supplierAdvanceDetail =>
      _supplierAdvanceDetail;
  bool get isDetailLoading => _isDetailLoading;
  String? get detailErrorMessage => _detailErrorMessage;

  bool get isPushLoading => _isPushLoading;
  String? get pushErrorMessage => _pushErrorMessage;

  // List<Map<String, dynamic>>? expenseDetail;
  List<Map<String, dynamic>>? supplierName;
  List<Map<String, dynamic>>? bankName;
  List<Map<String, dynamic>>? currencyName;
  String? nextPaymentVoucher;

  int? selectedSupplierId;
  int? selectedBankId;
  int? selectedCurrencyId;
  int? selectedPaymentVoucherId;

  String? savedSupplierAdvanceId;
  List<Map<String, dynamic>>? invoicesOfProductData;

  final Map<String, double> _availableQuantities = {};
  final bool _isLoadingAvailableQty = false;

  Map<String, double> get availableQuantities => _availableQuantities;
  bool get isLoadingAvailableQty => _isLoadingAvailableQty;

  bool _isCheckingReceipt = false;
  bool get isCheckingReceipt => _isCheckingReceipt;

  bool? _receiptExists;
  bool? get receiptExists => _receiptExists;

  String? _receiptCheckMessage;
  String? get receiptCheckMessage => _receiptCheckMessage;

  List<SupplierInvoiceForDistribution>? _supplierInvoicesForDistribution;
  bool _isDistributionLoading = false;
  String? _distributionErrorMessage;
  bool _isDistributionSaving = false;

  // Distribution getters
  List<SupplierInvoiceForDistribution>? get supplierInvoicesForDistribution =>
      _supplierInvoicesForDistribution;
  bool get isDistributionLoading => _isDistributionLoading;
  String? get distributionErrorMessage => _distributionErrorMessage;
  bool get isDistributionSaving => _isDistributionSaving;

  // Search functionality
  void searchExpenses(String query) {
    _searchQuery = query.toLowerCase();

    if (_searchQuery.isEmpty) {
      _filteredSupplierAdvances = List.from(_allSupplierAdvances);
    } else {
      _filteredSupplierAdvances =
          _allSupplierAdvances.where((supplierAdvances) {
            return supplierAdvances.receiptNumber.toLowerCase().contains(
              _searchQuery,
            );
          }).toList();
    }

    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredSupplierAdvances = List.from(_allSupplierAdvances);
    notifyListeners();
  }

  void setSupplierName(int? supplierId) {
    selectedSupplierId = supplierId;
    notifyListeners();
  }

  void setBankName(int? bankNameId) {
    selectedBankId = bankNameId;
    notifyListeners();
  }

  void setCurrencyName(int? currencyId) {
    selectedCurrencyId = currencyId;
    notifyListeners();
  }

  void setPaymentVoucher(int? paymentVoucherId) {
    selectedPaymentVoucherId = paymentVoucherId;
    notifyListeners();
  }

  void clearSelections() {
    selectedSupplierId = null;
    selectedBankId = null;
    selectedCurrencyId = null;
    selectedPaymentVoucherId = null;

    notifyListeners();
  }

  Future<void> getSupplierAdvance({bool loadMore = false}) async {
    if (!await checkToken()) return;

    isLoading = true;
    errorMessage = null; // Clear previous errors
    notifyListeners();

    try {
      // Add retry mechanism with exponential backoff
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          final supplierAdvance = await restApi.getSupplierAdvance(
            currentPage,
            totalPages,
            getAuthHeader(),
          );

          if (supplierAdvance is Map<String, dynamic>) {
            if (supplierAdvance['IsSuccess'] == true) {
              final data = supplierAdvance['Data'] as List<dynamic>?;
              if (data != null) {
                final newSupplierAdvanceData =
                    data.map((json) => SupplierAdvance.fromJson(json)).toList();
                if (loadMore) {
                  _allSupplierAdvances.addAll(newSupplierAdvanceData);
                } else {
                  _allSupplierAdvances =
                      newSupplierAdvanceData; // Replace list on initial load
                }
                searchExpenses(_searchQuery);
                hasMore = data.length == totalPages;

                // Success - break out of retry loop
                break;
              } else {
                errorMessage = supplierAdvance['Message'] as String?;
              }
            } else {
              errorMessage =
                  supplierAdvance['Message'] as String? ?? 'API call failed';
            }
          } else {
            errorMessage = 'Unexpected API response format';
          }

          // If we get here without success, break to avoid infinite retry
          break;
        } catch (e) {
          retryCount++;

          if (e is DioException && shouldRetry(e) && retryCount < maxRetries) {
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
      handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void loadMore() {
    if (hasMore && !isLoading) {
      currentPage++;
      getSupplierAdvance(loadMore: true);
    }
  }

  Future<void> refresh() async {
    currentPage = 1;
    hasMore = true;
    errorMessage = null; // Clear errors on refresh
    _allSupplierAdvances.clear();
    _filteredSupplierAdvances.clear();
    _searchQuery = '';
    await getSupplierAdvance(loadMore: false);
  }

  Future<void> getSupplierAdvanceDetail(int id) async {
    if (!await checkToken()) return;

    _isDetailLoading = true;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      final supplierDetailData = await restApi.getSupplierAdvanceDetail(
        id: id,
        token: getAuthHeader(),
      );

      if (supplierDetailData['IsSuccess'] == true) {
        final data = supplierDetailData['Data'] as Map<String, dynamic>;

        _supplierAdvanceDetail = SupplierAdvanceWithDetails.fromJson(data);
      } else {
        _detailErrorMessage =
            supplierDetailData['Message'] ?? 'Failed to fetch supplier detail';
      }
    } catch (e) {
      _detailErrorMessage = getErrorMessage(e);
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }

  void clearSupplierAdvanceDetail() {
    _supplierAdvanceDetail = null;
    _detailErrorMessage = null;
    notifyListeners();
  }

  Future<void> getSupplierAdvanceBaseData() async {
    if (!await checkToken()) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final supplierAdvanceBaseData = await restApi.getSupplierAdvanceBaseList(
        token: getAuthHeader(),
      );

      if (supplierAdvanceBaseData['IsSuccess'] == true) {
        supplierName = List<Map<String, dynamic>>.from(
          supplierAdvanceBaseData['Data']['suppliers'] ?? [],
        );

        bankName = List<Map<String, dynamic>>.from(
          supplierAdvanceBaseData['Data']['banks'] ?? [],
        );
        currencyName = List<Map<String, dynamic>>.from(
          supplierAdvanceBaseData['Data']['currencies'],
        );
        nextPaymentVoucher =
            supplierAdvanceBaseData['Data']['next_payment_voucher'];
      } else {
        errorMessage =
            supplierAdvanceBaseData['Message'] ?? 'Failed to fetch base data';
      }
    } catch (e) {
      handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> postSupplierAdvanceDistributionSave({
    required int supplierAdvanceId,
    required List<int> selectedInvoiceIds,
  }) async {
    if (!await checkToken()) {
      return false;
    }

    _isDistributionSaving = true;
    _distributionErrorMessage = null;
    notifyListeners();

    try {
      final response = await restApi.postSupplierAdvanceSaveDisburse(
        token: getAuthHeader(),
        body: {
          "supplier_advance_id": supplierAdvanceId,
          "orders": selectedInvoiceIds,
        },
      );

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          final message =
              response['Data'] as String? ?? 'Distribution completed.';
          showSuccessSnack(message);
          await Future.delayed(const Duration(seconds: 2));
          await getSupplierAdvance();
          return true;
        } else {
          _distributionErrorMessage =
              response['Data'] as String? ??
              response['Message'] as String? ??
              'Failed to distribute advance';

          return false;
        }
      } else {
        _distributionErrorMessage = 'Unexpected response format';

        return false;
      }
    } catch (e) {
      _distributionErrorMessage = getErrorMessage(e);

      return false;
    } finally {
      _isDistributionSaving = false;
      notifyListeners();
    }
  }

  void clearInvoicesOfProduct() {
    invoicesOfProductData = null;
    notifyListeners();
  }

  Future<bool> postSupplierAdvanceRegistration({
    int? supplierId,
    String? receiptNumber,
    String? paymentType,
    int? bankId,
    String? accountNumber,
    String? chequeNumber,
    String? transferDate,
    String? amount,
    int? currencyId,
    String? sumOf,
    String? receiverName,
    String? description,
    List<MultipartFile>? supplierAdvanceImage,
  }) async {
    if (!await checkToken()) return false;

    try {
      final response = await restApi.postSupplierAdvance(
        token: getAuthHeader(),
        supplierId: supplierId,
        receiptNumber: receiptNumber,
        paymentType: paymentType,
        bankId: bankId,
        accountNumber: accountNumber,
        chequeNumber: chequeNumber,
        transferDate: transferDate,
        amount: amount,
        currencyId: currencyId,
        sumOf: sumOf,
        receiverName: receiverName,
        description: description,
        files: supplierAdvanceImage,
      );

      if (response != null && response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          getSupplierAdvance();

          notifyListeners();
        }
        return true;
      } else if (response is int) {
        savedSupplierAdvanceId = response.toString();
        return true;
      } else {
        errorMessage = 'Unexpected response format';
        return false;
      }
    } catch (e) {
      errorMessage = 'Error saving supplier advance: ${e.toString()}';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // In your SalesController class
  Future<double?> postAvailableQtyForInvoice(String? invoiceNumber) async {
    if (invoiceNumber == null || invoiceNumber.isEmpty) return null;
    if (!await checkToken()) return null;

    try {
      final response = await restApi.postAvailableQtyForInvoiceInventory(
        token: getAuthHeader(),
        fromInvoice: invoiceNumber,
      );

      // Fix: Access the nested Debit field inside Data
      if (response['IsSuccess'] == true &&
          response['Data'] != null &&
          response['Data']['Debit'] != null) {
        return double.tryParse(response['Data']['Debit'].toString());
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> checkSupplierAdvanceReferenceExist(String? receiptNumber) async {
    if (receiptNumber == null || receiptNumber.isEmpty) {
      _receiptExists = null;
      _receiptCheckMessage = null;
      notifyListeners();
      return false;
    }

    _isCheckingReceipt = true;
    _receiptExists = null;
    _receiptCheckMessage = null;
    notifyListeners();

    if (!await checkToken()) {
      _isCheckingReceipt = false;
      _receiptCheckMessage = 'Authentication failed';
      notifyListeners();
      return false;
    }

    try {
      final response = await restApi.postCheckSupplierAdvanceReferenceExist(
        token: getAuthHeader(),
        receiptNumber: receiptNumber,
      );

      _isCheckingReceipt = false;

      if (response['IsSuccess'] == true) {
        final data = response['Data'];

        if (data == "false" || data == false) {
          _receiptExists = false;
          _receiptCheckMessage = 'Receipt number is available';
        } else {
          _receiptExists = true;
          _receiptCheckMessage =
              'Receipt number already exists. Please use a different number.';
        }
      } else {
        _receiptExists = null;
        _receiptCheckMessage =
            response['Message'] ?? 'Failed to check receipt number';
      }

      notifyListeners();
      return _receiptExists == true;
    } catch (e) {
      _isCheckingReceipt = false;
      _receiptExists = null;
      _receiptCheckMessage = 'Error checking invoice number: $e';
      notifyListeners();

      return false;
    }
  }

  // Clear invoice check state
  void clearReceiptCheck() {
    _receiptExists = null;
    _receiptCheckMessage = null;
    _isCheckingReceipt = false;
    notifyListeners();
  }

  Future<void> deleteSupplierAdvance(int? id, String? descriptionText) async {
    if (!await checkToken()) {
      return;
    }

    // Show loading state
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await restApi.deleteSupplierAdvance(
        token: getAuthHeader(),
        id: id,
        deleteDescription: descriptionText,
      );

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          await getSupplierAdvance();
          showSuccessSnack('Supplier advance deleted successfully');
        } else {
          // Handle different types of errors
          String errorMsg = 'Failed to delete supplier advance';

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
                'Failed to delete supplier advance';
          }

          errorMessage = errorMsg;

          showErrorSnack(errorMessage.toString());
        }
      } else {
        await getSupplierAdvance();
        showSuccessSnack('Supplier advance deleted successfully');
      }
    } catch (e) {
      handleApiError(e);
      showErrorSnack('Failed to delete supplier advance: ${e.toString()}');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getSupplierAdvancePush(int id) async {
    if (!await checkToken()) return;

    _isPushLoading = true;
    _pushErrorMessage = null;
    notifyListeners();

    try {
      final pushSupplierAdvance = await restApi.getSupplierAdvancePush(
        id: id,
        token: getAuthHeader(),
      );

      if (pushSupplierAdvance['IsSuccess'] == true) {
        final data = pushSupplierAdvance['Data'];
      } else {
        _pushErrorMessage =
            pushSupplierAdvance['Message'] ?? 'Failed to fetch supplier detail';
      }
    } catch (e) {
      _pushErrorMessage = getErrorMessage(e);
    } finally {
      _isPushLoading = false;
      notifyListeners();
    }
  }

  Future<void> getSupplierInvoicesForDistribution(
    int supplierId,
    int currencyId,
  ) async {
    if (!await checkToken()) return;

    _isDistributionLoading = true;
    _distributionErrorMessage = null;
    _supplierInvoicesForDistribution = null;
    notifyListeners();

    try {
      final response = await restApi.postSupplierAdvanceDisburse(
        supplierId: supplierId,
        currencyId: currencyId,
        token: getAuthHeader(),
      );

      if (response['IsSuccess'] == true) {
        final data = response['Data'] as List<dynamic>?;
        if (data != null) {
          _supplierInvoicesForDistribution =
              data
                  .map((json) => SupplierInvoiceForDistribution.fromJson(json))
                  .toList();
        } else {
          _supplierInvoicesForDistribution = [];
        }
      } else {
        _distributionErrorMessage =
            response['Message'] ?? 'Failed to fetch invoices for distribution';
      }
    } catch (e) {
      _distributionErrorMessage = getErrorMessage(e);
    } finally {
      _isDistributionLoading = false;
      notifyListeners();
    }
  }
}
