import 'package:dio/dio.dart';
import 'package:sample/src/models/expense_model.dart';
import 'package:sample/src/providers/base_controller.dart';
import 'package:sample/src/util/snack.dart';

import '../data/rest_client.dart';

class ExpenseController extends BaseController {
  bool isLoading = false;
  int currentPage = 1;
  final int totalPages = 10;
  bool hasMore = true;
  String? errorMessage;
  int? id;

  List<Expense> _allExpenses = [];
  List<Expense> _filteredExpenses = [];
  String _searchQuery = '';

  ExpenseDetail? _expenseDetail;
  bool _isDetailLoading = false;
  String? _detailErrorMessage;

  List<Expense> get expenses => _filteredExpenses;
  List<Expense> get allExpenses => _allExpenses;
  String get searchQuery => _searchQuery;
  bool get hasExpenses => _filteredExpenses.isNotEmpty;

  ExpenseDetail? get expenseDetail => _expenseDetail;
  bool get isDetailLoading => _isDetailLoading;
  String? get detailErrorMessage => _detailErrorMessage;

  bool get hasData => _allExpenses.isNotEmpty;

  // List<Map<String, dynamic>>? expenseDetail;
  List<Map<String, dynamic>>? expenseCategory;
  List<Map<String, dynamic>>? employeeType;
  List<Map<String, dynamic>>? supplierType;
  List<Map<String, dynamic>>? banks;
  List<Map<String, dynamic>>? paymentType;
  List<Map<String, dynamic>>? currency;

  int? selectedPaymentTypeId;
  int? selectedSupplierTypeId;
  int? selectedEmployeeTypeId;
  int? selectedEmployeeId;
  int? selectedCurrencyTypeId;
  int? selectedExpenseTypeId;
  int? selectedBankTypeId;

  int? savedExpenseId;

  void searchExpenses(String query) {
    _searchQuery = query.toLowerCase();

    if (_searchQuery.isEmpty) {
      _filteredExpenses = List.from(_allExpenses);
    } else {
      _filteredExpenses =
          _allExpenses.where((expense) {
            return expense.referenceNumber.toLowerCase().contains(_searchQuery);
          }).toList();
    }

    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredExpenses = List.from(_allExpenses);
    notifyListeners();
  }

  void setPaymentType(int? paymentTypeId) {
    selectedPaymentTypeId = paymentTypeId;
    notifyListeners();
  }

  void setSupplierType(int? supplierTypeId) {
    selectedSupplierTypeId = supplierTypeId;
    notifyListeners();
  }

  void setEmployeeType(int? employeeTypeId) {
    selectedEmployeeTypeId = employeeTypeId;
    notifyListeners();
  }

  void setEmployee(int? employeeId) {
    selectedEmployeeId = employeeId;
    notifyListeners();
  }

  void setCurrencyType(int? currencyTypeId) {
    selectedCurrencyTypeId = currencyTypeId;
    notifyListeners();
  }

  void setExpenseType(int? expenseTypeId) {
    selectedExpenseTypeId = expenseTypeId;
    notifyListeners();
  }

  void setBankType(int? bankTypeId) {
    selectedBankTypeId = bankTypeId;
    notifyListeners();
  }

  void clearSelections() {
    selectedPaymentTypeId = null;
    selectedSupplierTypeId = null;
    selectedEmployeeTypeId = null;
    selectedEmployeeId = null;
    selectedCurrencyTypeId = null;
    selectedExpenseTypeId = null;
    selectedBankTypeId = null;
    savedExpenseId = null;
    notifyListeners();
  }

