import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sample/src/models/user_model.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';

import '../config/messages.dart';
import '../data/rest_client.dart';
import '../repo/auth_repo.dart';
import '../util/circle_progress.dart';
import '../util/snack.dart';

class AuthController with ChangeNotifier {
  final token = AuthRepo.token;
  String? contactNumber;
  UserData? userData;

  Future<void> login(String email, String password) async {
    showCircle();

    try {
      final loginResponse = await restApi.login(
        email: email,
        password: password,
      );

      if (loginResponse.IsSuccess == true) {
        userData = loginResponse.Data;
        AuthRepo.token = loginResponse.Token;
        AuthRepo.loginId = loginResponse.Data?.id;
        AuthRepo.user = loginResponse.Data?.name;
        AuthRepo.contact = loginResponse.Data?.contactNumber;
        if (loginResponse.Data?.imageUrl != null &&
            loginResponse.Data!.imageUrl!.isNotEmpty) {
          AuthRepo.imageUrl =
              "${loginResponse.Data!.imageUrl}?t=${DateTime.now().millisecondsSinceEpoch}";
        } else {
          AuthRepo.imageUrl = null;
        }
        String? roleName;
        if (userData?.roles != null) {
          roleName = userData?.roles?.Name;
        }
        AuthRepo.role = roleName;
        notifyListeners();
        NavigationService().pushNavigation(
          Screenroutes.dashboard,
          arguments: {'role': roleName},
        );
      } else {
        showErrorSnack(Messages.authenticationFailure);
      }
    } catch (e) {
      if (e is TypeError) {
        if (e is DioException) {
          log("TypeError", stackTrace: e.stackTrace);
        }
        log("TypeError", stackTrace: e.stackTrace);
      }
      showErrorSnack(Messages.authenticationFailure);
    }

    removeCircle();
  }

  Future<bool> logout(int? loginId) async {
    showCircle();

    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      await restApi.logout(token: 'Bearer $token', id: AuthRepo.loginId);
      AuthRepo.logOut();
      removeCircle();
      return true;
    } catch (e) {
      if (e is DioException) {
        print("Dio Exception $e");
      }
      return false;
    }
  }

  Future<bool> changePassword(
    String? currentPassword,
    String? newPassword,
  ) async {
    showCircle();

    try {
      if (token == null) {
        throw Exception("No Token Found");
      }
      final response = await restApi.changePassword(
        token: 'Bearer $token',
        currentPassword: currentPassword,
        password: newPassword,
      );

      removeCircle();

      // Check the API response structure
      if (response != null && response is Map<String, dynamic>) {
        return response['IsSuccess'] == true;
      }
      return false;
    } catch (e) {
      removeCircle();
      if (e is DioException) {
        print("Dio Exception $e");
      }
      return false;
    }
  }

  // Future<bool> changePassword(
  //   String? currentPassword,
  //   String? newPassword,
  // ) async {
  //   showCircle();
  //
  //   try {
  //     if (token == null) {
  //       throw Exception("No Token Found");
  //     }
  //     await restApi.changePassword(
  //       token: 'Bearer $token',
  //       currentPassword: currentPassword,
  //       password: newPassword,
  //     );
  //     return true;
  //   } catch (e) {
  //     if (e is DioException) {
  //       print("Dio Exception $e");
  //     }
  //     return false;
  //   }
  // }

  Future<bool> updateUserProfile({
    required String token,
    required String name,
    required String contactNumber,
    File? imageFile,
  }) async {
    try {
      MultipartFile? multipartFile;

      if (imageFile != null) {
        multipartFile = await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        );
      }

      // Build form-data map
      final formData = {
        "name": name,
        "contactNumber": contactNumber,
        if (multipartFile != null)
          "imageUrl": multipartFile, // backend expects "imageUrl"
      };

      final response = await restApi.userUpdate("Bearer $token", formData);

      // Update local cache
      AuthRepo.user = name;
      AuthRepo.contact = contactNumber;

      // Handle image URL from API response
      if (response != null && response is Map<String, dynamic>) {
        final data = response["Data"];
        if (data != null &&
            data["imageUrl"] != null &&
            data["imageUrl"].toString().isNotEmpty) {
          final rawUrl = data["imageUrl"].toString();
          AuthRepo.imageUrl =
              "$rawUrl?t=${DateTime.now().millisecondsSinceEpoch}";
        } else if (imageFile == null) {
          AuthRepo.imageUrl = null;
        }
      }

      notifyListeners();
      removeCircle();
      return true;
    } catch (e) {
      removeCircle();
      if (e is DioException) {
        print("Dio Exception $e");
      }
      return false;
    }
  }
}
