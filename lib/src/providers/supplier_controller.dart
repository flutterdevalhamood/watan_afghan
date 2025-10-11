import 'package:dio/dio.dart';
import 'package:sample/src/providers/base_controller.dart';
import 'package:sample/src/screens/supplier/supplier_model.dart';
import 'package:sample/src/util/snack.dart';

import '../data/rest_client.dart';

class SupplierController extends BaseController {
  bool isLoading = false;
  int currentPage = 1;
  final int totalPages = 10;
  bool hasMore = true;
  String? errorMessage;
  int? id;

  List<Map<String, dynamic>>? supplierDetail;
  List<Map<String, dynamic>>? companyType;
  List<Map<String, dynamic>>? paymentType;
  List<Map<String, dynamic>>? countries;
  List<Supplier> _allSuppliers = [];
  List<Supplier> _filteredSuppliers = [];
  String _searchQuery = '';

  List<Supplier> get suppliers => _filteredSuppliers;
  String get searchQuery => _searchQuery;
  bool get isEmpty => _filteredSuppliers.isEmpty && !isLoading;
  bool get hasData => _allSuppliers.isNotEmpty;

  List<Map<String, dynamic>>? _supplierDetail;
  bool _isDetailLoading = false;
  String? _detailErrorMessage;

  List<Map<String, dynamic>>? get supplierDetailData => _supplierDetail;
  bool get isDetailLoading => _isDetailLoading;
  String? get detailErrorMessage => _detailErrorMessage;

  // Search functionality
  void searchSuppliers(String query) {
    _searchQuery = query.toLowerCase();

    if (_searchQuery.isEmpty) {
      _filteredSuppliers = List.from(_allSuppliers);
    } else {
      _filteredSuppliers =
          _allSuppliers.where((customer) {
            return customer.name.toLowerCase().contains(_searchQuery) ||
                customer.mobile.toLowerCase().contains(_searchQuery);
          }).toList();
    }

    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredSuppliers = List.from(_allSuppliers);
    notifyListeners();
  }

