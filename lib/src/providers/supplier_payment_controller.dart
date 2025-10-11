import 'package:dio/dio.dart';
import 'package:sample/src/models/supplier_advance_disburse_model.dart';
import 'package:sample/src/models/supplier_payment_model.dart';
import 'package:sample/src/providers/base_controller.dart';
import 'package:sample/src/util/snack.dart';

import '../data/rest_client.dart';

class SupplierPaymentController extends BaseController {
  bool isLoading = false;
  int currentPage = 1;
  final int totalPages = 10;
  bool hasMore = true;
  String? errorMessage;
  int? id;

  List<SupplierPayment> _allSupplierPayments = [];
  List<SupplierPayment> _filteredSupplierPayments = [];
  String _searchQuery = '';

  bool get hasData => _allSupplierPayments.isNotEmpty;

  // Detail properties
  SupplierPaymentDetail? _supplierPaymentDetail;
  bool _isDetailLoading = false;
  String? _detailErrorMessage;

  bool _isPushLoading = false;
  String? _pushErrorMessage;

  // Getters
  List<SupplierPayment> get filteredSupplierPayments =>
      _filteredSupplierPayments;
  List<SupplierPayment> get allSupplierAdvances => _allSupplierPayments;
  String get searchQuery => _searchQuery;
  bool get hasExpenses => _filteredSupplierPayments.isNotEmpty;

  // Detail getters
  SupplierPaymentDetail? get supplierPaymentDetail => _supplierPaymentDetail;
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

  String? savedSupplierPaymentId;
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

  // In SupplierPaymentController
  bool? validationTriggered;

  String? selectedBankAccountNumber;

  void setValidationTriggered(bool value) {
    validationTriggered = value;
    notifyListeners();
  }

  void clearSupplierAdvanceDetail() {
    _supplierPaymentDetail = null;
    _detailErrorMessage = null;
    notifyListeners();
  }

  void clearInvoiceDistributionData() {
    _supplierInvoicesForDistribution = null;
    _isDistributionLoading = false;
    _distributionErrorMessage = null;
    notifyListeners();
  }

  /// Enhanced clearSelections to also clear invoice data
  void clearSelectionsAndData() {
    selectedSupplierId = null;
    selectedBankId = null;
    selectedCurrencyId = null;
    selectedPaymentVoucherId = null;

    // Clear invoice distribution data
    _supplierInvoicesForDistribution = null;
    _isDistributionLoading = false;
    _distributionErrorMessage = null;

    notifyListeners();
  }

  void setBankName(int? bankNameId) {
    selectedBankId = bankNameId;

    // Auto-fill account number when bank is selected
    if (bankNameId != null && bankName != null) {
      final selectedBank = bankName!.firstWhere(
        (bank) => bank['id'] == bankNameId,
        orElse: () => {},
      );
      selectedBankAccountNumber = selectedBank['account_number']?.toString();
    } else {
      selectedBankAccountNumber = null;
    }

    notifyListeners();
  }

  // Search functionality
  void searchExpenses(String query) {
    _searchQuery = query.toLowerCase();

    if (_searchQuery.isEmpty) {
      _filteredSupplierPayments = List.from(_allSupplierPayments);
    } else {
      _filteredSupplierPayments =
          _allSupplierPayments.where((supplierPayments) {
            return supplierPayments.referenceNumber.toLowerCase().contains(
              _searchQuery,
            );
          }).toList();
    }

    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredSupplierPayments = List.from(_allSupplierPayments);
    notifyListeners();
  }

  void setSupplierName(int? supplierId) {
    selectedSupplierId = supplierId;
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
    selectedBankAccountNumber = null;
    notifyListeners();
  }

