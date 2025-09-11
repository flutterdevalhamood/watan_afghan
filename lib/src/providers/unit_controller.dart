import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import '../data/rest_client.dart';
import '../repo/auth_repo.dart';

class UnitController with ChangeNotifier {
  List<Map<String, dynamic>>? customerData;
  List<Map<String, dynamic>>? unitData;
  bool isLoading = false;
  final token = AuthRepo.token;
  bool hasMore = false;
  int currentPage = 1;
  final int totalPages = 10;

  Future<void> refresh() async {
    currentPage = 1;
    hasMore = true;
    unitData?.clear();
    await getUnitData();
  }

  Future<void> getUnitData({bool loadMore = false}) async {
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
      final unit = await restApi.getUnitData(
        currentPage,
        totalPages,
        'Bearer $token',
      );
      if (unit['IsSuccess'] == true) {
        final data = unit['Data'] as List<dynamic>;
        if (data != null) {
          final newProduct =
              data.map((v) => v as Map<String, dynamic>).toList();
          print('productData $unitData');
          if (loadMore) {
            unitData ??= [];
            unitData!.addAll(newProduct);
          } else {
            unitData = newProduct;
          }
          hasMore = data.length == totalPages;
        } else {
          hasMore = false;
        }
      } else {
        print('Api call failed ${unit['Message']}');
      }
    } catch (e) {
      if (e is DioException) {
        print('Dio Exception $e');
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void loadMore() {
    if (hasMore && !isLoading) {}
    currentPage++;
    getUnitData(loadMore: true);
  }

  Future<bool> registerUnit(String? name) async {
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      await restApi.registerUnit(token: 'Bearer $token', name: name);
      await getUnitData();
      return true;
    } catch (e) {
      if (e is DioException) {
        print("Dio Exception $e");
      }
      return false;
    }
  }

  Future<bool> updateUnit(int? id, String? name) async {
    if (token == null) {
      throw Exception("No Token Found");
    }
    try {
      await restApi.updateUnit(token: 'Bearer $token', id: id, name: name);
      await getUnitData();
      return true;
    } catch (e) {
      if (e is DioException) {
        print('Dio Exception $e');
      }
      return false;
    }
  }

  Future<void> deleteUnit(int? id, String? description) async {
    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      await restApi.deleteUnit(
        token: 'Bearer $token',
        id: id,
        deleteDescription: description,
      );
      await getUnitData();
    } catch (e) {
      if (e is DioException) {
        print("Dio Exception $e");
      }
    }
  }
}
