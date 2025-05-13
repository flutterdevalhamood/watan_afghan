import 'dart:convert';

import 'package:sample/src/util/app_routes.dart';

import '../BaseScreen.dart';
import '../util/shared_pref.dart';

class AuthRepo {
  static const _prefUserKey = "userBase";
  static const _prefTokenKey = "token";
  static const _prefRoleKey = "role";
  static const _prefLoginIdKey = "Id";

  static set token(String? token) {
    if (token == null) {
      prefs?.remove(_prefTokenKey);
    } else {
      prefs?.setString(_prefTokenKey, token);
    }
  }

  static String? get token {
    return prefs?.getString(_prefTokenKey); // Retrieve token
  }

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

  static logOut() {
    prefs?.clear();
    user = null;
    navigatorKey?.currentState?.pushNamedAndRemoveUntil(
      Screenroutes.login,
      (route) => false,
    );
  }
}