  Future<void> getSupplierPayment({bool loadMore = false}) async {
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
          final supplierPayment = await restApi.getSupplierPayment(
            currentPage,
            totalPages,
            getAuthHeader(),
          );

          if (supplierPayment is Map<String, dynamic>) {
            if (supplierPayment['IsSuccess'] == true) {
              final data = supplierPayment['Data'] as List<dynamic>?;
              if (data != null) {
                final newSupplierPaymentData =
                    data.map((json) => SupplierPayment.fromJson(json)).toList();
                if (loadMore) {
                  _allSupplierPayments.addAll(newSupplierPaymentData);
                } else {
                  _allSupplierPayments =
                      newSupplierPaymentData; // Replace list on initial load
                }
                searchExpenses(_searchQuery);
                hasMore = data.length == totalPages;

                // Success - break out of retry loop
                break;
              } else {
                errorMessage = supplierPayment['Message'] as String?;
              }
            } else {
              errorMessage =
                  supplierPayment['Message'] as String? ?? 'API call failed';
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
      getSupplierPayment(loadMore: true);
    }
  }

  Future<void> refresh() async {
    currentPage = 1;
    hasMore = true;
    errorMessage = null; // Clear errors on refresh
    _allSupplierPayments.clear();
    _filteredSupplierPayments.clear();
    _searchQuery = '';
    await getSupplierPayment(loadMore: false);
  }

  Future<void> getSupplierPaymentDetail(int id) async {
    if (!await checkToken()) return;

    _isDetailLoading = true;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      final supplierPaymentDetailData = await restApi.getSupplierPaymentDetail(
        id: id,
        token: getAuthHeader(),
      );

      if (supplierPaymentDetailData['IsSuccess'] == true) {
        final data = supplierPaymentDetailData['Data'] as Map<String, dynamic>;

        _supplierPaymentDetail = SupplierPaymentDetail.fromJson(data);
      } else {
        _detailErrorMessage =
            supplierPaymentDetailData['Message'] ??
            'Failed to fetch supplier detail';
      }
    } catch (e) {
      _detailErrorMessage = getErrorMessage(e);
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }

  void clearSupplierPaymentDetail() {
    _supplierPaymentDetail = null;
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

  Future<bool> postSupplierPaymentRegistration({
    required int supplierId,
    required String referenceNumber,
    required String paymentType,
    required int bankId,
    required String accountNumber,
    required String transferDate,
    required String totalAmount,
    required String paidAmount,
    required String amountInWords,
    required int currencyId,
    required String receiverName,
    required String description,
    List<MultipartFile>? paymentFiles,
  }) async {
    if (!await checkToken()) return false;

    try {
      final response = await restApi.postSupplierPayment(
        token: getAuthHeader(),
        supplierId: supplierId,
        referenceNumber: referenceNumber,
        paymentType: paymentType,
        bankId: bankId,
        accountNumber: accountNumber,
        transferDate: transferDate,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        amountInWords: amountInWords,
        currencyId: currencyId,
        receiverName: receiverName,
        description: description,
        files: paymentFiles,
      );

      if (response != null && response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          showSuccessSnack('Supplier payment registered successfully');
          await getSupplierPayment();
          notifyListeners();
          return true;
        } else {
          errorMessage = response['Message'] ?? 'Failed to register payment';
          showErrorSnack(errorMessage!);
          return false;
        }
      } else {
        errorMessage = 'Unexpected response format';
        return false;
      }
    } catch (e) {
      errorMessage = 'Error saving supplier payment: ${e.toString()}';
      showErrorSnack(errorMessage!);
      return false;
    }
  }

  Future<bool> checkSupplierpaymentReferenceExist(String? receiptNumber) async {
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
      final response = await restApi.postCheckSupplierPaymentReferenceExist(
        token: getAuthHeader(),
        referenceNumber: receiptNumber,
      );

      _isCheckingReceipt = false;

      if (response['IsSuccess'] == true) {
        final data = response['Data'];

        // FIXED: Handle the response structure properly
        if (data != null && data is Map<String, dynamic>) {
          final referenceExists = data['reference_exists'];

          if (referenceExists == true) {
            _receiptExists = true;
            _receiptCheckMessage =
                'Receipt number already exists. Please use a different number.';
          } else {
            _receiptExists = false;
            _receiptCheckMessage = 'Receipt number is available';
          }
        } else {
          // Handle case where Data might be null or different structure
          _receiptExists = null;
          _receiptCheckMessage = 'Unable to validate receipt number';
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
      _receiptCheckMessage = 'Error checking receipt number: ${e.toString()}';
      notifyListeners();

      if (e is DioException) {}
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

  Future<void> deleteSupplierPayment(int? id, String? descriptionText) async {
    if (!await checkToken()) {
      return;
    }

    // Show loading state
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await restApi.deleteSupplierPayment(
        token: getAuthHeader(),
        id: id,
        deleteDescription: descriptionText,
      );

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          await getSupplierPayment();
          showSuccessSnack('Supplier payment deleted successfully');
        } else {
          // Handle different types of errors
          String errorMsg = 'Failed to delete supplier payment';

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
        await getSupplierPayment();
        showSuccessSnack('Supplier payment deleted successfully');
      }
    } catch (e) {
      handleApiError(e);
      showErrorSnack('Failed to delete supplier payment: ${e.toString()}');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getSupplierPaymentPush(int id) async {
    if (!await checkToken()) return;

    _isPushLoading = true;
    _pushErrorMessage = null;
    notifyListeners();

    try {
      final pushSupplierPayment = await restApi.getSupplierPaymentPush(
        id: id,
        token: getAuthHeader(),
      );

      if (pushSupplierPayment['IsSuccess'] == true) {
        final data = pushSupplierPayment['Data'];
      } else {
        _pushErrorMessage =
            pushSupplierPayment['Message'] ?? 'Failed to fetch supplier detail';
      }
    } catch (e) {
      _pushErrorMessage = getErrorMessage(e);
    } finally {
      _isPushLoading = false;
      notifyListeners();
    }
  }

  Future<void> getSupplierPaymentInvoicesForDistribution(
    int supplierId,
    int currencyId,
  ) async {
    if (!await checkToken()) return;

    _isDistributionLoading = true;
    _distributionErrorMessage = null;
    _supplierInvoicesForDistribution = null;
    notifyListeners();

    try {
      final response = await restApi.postSupplierPaymentDisburse(
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
