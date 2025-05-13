import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sample/src/util/app_navigation.dart';
import 'package:sample/src/util/app_routes.dart';

import '../config/messages.dart';
import '../data/rest_client.dart';
import '../repo/auth_repo.dart';
import '../util/circle_progress.dart';
import '../util/snack.dart';

class AuthController with ChangeNotifier {
  final token = AuthRepo.token;
  Future<void> login(String email, String password) async {
    showCircle();

    try {
      final loginResponse = await restApi.login(
        email: email,
        password: password,
      );

      if (loginResponse.IsSuccess == true) {
        final data = loginResponse.Data;
        AuthRepo.token = loginResponse.Token;
        AuthRepo.loginId = loginResponse.Data?.id;

        String? roleName;
        if (data?.roles != null) {
          roleName = data?.roles?.Name;
        }
        AuthRepo.role = roleName;

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
      return true;
    } catch (e) {
      if (e is DioException) {
        print("Dio Exception $e");
      }
      return false;
    }
  }
}
