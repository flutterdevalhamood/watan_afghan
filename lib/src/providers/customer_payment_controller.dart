import 'package:dio/dio.dart';
import 'package:sample/src/models/customer_payment_model.dart';
import 'package:sample/src/providers/base_controller.dart';
import 'package:sample/src/util/snack.dart';

import '../data/rest_client.dart';
import '../models/customer_payment_disburse_model.dart';

class CustomerPaymentController extends BaseController {
  bool isLoading = false;
  int currentPage = 1;
  final int totalPages = 10;
  bool hasMore = true;
  String? errorMessage;
  int? id;

  List<CustomerPayment> _allCustomerPayments = [];
  List<CustomerPayment> _filteredCustomerPayments = [];
  String _searchQuery = '';

  bool get hasData => _allCustomerPayments.isNotEmpty;

  CustomerPaymentDetail? _customerPaymentDetail;
  bool _isDetailLoading = false;
  String? _detailErrorMessage;

  bool _isPushLoading = false;
  String? _pushErrorMessage;

  List<CustomerPayment> get filteredCustomerPayments =>
      _filteredCustomerPayments;
  List<CustomerPayment> get allCustomerPayments => _allCustomerPayments;
  String get searchQuery => _searchQuery;
  bool get hasExpenses => _filteredCustomerPayments.isNotEmpty;

  CustomerPaymentDetail? get customerPaymentDetail => _customerPaymentDetail;
  bool get isDetailLoading => _isDetailLoading;
  String? get detailErrorMessage => _detailErrorMessage;

  bool get isPushLoading => _isPushLoading;
  String? get pushErrorMessage => _pushErrorMessage;

  // List<Map<String, dynamic>>? expenseDetail;
  List<Map<String, dynamic>>? customerName;
  List<Map<String, dynamic>>? bankName;
  List<Map<String, dynamic>>? currencyName;
  String? nextPaymentVoucher;

  int? selectedCustomerId;
  int? selectedBankId;
  int? selectedCurrencyId;
  int? selectedPaymentVoucherId;

  String? savedCustomerPaymentId;
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

  List<CustomerInvoiceForDistribution>? _customerInvoicesForDistribution;
  bool _isDistributionLoading = false;
  String? _distributionErrorMessage;
  bool _isDistributionSaving = false;

  List<CustomerInvoiceForDistribution>? get customerInvoicesForDistribution =>
      _customerInvoicesForDistribution;
  bool get isDistributionLoading => _isDistributionLoading;
  String? get distributionErrorMessage => _distributionErrorMessage;
  bool get isDistributionSaving => _isDistributionSaving;

  bool? validationTriggered;

  String? selectedBankAccountNumber;

  void setValidationTriggered(bool value) {
    validationTriggered = value;
    notifyListeners();
  }

  void clearCustomerAdvanceDetail() {
    _customerPaymentDetail = null;
    _detailErrorMessage = null;
    notifyListeners();
  }

  void clearInvoiceDistributionData() {
    _customerInvoicesForDistribution = null;
    _isDistributionLoading = false;
    _distributionErrorMessage = null;
    notifyListeners();
  }

  void clearSelectionsAndData() {
    selectedCustomerId = null;
    selectedBankId = null;
    selectedCurrencyId = null;
    selectedPaymentVoucherId = null;

    _customerInvoicesForDistribution = null;
    _isDistributionLoading = false;
    _distributionErrorMessage = null;

    notifyListeners();
  }

