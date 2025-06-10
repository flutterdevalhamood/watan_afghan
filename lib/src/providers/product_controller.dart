import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:sample/src/repo/auth_repo.dart';

import '../data/rest_client.dart';

class ProductController with ChangeNotifier {
  List<Map<String, dynamic>>? productData;
  List<Map<String, dynamic>>? filteredProducts;
  bool isLoading = false;
  final token = AuthRepo.token;
  bool hasMore = false;
  int currentPage = 1;
  final int totalPages = 10;
  String searchQuery = '';

  Future<void> getProductData({bool loadMore = false}) async {
    isLoading = true;
    notifyListeners();
    if (!loadMore) {
      currentPage = 1;
      hasMore = true;
    }
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      final product = await restApi.getProductData(
        currentPage,
        totalPages,
        'Bearer $token',
      );
      print('Full API Response: $product'); // Debug print
      if (product['IsSuccess'] == true) {
        final data = product['Data'] as List<dynamic>;
        final newProduct = data.map((v) => v as Map<String, dynamic>).toList();
        print('New products loaded: ${newProduct.length}'); // Debug print
        print('Product data: $newProduct'); // Debug print

        if (loadMore) {
          productData ??= [];
          productData!.addAll(newProduct);
        } else {
          productData = newProduct;
        }

        // Fix pagination logic - check if we have more data to load
        hasMore = newProduct.isNotEmpty && newProduct.length >= totalPages;

        print(
          'Total products after loading: ${productData?.length}',
        ); // Debug print
        _applySearch(); // Apply current search after loading data
      } else {
        print('Api call failed ${product['Message']}');
        // Initialize empty list if API fails
        if (!loadMore) {
          productData = [];
          _applySearch();
        }
      }
    } catch (e) {
      print('Exception occurred: $e'); // Debug print
      if (e is DioException) {
        print('Dio Exception details: ${e.response?.data}');
        print('Dio Exception message: ${e.message}');
      }
      // Initialize empty list on error if not loading more
      if (!loadMore) {
        productData = [];
        _applySearch();
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void loadMore() {
    if (hasMore && !isLoading) {
      currentPage++;
      getProductData(loadMore: true);
    }
  }

  void searchProducts(String query) {
    searchQuery = query.toLowerCase();
    _applySearch();
  }

  void _applySearch() {
    if (productData == null) {
      filteredProducts = [];
      notifyListeners();
      return;
    }

    if (searchQuery.isEmpty) {
      filteredProducts = List.from(productData!);
    } else {
      filteredProducts =
          productData!.where((product) {
            final name = (product['Name'] ?? '').toString().toLowerCase();
            final id = (product['id'] ?? '').toString().toLowerCase();
            return name.contains(searchQuery) || id.contains(searchQuery);
          }).toList();
    }
    print(
      'Filtered products count: ${filteredProducts?.length}',
    ); // Debug print
    notifyListeners();
  }

  void clearSearch() {
    searchQuery = '';
    _applySearch();
  }

  List<Map<String, dynamic>> get displayProducts => filteredProducts ?? [];

  Future<bool> registerProduct(String? name, List<MultipartFile>? files) async {
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      await restApi.registerProduct(
        token: 'Bearer $token',
        name: name,
        files: files,
      );
      await getProductData();
      return true;
    } catch (e) {
      if (e is DioException) {
        print("Dio Exception $e");
      }
      return false;
    }
  }

  Future<bool> updateProduct(
    int? id,
    String? name,
    List<MultipartFile>? files,
  ) async {
    if (token == null) {
      throw Exception("No Token Found");
    }
    try {
      await restApi.updateProduct(
        token: 'Bearer $token',
        id: id,
        name: name,
        files: files,
      );
      await getProductData();
      return true;
    } catch (e) {
      if (e is DioException) {
        print('Dio Exception $e');
      }
      return false;
    }
  }

  Future<void> deleteProduct(int? id, String? description) async {
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      await restApi.deleteProduct(
        token: 'Bearer $token',
        id: id,
        deleteDescription: description,
      );
      await getProductData();
    } catch (e) {
      if (e is DioException) {
        print("Dio Exception $e");
      }
      rethrow; // Re-throw to handle in UI
    }
  }
}
