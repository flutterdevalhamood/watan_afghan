import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../repo/auth_repo.dart';

abstract class BaseController with ChangeNotifier {
  Future<bool> checkToken() async {
    final token = AuthRepo.token;

    if (token == null || token.isEmpty) {
      debugPrint("No token available - auth failed");
      AuthRepo.handleAuthError();
      return false;
    }

    if (AuthRepo.isTokenExpired()) {
      debugPrint("Token expired - auth failed");
      // Handle expired token
      AuthRepo.handleAuthError();
      return false;
    }

    return true;
  }

  String getAuthHeader() {
    return 'Bearer ${AuthRepo.token}';
  }

  dynamic handleApiError(
    dynamic e, {
    Function(String)? onAuthError,
    Function(String)? onError,
  }) {
    if (e is DioException) {
      debugPrint("Dio Exception: ${e.message}");
      debugPrint("Dio Exception Type: ${e.type}");

      if (e.response?.statusCode == 302 ||
          e.response?.statusCode == 401 ||
          (e.response?.data is String &&
              (e.response?.data as String).contains('login'))) {
        debugPrint("Authentication failed - redirected to login page");
        final authErrorMsg = 'Authentication failed. Please log in again.';
        onAuthError?.call(authErrorMsg);
        AuthRepo.handleAuthError();
        return false;
      }

      if (e.response != null) {
        debugPrint('Response status: ${e.response?.statusCode}');
        debugPrint('Response headers: ${e.response?.headers}');
        debugPrint('Response data: ${e.response?.data}');
      }

      final errorMsg = getErrorMessage(e);
      onError?.call(errorMsg);
      return false;
    } else {
      debugPrint("Error: $e");
      final errorMsg = 'An unexpected error occurred. Please try again.';
      onError?.call(errorMsg);
      return false;
    }
  }

  String getErrorMessage(dynamic e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.receiveTimeout:
        return 'Server response timeout. Please try again.';
      case DioExceptionType.sendTimeout:
        return 'Request timeout. Please try again.';
      case DioExceptionType.connectionError:
        if (e.message?.contains('Failed host lookup') ?? false) {
          return 'Cannot connect to server. Please check your internet connection or try again later.';
        }
        return 'Connection error. Please check your internet connection.';
      case DioExceptionType.badResponse:
        if (e.response?.statusCode == 404) {
          return 'Service not found. Please contact support.';
        } else if (e.response?.statusCode == 500) {
          return 'Server error. Please try again later.';
        }
        return 'Server error (${e.response?.statusCode}). Please try again.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      default:
        return 'Network error. Please check your connection and try again.';
    }
  }

  bool shouldRetry(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError ||
        (e.message?.contains('Failed host lookup') ?? false) ||
        (e.message?.contains('SocketException') ?? false) ||
        (e.response?.statusCode == 502) ||
        (e.response?.statusCode == 503) ||
        (e.response?.statusCode == 504);
  }

  String extractValidationError(
    Map<String, dynamic>? data,
    String defaultMessage,
  ) {
    if (data == null) return defaultMessage;

    for (var key in data.keys) {
      final value = data[key];
      if (value is List && value.isNotEmpty) {
        return value.first.toString();
      } else if (value is String && value.isNotEmpty) {
        return value;
      }
    }

    return defaultMessage;
  }

  bool isApiResponseSuccess(Map<String, dynamic>? response) {
    return response != null && response['IsSuccess'] == true;
  }

  String getApiErrorMessage(
    Map<String, dynamic>? response,
    String defaultMessage,
  ) {
    if (response == null) return defaultMessage;
    return response['Message'] as String? ?? defaultMessage;
  }
}