  void setBankName(int? bankNameId) {
    selectedBankId = bankNameId;

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

  void searchExpenses(String query) {
    _searchQuery = query.toLowerCase();

    if (_searchQuery.isEmpty) {
      _filteredCustomerPayments = List.from(_allCustomerPayments);
    } else {
      _filteredCustomerPayments =
          _allCustomerPayments.where((customerPayments) {
            return customerPayments.referenceNumber.toLowerCase().contains(
              _searchQuery,
            );
          }).toList();
    }

    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredCustomerPayments = List.from(_allCustomerPayments);
    notifyListeners();
  }

  void setCustomerName(int? customerId) {
    selectedCustomerId = customerId;
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
    selectedCustomerId = null;
    selectedBankId = null;
    selectedCurrencyId = null;
    selectedPaymentVoucherId = null;
    selectedBankAccountNumber = null;
    notifyListeners();
  }

  Future<void> getCustomerPayment({bool loadMore = false}) async {
    if (!await checkToken()) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          final customerPayment = await restApi.getCustomerPayment(
            currentPage,
            totalPages,
            getAuthHeader(),
          );

          if (customerPayment is Map<String, dynamic>) {
            if (customerPayment['IsSuccess'] == true) {
              final data = customerPayment['Data'] as List<dynamic>?;
              if (data != null) {
                final newCustomerPaymentData =
                    data.map((json) => CustomerPayment.fromJson(json)).toList();
                if (loadMore) {
                  _allCustomerPayments.addAll(newCustomerPaymentData);
                } else {
                  _allCustomerPayments = newCustomerPaymentData;
                }
                searchExpenses(_searchQuery);
                hasMore = data.length == totalPages;

                break;
              } else {
                errorMessage = customerPayment['Message'] as String?;
              }
            } else {
              errorMessage =
                  customerPayment['Message'] as String? ?? 'API call failed';
            }
          } else {
            errorMessage = 'Unexpected API response format';
          }

          break;
        } catch (e) {
          retryCount++;

          if (e is DioException && shouldRetry(e) && retryCount < maxRetries) {
            await Future.delayed(Duration(seconds: retryCount * 2));
            continue;
          } else {
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
      getCustomerPayment(loadMore: true);
    }
  }

  Future<void> refresh() async {
    currentPage = 1;
    hasMore = true;
    errorMessage = null;
    _allCustomerPayments.clear();
    _filteredCustomerPayments.clear();
    _searchQuery = '';
    await getCustomerPayment(loadMore: false);
  }

  Future<void> getCustomerPaymentDetail(int id) async {
    if (!await checkToken()) return;

    _isDetailLoading = true;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      final customerPaymentDetailData = await restApi.getCustomerPaymentDetail(
        id: id,
        token: getAuthHeader(),
      );

      if (customerPaymentDetailData['IsSuccess'] == true) {
        final data = customerPaymentDetailData['Data'] as Map<String, dynamic>;

        _customerPaymentDetail = CustomerPaymentDetail.fromJson(data);
      } else {
        _detailErrorMessage =
            customerPaymentDetailData['Message'] ??
            'Failed to fetch customer detail';
      }
    } catch (e) {
      _detailErrorMessage = getErrorMessage(e);
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }

  void clearCustomerPaymentDetail() {
    _customerPaymentDetail = null;
    _detailErrorMessage = null;
    notifyListeners();
  }

  Future<void> getCustomerPaymentBaseData() async {
    if (!await checkToken()) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final customerPaymentBaseData = await restApi.getCustomerPaymentBaseList(
        token: getAuthHeader(),
      );

      if (customerPaymentBaseData['IsSuccess'] == true) {
        customerName = List<Map<String, dynamic>>.from(
          customerPaymentBaseData['Data']['customers'] ?? [],
        );

        bankName = List<Map<String, dynamic>>.from(
          customerPaymentBaseData['Data']['banks'] ?? [],
        );
        currencyName = List<Map<String, dynamic>>.from(
          customerPaymentBaseData['Data']['currencies'],
        );
        nextPaymentVoucher =
            customerPaymentBaseData['Data']['next_payment_voucher'];
      } else {
        errorMessage =
            customerPaymentBaseData['Message'] ?? 'Failed to fetch base data';
      }
    } catch (e) {
      handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> postCustomerPaymentRegistration({
    required int customerId,
    required String referenceNumber,
    required String paymentType,
    required int bankId,
    required String accountNumber,
    required String paymentReceiveDate,
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
      final response = await restApi.postCustomerPayment(
        token: getAuthHeader(),
        customerId: customerId,
        referenceNumber: referenceNumber,
        paymentType: paymentType,
        bankId: bankId,
        accountNumber: accountNumber,
        paymentReceiveDate: paymentReceiveDate,
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
          showSuccessSnack('Customer payment registered successfully');
          await getCustomerPayment();
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
      errorMessage = 'Error saving customer payment: ${e.toString()}';
      showErrorSnack(errorMessage!);
      return false;
    }
  }

  Future<bool> checkCustomerPaymentReferenceExist(String? receiptNumber) async {
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
      final response = await restApi.postCheckCustomerPaymentReferenceExist(
        token: getAuthHeader(),
        referenceNumber: receiptNumber,
      );

      _isCheckingReceipt = false;

      if (response['IsSuccess'] == true) {
        final data = response['Data'];

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

  void clearReceiptCheck() {
    _receiptExists = null;
    _receiptCheckMessage = null;
    _isCheckingReceipt = false;
    notifyListeners();
  }

  Future<void> deleteCustomerPayment(int? id, String? descriptionText) async {
    if (!await checkToken()) {
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await restApi.deleteCustomerPayment(
        token: getAuthHeader(),
        id: id,
        deleteDescription: descriptionText,
      );

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          await getCustomerPayment();
          showSuccessSnack('Customer payment deleted successfully');
        } else {
          String errorMsg = 'Failed to delete customer payment';

          if (response['Data'] != null &&
              response['Data'] is Map<String, dynamic>) {
            final data = response['Data'] as Map<String, dynamic>;

            if (data['deleteDescription'] != null &&
                data['deleteDescription'] is List) {
              final deleteDescriptionErrors = data['deleteDescription'] as List;
              if (deleteDescriptionErrors.isNotEmpty) {
                errorMsg = deleteDescriptionErrors.first.toString();
              }
            } else if (data.isNotEmpty) {
              final firstError = data.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                errorMsg = firstError.first.toString();
              }
            }
          } else {
            errorMsg =
                response['Message'] as String? ??
                'Failed to delete supplier advance';
          }

          errorMessage = errorMsg;
          showErrorSnack(errorMessage.toString());
        }
      } else {
        await getCustomerPayment();
        showSuccessSnack('Customer payment deleted successfully');
      }
    } catch (e) {
      handleApiError(e);
      showErrorSnack('Failed to delete customer payment: ${e.toString()}');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getCustomerPaymentPush(int id) async {
    if (!await checkToken()) return;

    _isPushLoading = true;
    _pushErrorMessage = null;
    notifyListeners();

    try {
      final pushCustomerPayment = await restApi.getCustomerPaymentPush(
        id: id,
        token: getAuthHeader(),
      );

      if (pushCustomerPayment['IsSuccess'] == true) {
        final data = pushCustomerPayment['Data'];
      } else {
        _pushErrorMessage =
            pushCustomerPayment['Message'] ?? 'Failed to fetch customer detail';
      }
    } catch (e) {
      _pushErrorMessage = getErrorMessage(e);
    } finally {
      _isPushLoading = false;
      notifyListeners();
    }
  }

  Future<void> getCustomerPaymentInvoicesForDistribution(
    int customerId,
    int currencyId,
  ) async {
    if (!await checkToken()) return;

    _isDistributionLoading = true;
    _distributionErrorMessage = null;
    _customerInvoicesForDistribution = null;
    notifyListeners();

    try {
      final response = await restApi.postCustomerPaymentDisburse(
        customerId: customerId,
        currencyId: currencyId,
        token: getAuthHeader(),
      );

      if (response['IsSuccess'] == true) {
        final data = response['Data'] as List<dynamic>?;
        if (data != null) {
          _customerInvoicesForDistribution =
              data
                  .map((json) => CustomerInvoiceForDistribution.fromJson(json))
                  .toList();
        } else {
          _customerInvoicesForDistribution = [];
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
