import 'package:dio/dio.dart';
import 'package:sample/src/models/Sales_detail_model.dart';
import 'package:sample/src/models/sales_model.dart';
import 'package:sample/src/providers/base_controller.dart';
import 'package:sample/src/util/snack.dart';

import '../data/rest_client.dart';

class SalesController extends BaseController {
  bool isLoading = false;
  int currentPage = 1;
  final int totalPages = 10;
  bool hasMore = true;
  String? errorMessage;
  int? id;

  List<Sales> _allSales = [];
  List<Sales> _filteredSales = [];
  String _searchQuery = '';

  // Detail properties
  SalesData? _salesDetail;
  bool _isDetailLoading = false;
  String? _detailErrorMessage;

  // Getters
  List<Sales> get sales => _filteredSales;
  List<Sales> get allSales => _allSales;
  String get searchQuery => _searchQuery;
  bool get hasExpenses => _filteredSales.isNotEmpty;

  // Detail getters
  SalesData? get salesDetail => _salesDetail;
  bool get isDetailLoading => _isDetailLoading;
  String? get detailErrorMessage => _detailErrorMessage;

  bool _isLoadingInvoices = false;
  bool get isLoadingInvoices => _isLoadingInvoices;

  bool get hasData => _allSales.isNotEmpty;

  // List<Map<String, dynamic>>? expenseDetail;
  List<Map<String, dynamic>>? productType;
  List<Map<String, dynamic>>? currencyType;
  List<Map<String, dynamic>>? unitType;
  List<Map<String, dynamic>>? customer;
  String? nextInvoiceNumber;

  int? selectedProductTypeId;
  int? selectedCurrencyTypeId;
  int? selectedUnitTypeId;
  int? selectedCustomerId;

  String? savedSalesId;
  List<Map<String, dynamic>>? invoicesOfProductData;

  final Map<String, double> _availableQuantities = {};
  final bool _isLoadingAvailableQty = false;

  Map<String, double> get availableQuantities => _availableQuantities;
  bool get isLoadingAvailableQty => _isLoadingAvailableQty;

  bool _isCheckingInvoice = false;
  bool get isCheckingInvoice => _isCheckingInvoice;

  bool? _invoiceExists;
  bool? get invoiceExists => _invoiceExists;

  String? _invoiceCheckMessage;
  String? get invoiceCheckMessage => _invoiceCheckMessage;

  String? salesPdfUrl;

  String? salesReportUrl;

  // Search functionality
  void searchExpenses(String query) {
    _searchQuery = query.toLowerCase();

    if (_searchQuery.isEmpty) {
      _filteredSales = List.from(_allSales);
    } else {
      _filteredSales =
          _allSales.where((sales) {
            return sales.InvoiceNumber.toLowerCase().contains(_searchQuery);
          }).toList();
    }

    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredSales = List.from(_allSales);
    notifyListeners();
  }

  void setProductType(int? productTypeId) {
    selectedProductTypeId = productTypeId;
    notifyListeners();
  }

  void setCurrencyType(int? currencyTypeId) {
    selectedCurrencyTypeId = currencyTypeId;
    notifyListeners();
  }

  void setUnitType(int? unitTypeId) {
    selectedUnitTypeId = unitTypeId;
    notifyListeners();
  }

  void setCustomer(int? customerId) {
    selectedCustomerId = customerId;
    notifyListeners();
  }

  void setInvoiceNumber(String invoiceNumber) {
    invoiceNumber = invoiceNumber;
    notifyListeners();
  }

  void clearSelections() {
    selectedProductTypeId = null;
    selectedCurrencyTypeId = null;
    selectedUnitTypeId = null;
    selectedCustomerId = null;
    invoicesOfProductData = null;

    notifyListeners();
  }