  Future<void> getExpenseData({bool loadMore = false}) async {
    if (!await checkToken()) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          final expense = await restApi.getExpense(
            currentPage,
            totalPages,
            getAuthHeader(),
          );

          if (expense is Map<String, dynamic>) {
            if (expense['IsSuccess'] == true) {
              final data = expense['Data'] as List<dynamic>?;
              if (data != null) {
                final newExpenseData =
                    data.map((json) => Expense.fromJson(json)).toList();
                if (loadMore) {
                  _allExpenses.addAll(newExpenseData);
                } else {
                  _allExpenses = newExpenseData;
                }
                searchExpenses(_searchQuery);
                hasMore = data.length == totalPages;

                break;
              } else {
                errorMessage = expense['Message'] as String?;
              }
            } else {
              errorMessage = expense['Message'] as String? ?? 'API call failed';
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
      getExpenseData(loadMore: true);
    }
  }

  Future<void> refresh() async {
    currentPage = 1;
    hasMore = true;
    errorMessage = null;
    _allExpenses.clear();
    _filteredExpenses.clear();
    _searchQuery = '';
    await getExpenseData(loadMore: false);
  }

  Future<void> getExpenseDetail(int expenseId) async {
    if (!await checkToken()) return;

    _isDetailLoading = true;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      final expenseDetailData = await restApi.getExpenseDetail(
        id: expenseId,
        token: getAuthHeader(),
      );

      if (expenseDetailData['IsSuccess'] == true) {
        final data = expenseDetailData['Data'] as Map<String, dynamic>;
        final expenseId = expenseDetailData['Data']['id'];
        _expenseDetail = ExpenseDetail.fromJson(data);
      } else {
        _detailErrorMessage =
            expenseDetailData['Message'] ?? 'Failed to fetch supplier detail';
      }
    } catch (e) {
      _detailErrorMessage = getErrorMessage(e);
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }

  void clearExpenseDetail() {
    _expenseDetail = null;
    _detailErrorMessage = null;
    notifyListeners();
  }

  Future<void> getExpenseBaseData() async {
    if (!await checkToken()) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final expenseBaseData = await restApi.getExpenseBaseList(
        token: getAuthHeader(),
      );

      if (expenseBaseData['IsSuccess'] == true) {
        expenseCategory = List<Map<String, dynamic>>.from(
          expenseBaseData['Data']['expense_category'] ?? [],
        );
        employeeType = List<Map<String, dynamic>>.from(
          expenseBaseData['Data']['employee'] ?? [],
        );
        supplierType = List<Map<String, dynamic>>.from(
          expenseBaseData['Data']['supplier'],
        );
        banks = List<Map<String, dynamic>>.from(
          expenseBaseData['Data']['banks'],
        );
        paymentType = List<Map<String, dynamic>>.from(
          expenseBaseData['Data']['payment_type'],
        );
        currency = List<Map<String, dynamic>>.from(
          expenseBaseData['Data']['currency'],
        );
      } else {
        errorMessage =
            expenseBaseData['Message'] ?? 'Failed to fetch base data';
      }
    } catch (e) {
      handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> postExpenseRegistration({
    int? supplierId,
    int? employeeId,
    String? expenseDate,
    String? referenceNumber,
    int? currencyId,
    String? total,
    String? subTotal,
    String? totalVat,
    String? grandTotal,
    String? expenseDetail,
    String? paymentType,
    int? bankId,
    String? transferDate,
    String? chequeNumber,
  }) async {
    if (!await checkToken()) return false;

    try {
      final response = await restApi.postExpenseRegistration(
        token: getAuthHeader(),
        supplierId: supplierId,
        employeeId: employeeId,
        expenseDate: expenseDate,
        referenceNumber: referenceNumber,
        currencyId: currencyId,
        total: total,
        subTotal: subTotal,
        totalVat: totalVat,
        grandTotal: grandTotal,
        expenseDetail: expenseDetail,
        paymentType: paymentType,
        bankId: bankId,
        transferDate: transferDate,
        chequeNumber: chequeNumber,
      );

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          if (response['Data'] != null) {
            if (response['Data'] is Map) {
              savedExpenseId = response['Data']['id'];
            } else if (response['Data'] is int) {
              savedExpenseId = response['Data'];
            }
          } else if (response['id'] != null) {
            savedExpenseId = response['id'];
          }

          if (savedExpenseId != null) {
            return true;
          } else {
            errorMessage = 'Expense saved but no ID returned';
            return false;
          }
        } else {
          errorMessage = response['Message'] ?? 'Failed to save expense';
          return false;
        }
      } else if (response is int) {
        savedExpenseId = response;
        return true;
      } else {
        errorMessage = 'Unexpected response format';
        return false;
      }
    } catch (e) {
      errorMessage = 'Error saving expense: ${e.toString()}';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteExpenses(int? id, String? descriptionText) async {
    if (!await checkToken()) {
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await restApi.deleteExpense(
        token: getAuthHeader(),
        id: id,
        description: descriptionText,
      );

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          await getExpenseData();
          showSuccessSnack('Transaction deleted successfully');
        } else {
          String errorMsg = 'Failed to delete expense data';

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
                'Failed to delete expense data';
          }

          errorMessage = errorMsg;

          showErrorSnack(errorMessage.toString());
        }
      } else {
        await getExpenseData();
        showErrorSnack(errorMessage.toString());
      }
    } catch (e) {
      handleApiError(e);
      showErrorSnack('Failed to delete expense: ${e.toString()}');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> postExpenseDocumentUpload({
    int? id,
    List<MultipartFile>? files,
  }) async {
    try {
      final postExpenseDocumentUploadData = await restApi
          .postExpenseDocumentsUpload(
            token: getAuthHeader(),
            id: id,
            files: files,
          );

      if (postExpenseDocumentUploadData['IsSuccess'] == true) {
        getExpenseData();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      if (e is DioException) {}
      return false;
    }
  }
}
