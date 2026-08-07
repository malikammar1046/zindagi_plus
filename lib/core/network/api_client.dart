import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zindagi_plus/core/config/environment.dart';

/// Shared key used to persist the auth token in [SharedPreferences].
const _kTokenKey = 'auth_token';

/// Singleton HTTP client backed by [Dio].
///
/// Configured with the base URL from [Environment.baseUrl].
/// Call [saveToken] after a successful login to persist the JWT.
class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Environment.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add logging interceptor in non-prod builds.
    if (!Environment.currentFlavor.name.contains('prod')) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint('[Dio] $obj'),
        ),
      );
    }
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;

  /// Exposes the underlying [Dio] instance for repository use.
  Dio get dio => _dio;

  // ---------------------------------------------------------------------------
  // Token management
  // ---------------------------------------------------------------------------

  /// Persists the JWT [token] to [SharedPreferences].
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTokenKey, token);
  }

  /// Retrieves the stored JWT token, or `null` if none exists.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTokenKey);
  }

  /// Removes the stored JWT token (call on logout).
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTokenKey);
  }
}
