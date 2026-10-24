import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/services/user_service.dart';

/// Owns the login session: restoring a saved token at startup, logging in and
/// out, and ending the session when the backend reports it has expired.
///
/// [sessionEpoch] changes on every login and logout; the app keys all
/// session-scoped providers on it so no data survives from a previous session.
class UserViewModel extends ChangeNotifier {
  UserViewModel(this._userService);

  static const _tokenKey = 'auth_token';
  static const sessionExpiredMessage = 'Your session has expired. Please log in again.';

  final UserService _userService;

  String? _token;
  bool _isRestoring = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _logoutReason;
  int _sessionEpoch = 0;

  bool get isRestoring => _isRestoring;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  int get sessionEpoch => _sessionEpoch;

  /// Why the last login attempt failed, ready to show to the user.
  String? get errorMessage => _errorMessage;

  /// Set when the session ended without the user asking (e.g. token expired).
  String? get logoutReason => _logoutReason;

  /// Current JWT, or an empty string when logged out.
  String get token => _token ?? '';

  /// Loads a saved token, discarding it if it has already expired.
  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_tokenKey);
      if (saved != null && !isTokenExpired(saved)) {
        _token = saved;
      } else if (saved != null) {
        await prefs.remove(_tokenKey);
      }
    } catch (e) {
      debugPrint('Could not restore session: $e');
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  /// Returns true on success; on failure [errorMessage] explains why.
  Future<bool> login(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) {
      _errorMessage = 'Please enter your username and password.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _userService.login(username.trim(), password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      _token = token;
      _logoutReason = null;
      _sessionEpoch++;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      debugPrint('Unexpected login error: $e');
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout({String? reason}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _token = null;
    _logoutReason = reason;
    _errorMessage = null;
    _sessionEpoch++;
    notifyListeners();
  }

  /// Called by the ApiClient when an authenticated request returns 401.
  void handleSessionExpired() {
    if (!isAuthenticated) return;
    logout(reason: sessionExpiredMessage);
  }

  /// Reads the `exp` claim without verifying the signature (the server does that).
  @visibleForTesting
  static bool isTokenExpired(String token, {DateTime? now}) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final exp = payload is Map ? payload['exp'] : null;
      if (exp is! num) return false;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
      return !(now ?? DateTime.now()).isBefore(expiresAt);
    } catch (_) {
      return true;
    }
  }
}