  Future<void> getSalesData({bool loadMore = false}) async {
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
          final sales = await restApi.getSalesData(
            currentPage,
            totalPages,
            getAuthHeader(),
          );

          if (sales is Map<String, dynamic>) {
            if (sales['IsSuccess'] == true) {
              final data = sales['Data'] as List<dynamic>?;
              if (data != null) {
                final newSalesData =
                    data.map((json) => Sales.fromJson(json)).toList();
                if (loadMore) {
                  _allSales.addAll(newSalesData);
                } else {
                  _allSales = newSalesData; // Replace list on initial load
                }
                searchExpenses(_searchQuery);
                hasMore = data.length == totalPages;

                // Success - break out of retry loop
                break;
              } else {
                errorMessage = sales['Message'] as String?;
              }
            } else {
              errorMessage = sales['Message'] as String? ?? 'API call failed';
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
      getSalesData(loadMore: true);
    }
  }

  Future<void> refresh() async {
    currentPage = 1;
    hasMore = true;
    errorMessage = null; // Clear errors on refresh
    _allSales.clear();
    _filteredSales.clear();
    _searchQuery = '';
    await getSalesData(loadMore: false);
  }

  Future<void> getSalesDetail(int salesId) async {
    if (!await checkToken()) return;

    _isDetailLoading = true;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      final salesDetailData = await restApi.getSalesDetail(
        id: salesId,
        token: getAuthHeader(),
      );

      if (salesDetailData['IsSuccess'] == true) {
        final data = salesDetailData['Data'] as Map<String, dynamic>;
        final salesId = salesDetailData['Data']['id'];
        _salesDetail = SalesData.fromJson(data);
      } else {
        _detailErrorMessage =
            salesDetailData['Message'] ?? 'Failed to fetch supplier detail';
      }
    } catch (e) {
      _detailErrorMessage = getErrorMessage(e);
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }

  void clearSalesDetail() {
    _salesDetail = null;
    _detailErrorMessage = null;
    notifyListeners();
  }

  Future<void> getSalesBaseData() async {
    if (!await checkToken()) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final salesBaseData = await restApi.getSalesBaseList(
        token: getAuthHeader(),
      );

      if (salesBaseData['IsSuccess'] == true) {
        productType = List<Map<String, dynamic>>.from(
          salesBaseData['Data']['products'] ?? [],
        );

        currencyType = List<Map<String, dynamic>>.from(
          salesBaseData['Data']['currency'] ?? [],
        );
        unitType = List<Map<String, dynamic>>.from(
          salesBaseData['Data']['units'],
        );
        customer = List<Map<String, dynamic>>.from(
          salesBaseData['Data']['customers'],
        );
        nextInvoiceNumber = salesBaseData['Data']['next_invoice_number'];
      } else {
        errorMessage = salesBaseData['Message'] ?? 'Failed to fetch base data';
      }
    } catch (e) {
      handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getInvoicesOfProduct(int selectedProductTypeId) async {
    if (!await checkToken()) return;

    _isLoadingInvoices = true;
    invoicesOfProductData = null;
    notifyListeners();

    try {
      final invoicesOfProductResponse = await restApi
          .getAllInvoicesOfProductFromInventory(
            id: selectedProductTypeId,
            token: getAuthHeader(),
          );

      if (invoicesOfProductResponse['IsSuccess'] == true) {
        final invoiceNumbers = List<String>.from(
          invoicesOfProductResponse['Data'] ?? [],
        );

        invoicesOfProductData =
            invoiceNumbers.asMap().entries.map((entry) {
              return {
                'id': entry.key.toString(),
                'invoice_number': entry.value,
                'display_name': entry.value,
              };
            }).toList();
      } else {
        invoicesOfProductData = []; // Set empty list on failure
      }
    } catch (e) {
      invoicesOfProductData = []; // Set empty list on error
      // Don't call handleApiError here as it might affect main loading state
    } finally {
      _isLoadingInvoices = false;
      notifyListeners();
    }
  }

  void clearInvoicesOfProduct() {
    invoicesOfProductData = null;
    notifyListeners();
  }

  Future<bool> postSalesRegistration({
    int? customerId,
    int? currencyId,
    String? saleDate,
    String? invoiceNumber,
    String? finalTotalBeforeTax,
    String? totalTax,
    String? grandTotal,
    String? customerNote,
    String? productDetails,
  }) async {
    if (!await checkToken()) return false;

    try {
      final response = await restApi.registerSales(
        token: getAuthHeader(),
        customerId: customerId,
        currencyId: currencyId,
        saleDate: saleDate,
        invoiceNumber: invoiceNumber,
        finalTotalBeforeTax: finalTotalBeforeTax,
        totalTax: totalTax,
        grandTotal: grandTotal,
        customerNote: customerNote,
        productDetails: productDetails,
      );

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          getSalesData();
          if (response['Data'] != null) {
            if (response['Data'] is Map) {
              savedSalesId = response['Data']['id'];
            } else if (response['Data'] is int) {
              savedSalesId = response['Data'];
            }
          }
        }
        return true;
      } else if (response is int) {
        savedSalesId = response.toString();
        return true;
      } else {
        errorMessage = 'Unexpected response format';
        return false;
      }
    } catch (e) {
      errorMessage = 'Error saving purchase: ${e.toString()}';
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

  Future<bool> checkInvoiceExists(String? invoiceNumber) async {
    if (invoiceNumber == null || invoiceNumber.isEmpty) {
      _invoiceExists = null;
      _invoiceCheckMessage = null;
      notifyListeners();
      return false;
    }

    _isCheckingInvoice = true;
    _invoiceExists = null;
    _invoiceCheckMessage = null;
    notifyListeners();

    if (!await checkToken()) {
      _isCheckingInvoice = false;
      _invoiceCheckMessage = 'Authentication failed';
      notifyListeners();
      return false;
    }

    try {
      final response = await restApi.postCheckSalesInvoiceExist(
        token: getAuthHeader(),
        invoiceNumber: invoiceNumber,
      );

      _isCheckingInvoice = false;

      if (response['IsSuccess'] == true) {
        final data = response['Data'];

        if (data == "false" || data == false) {
          _invoiceExists = false;
          _invoiceCheckMessage = 'Invoice number is available';
        } else {
          _invoiceExists = true;
          _invoiceCheckMessage =
              'Invoice number already exists. Please use a different number.';
        }
      } else {
        _invoiceExists = null;
        _invoiceCheckMessage =
            response['Message'] ?? 'Failed to check invoice number';
      }

      notifyListeners();
      return _invoiceExists == true;
    } catch (e) {
      _isCheckingInvoice = false;
      _invoiceExists = null;
      _invoiceCheckMessage = 'Error checking invoice number: $e';
      notifyListeners();

      return false;
    }
  }

  // Clear invoice check state
  void clearInvoiceCheck() {
    _invoiceExists = null;
    _invoiceCheckMessage = null;
    _isCheckingInvoice = false;
    notifyListeners();
  }

  Future<void> deleteSales(int? id, String? descriptionText) async {
    if (!await checkToken()) {
      return;
    }

    // Show loading state
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await restApi.deleteSales(
        token: getAuthHeader(),
        id: id,
        deleteDescription: descriptionText,
      );

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          await getSalesData();
          showSuccessSnack('Sales data deleted successfully');
        } else {
          String errorMsg = 'Failed to delete sales data';

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
              // Handle other validation errors if needed
              final firstError = data.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                errorMsg = firstError.first.toString();
              }
            }
          } else {
            // Fallback to general message
            errorMsg =
                response['Message'] as String? ?? 'Failed to delete sales data';
          }

          errorMessage = errorMsg;

          showErrorSnack(errorMessage.toString());
        }
      } else {
        await getSalesData();
        showErrorSnack(errorMessage.toString());
      }
    } catch (e) {
      handleApiError(e);
      showErrorSnack('Failed to delete sales: ${e.toString()}');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getSalesPdf(String salesId) async {
    if (!await checkToken()) return;

    try {
      final salesPdf = await restApi.getSalesPDF(
        token: getAuthHeader(),
        id: salesId,
      );

      if (salesPdf['IsSuccess'] == true) {
        salesPdfUrl = salesPdf['Data']?['url'];
        notifyListeners();
      } else {
        errorMessage = salesPdf['Message'] ?? 'Failed to fetch data';
      }
    } catch (e) {
      handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
