import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:warsha_app/services/base_url.dart';

import 'api_exception.dart';

/// The single HTTP entry point for the app.
///
/// - Adds the bearer token from [tokenProvider] to every request.
/// - Decodes JSON responses (204 / empty bodies return `null`).
/// - Turns every failure into an [ApiException] with a user-friendly message.
/// - Calls [onUnauthorized] when an authenticated request gets a 401, so the
///   session can be ended in one place.
class ApiClient {
  ApiClient({
    http.Client? client,
    String? baseUrl,
    this.timeout = const Duration(seconds: 20),
  })  : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? Baseurl.baseURL;

  final http.Client _client;
  final String baseUrl;
  final Duration timeout;

  /// Returns the current token, or null when logged out.
  String? Function()? tokenProvider;

  /// Invoked once per 401 on a request that carried a token.
  VoidCallback? onUnauthorized;

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body, Map<String, String>? query}) =>
      _send('POST', path, body: body, query: query);

  Future<dynamic> put(String path, {Object? body, Map<String, String>? query}) =>
      _send('PUT', path, body: body, query: query);

  Future<dynamic> patch(String path, {Object? body, Map<String, String>? query}) =>
      _send('PATCH', path, body: body, query: query);

  Future<dynamic> delete(String path, {Map<String, String>? query}) =>
      _send('DELETE', path, query: query);

  /// For binary downloads such as invoice PDFs.
  Future<Uint8List> getBytes(String path, {Map<String, String>? query}) async {
    final response = await _raw('GET', path, query: query, accept: '*/*');
    return response.bodyBytes;
  }

  Future<dynamic> _send(String method, String path,
      {Object? body, Map<String, String>? query}) async {
    final response = await _raw(method, path, body: body, query: query);
    if (response.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw ApiException.badResponse(response.statusCode);
    }
  }

  Future<http.Response> _raw(String method, String path,
      {Object? body, Map<String, String>? query, String accept = 'application/json'}) async {
    final token = tokenProvider?.call();
    final hasToken = token != null && token.isNotEmpty;

    final request = http.Request(method, resolve(path, query));
    request.headers['Accept'] = accept;
    if (hasToken) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(timeout);
      response = await http.Response.fromStream(streamed).timeout(timeout);
    } on TimeoutException {
      throw ApiException.timeout();
    } on http.ClientException {
      // http wraps socket / XHR failures in ClientException on every platform.
      throw ApiException.network();
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    final error = ApiException.fromResponse(response);
    debugPrint('API $method ${request.url.path} -> ${response.statusCode} '
        '${error.code} [${error.requestId ?? '-'}]');
    if (error.isUnauthenticated && hasToken) {
      onUnauthorized?.call();
    }
    throw error;
  }

  /// Accepts either a path relative to [baseUrl] (`orders/12`) or a full URL.
  @visibleForTesting
  Uri resolve(String path, Map<String, String>? query) {
    final isAbsolute = path.startsWith('http://') || path.startsWith('https://');
    final base = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final relative = path.startsWith('/') ? path.substring(1) : path;
    final uri = Uri.parse(isAbsolute ? path : '$base$relative');
    return (query == null || query.isEmpty)
        ? uri
        : uri.replace(queryParameters: {...uri.queryParameters, ...query});
  }

  void close() => _client.close();
}
