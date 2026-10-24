import 'dart:convert';

import 'package:http/http.dart' as http;

/// One invalid input field returned by the backend, e.g. `items[0].quantity`.
class FieldViolation {
  final String field;
  final String message;

  const FieldViolation(this.field, this.message);

  factory FieldViolation.fromJson(Map<String, dynamic> json) => FieldViolation(
        json['field']?.toString() ?? '',
        json['message']?.toString() ?? '',
      );
}

/// Every failed API call surfaces as an [ApiException].
///
/// [message] is always safe to show to the user. [code] mirrors the backend's
/// `ApiError.code` (e.g. `INSUFFICIENT_STOCK`) so the UI can branch on it, plus
/// the client-side codes [codeNetwork], [codeTimeout] and [codeBadResponse].
class ApiException implements Exception {
  static const codeNetwork = 'NETWORK_ERROR';
  static const codeTimeout = 'TIMEOUT';
  static const codeBadResponse = 'BAD_RESPONSE';

  final int? statusCode;
  final String code;
  final String message;
  final List<FieldViolation> details;
  final String? requestId;

  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.details = const [],
    this.requestId,
  });

  bool get isUnauthenticated => code == 'UNAUTHENTICATED';
  bool get isNotFound => statusCode == 404;
  bool get isValidation => code == 'VALIDATION_FAILED';

  /// Message for a single field, if the backend reported one.
  String? messageFor(String field) {
    for (final d in details) {
      if (d.field == field) return d.message;
    }
    return null;
  }

  factory ApiException.network() => const ApiException(
        code: codeNetwork,
        message: "Can't reach the server. Check your internet connection and try again.",
      );

  factory ApiException.timeout() => const ApiException(
        code: codeTimeout,
        message: 'The server is taking too long to respond. Please try again.',
      );

  factory ApiException.badResponse(int statusCode) => ApiException(
        code: codeBadResponse,
        statusCode: statusCode,
        message: 'The server sent a response the app could not read.',
      );

  /// Builds an exception from a non-2xx response. Prefers the backend's
  /// `ApiError` body and falls back to a friendly message per status code.
  factory ApiException.fromResponse(http.Response response) {
    final requestId = response.headers['x-request-id'];
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map<String, dynamic> && body['code'] is String) {
        final details = body['details'] is List
            ? (body['details'] as List)
                .whereType<Map<String, dynamic>>()
                .map(FieldViolation.fromJson)
                .toList()
            : const <FieldViolation>[];
        final message = body['message']?.toString();
        return ApiException(
          statusCode: response.statusCode,
          code: body['code'] as String,
          message: (message == null || message.isEmpty)
              ? _fallbackMessage(response.statusCode)
              : message,
          details: details,
          requestId: body['requestId']?.toString() ?? requestId,
        );
      }
    } catch (_) {
      // Not an ApiError body (old endpoint, proxy page, plain text...).
    }
    return ApiException(
      statusCode: response.statusCode,
      code: _fallbackCode(response.statusCode),
      message: _fallbackMessage(response.statusCode),
      requestId: requestId,
    );
  }

  static String _fallbackCode(int status) => switch (status) {
        400 => 'MALFORMED_REQUEST',
        401 => 'UNAUTHENTICATED',
        403 => 'FORBIDDEN',
        404 => 'NOT_FOUND',
        409 => 'CONFLICT',
        413 => 'PAYLOAD_TOO_LARGE',
        422 => 'BUSINESS_RULE_VIOLATION',
        _ => 'INTERNAL_ERROR',
      };

  static String _fallbackMessage(int status) => switch (status) {
        400 => 'The request was not valid. Please check the data and try again.',
        401 => 'Your session has expired. Please log in again.',
        403 => "You don't have permission to do this.",
        404 => 'The requested item was not found.',
        409 => 'This change conflicts with existing data.',
        413 => 'The uploaded file is too large.',
        422 => 'This action is not allowed in the current state.',
        _ => 'Something went wrong on the server. Please try again.',
      };

  @override
  String toString() => message;
}
