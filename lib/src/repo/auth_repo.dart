import 'dart:convert';

import 'package:sample/src/util/app_routes.dart';

import '../BaseScreen.dart';
import '../util/shared_pref.dart';

class AuthRepo {
  static const _prefUserKey = "userBase";
  static const _prefTokenKey = "token";
  static const _prefRoleKey = "role";
  static const _prefLoginIdKey = "Id";
  static const _prefContactKey = "contact";
  static const _prefTokenExpiryKey = "tokenExpiry";
  static const _prefImageUrlKey = "imageUrl";

  // Token setters and getters
  static set token(String? token) {
    if (token == null) {
      prefs?.remove(_prefTokenKey);
    } else {
      prefs?.setString(_prefTokenKey, token);
      // Set token expiry to 24 hours from now (adjust as needed based on your server config)
      setTokenExpiry(
        DateTime.now().add(Duration(hours: 24)).millisecondsSinceEpoch,
      );
    }
  }

  static String? get token {
    final storedToken = prefs?.getString(_prefTokenKey);
    // Check if token is expired
    if (storedToken != null && isTokenExpired()) {}
    return storedToken;
  }

  // Token expiry helpers
  static void setTokenExpiry(int expiryTimestamp) {
    prefs?.setInt(_prefTokenExpiryKey, expiryTimestamp);
  }

  static int? getTokenExpiry() {
    return prefs?.getInt(_prefTokenExpiryKey);
  }

  static bool isTokenExpired() {
    final expiry = getTokenExpiry();
    if (expiry == null) return true;
    return DateTime.now().millisecondsSinceEpoch > expiry;
  }

  // Token validation and refresh
  static bool hasValidToken() {
    final storedToken = prefs?.getString(_prefTokenKey);
    return storedToken != null && storedToken.isNotEmpty && !isTokenExpired();
  }

  static Future<bool> refreshToken() async {
    // This is a placeholder. In a real app, you would call your refresh token API here
    // For now, we just check if the token exists
    final currentToken = token;

    return currentToken != null && currentToken.isNotEmpty;
  }

  static set imageUrl(String? url) {
    if (url == null) {
      prefs?.remove(_prefImageUrlKey);
    } else {
      prefs?.setString(_prefImageUrlKey, url);
    }
  }

  static String? get imageUrl {
    return prefs?.getString(_prefImageUrlKey);
  }

  // Role setters and getters
  static set role(String? role) {
    if (role == null) {
      prefs?.remove(_prefRoleKey);
    } else {
      prefs?.setString(_prefRoleKey, role);
    }
  }

  static String? get role {
    return prefs?.getString(_prefRoleKey);
  }

  // Contact setters and getters
  static set contact(String? contact) {
    if (contact == null) {
      prefs?.remove(_prefContactKey);
    } else {
      prefs?.setString(_prefContactKey, contact);
    }
  }

  static String? get contact {
    return prefs?.getString(_prefContactKey);
  }

  // User setters and getters
  static set user(String? user) {
    if (user == null) {
      prefs?.remove(_prefUserKey);
    } else {
      final userJson = jsonEncode(user);
      prefs?.setString(_prefUserKey, userJson);
    }
  }

  static String? get user {
    var value = prefs?.getString(_prefUserKey);
    if (value == null) return null;

    final userJson = jsonDecode(value);
    return userJson;
  }

  // Login ID setters and getters
  static set loginId(int? id) {
    if (id == null) {
      prefs?.remove(_prefLoginIdKey);
    } else {
      final userJson = jsonEncode(id);
      prefs?.setString(_prefLoginIdKey, userJson);
    }
  }

  static int? get loginId {
    var value = prefs?.getString(_prefLoginIdKey);
    if (value == null) return null;
    final customerIdJson = jsonDecode(value);
    return customerIdJson;
  }

  // Authentication state
  static bool get isAuthenticated {
    final hasToken = token != null && token!.isNotEmpty;
    final isLoggedIn = loginId != null;
    return hasToken && isLoggedIn && !isTokenExpired();
  }

  // Logout
  static void logOut() {
    prefs?.clear();
    user = null;
    navigatorKey?.currentState?.pushNamedAndRemoveUntil(
      Screenroutes.login,
      (route) => false,
    );
  }

  // Handle auth errors
  static void handleAuthError() {
    logOut();
  }

  // Initialize auth when app starts
  static Future<void> initAuth() async {
    if (isTokenExpired() && token != null) {
      logOut();
    }
  }
}