  Future<void> getSupplierData({bool loadMore = false}) async {
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
          final supplier = await restApi.getSupplier(
            currentPage,
            totalPages,
            getAuthHeader(),
          );

          if (supplier is Map<String, dynamic>) {
            if (supplier['IsSuccess'] == true) {
              final data = supplier['Data'] as List<dynamic>?;
              if (data != null) {
                final newSupplierData =
                    data.map((json) => Supplier.fromJson(json)).toList();
                if (loadMore) {
                  _allSuppliers.addAll(newSupplierData);
                } else {
                  _allSuppliers =
                      newSupplierData; // Replace list on initial load
                }
                searchSuppliers(_searchQuery);
                hasMore = data.length == totalPages;

                // Success - break out of retry loop
                break;
              } else {
                errorMessage = supplier['Message'] as String?;
              }
            } else {
              errorMessage =
                  supplier['Message'] as String? ?? 'API call failed';
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
      getSupplierData(loadMore: true);
    }
  }

  void refresh() {
    currentPage = 1;
    hasMore = true;
    errorMessage = null; // Clear errors on refresh
    _allSuppliers.clear();
    _filteredSuppliers.clear();
    _searchQuery = '';
    getSupplierData();
  }

  Future<void> getSupplierDetail(int supplierId) async {
    if (!await checkToken()) return;

    _isDetailLoading = true;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      final supplierDetailData = await restApi.getSupplierDetail(
        id: supplierId,
        token: getAuthHeader(),
      );

      if (supplierDetailData['IsSuccess'] == true) {
        final data = supplierDetailData['Data'] as Map<String, dynamic>;
        supplierDetail = [data];
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

  Future<void> getSupplierBaseData() async {
    if (!await checkToken()) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final supplierBaseData = await restApi.getSupplierBaseList(
        token: getAuthHeader(),
      );

      if (supplierBaseData['IsSuccess'] == true) {
        companyType = List<Map<String, dynamic>>.from(
          supplierBaseData['Data']['company_type'],
        );
        paymentType = List<Map<String, dynamic>>.from(
          supplierBaseData['Data']['payment_type'],
        );
        countries = List<Map<String, dynamic>>.from(
          supplierBaseData['Data']['countries'],
        );
      } else {
        errorMessage =
            supplierBaseData['Message'] ?? 'Failed to fetch base data';
      }
    } catch (e) {
      handleApiError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<SupplierRegistrationResult> postSupplierRegistration({
    String? name,
    String? trnNumber,
    String? representative,
    int? companyTypeId,
    String? registrationDate,
    int? paymentTypeId,
    String? toPaymentType,
    int? openingBalance,
    String? openingBalanceAsOfDate,
    String? mobile,
    String? phone,
    String? email,
    String? address,
    int? regionId,
    String? postCode,
  }) async {
    if (!await checkToken()) {
      return SupplierRegistrationResult(
        success: false,
        message: 'Authentication failed',
      );
    }

    try {
      final response = await restApi.postSupplierRegistration(
        token: getAuthHeader(),
        name: name,
        trnNumber: trnNumber,
        representative: representative,
        companyTypeId: companyTypeId,
        registrationDate: registrationDate,
        paymentTypeId: paymentTypeId,
        toPaymentType: toPaymentType,
        openingBalance: openingBalance,
        openingBalanceAsOfDate: openingBalanceAsOfDate,
        mobile: mobile,
        phone: phone,
        email: email,
        address: address,
        regionId: regionId,
        postCode: postCode,
      );

      // Check response
      if (response is Map<String, dynamic> && response['IsSuccess'] == true) {
        await getSupplierData();

        return SupplierRegistrationResult(success: true);
      } else if (response is Map<String, dynamic>) {
        final errorMessage = response['Message'] as String? ?? 'Unknown error';

        // Check for duplicate name error
        bool isDuplicate =
            errorMessage.toLowerCase().contains('duplicate') ||
            errorMessage.toLowerCase().contains('already exists') ||
            errorMessage.toLowerCase().contains('name already') ||
            errorMessage.toLowerCase().contains('SUPPLIER AVAILABLE') ||
            errorMessage.toLowerCase().contains(' SAME TRN NUMBER') ||
            response['StatusCode'] == 401;

        return SupplierRegistrationResult(
          success: false,
          message: errorMessage,
          isDuplicateName: isDuplicate,
        );
      } else {
        return SupplierRegistrationResult(
          success: false,
          message: 'Unexpected response format',
        );
      }
    } catch (e) {
      handleApiError(e);

      return SupplierRegistrationResult(
        success: false,
        message: errorMessage ?? 'An error occurred',
      );
    }
  }

  Future<void> deleteSupplier(int? id, String? descriptionText) async {
    if (!await checkToken()) {
      return;
    }

    // Show loading state
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await restApi.deleteSupplier(
        token: getAuthHeader(),
        id: id,
        description: descriptionText,
      );

      if (response is Map<String, dynamic>) {
        if (response['IsSuccess'] == true) {
          await getSupplierData();
          showSuccessSnack('Supplier deleted successfully');
        } else {
          // Handle different types of errors
          String errorMsg = 'Failed to delete supplier';

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
                response['Message'] as String? ?? 'Failed to delete supplier';
          }

          errorMessage = errorMsg;

          showErrorSnack(errorMessage.toString());
        }
      } else {
        await getSupplierData();
        showErrorSnack(errorMessage.toString());
      }
    } catch (e) {
      handleApiError(e);
      showErrorSnack(errorMessage.toString());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

class SupplierRegistrationResult {
  final bool success;
  final String? message;
  final bool isDuplicateName;

  SupplierRegistrationResult({
    required this.success,
    this.message,
    this.isDuplicateName = false,
  });
}
