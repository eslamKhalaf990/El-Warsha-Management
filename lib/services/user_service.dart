import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/core/network/api_exception.dart';

class UserService {
  UserService(this._api);

  final ApiClient _api;

  /// Logs an ERP user in and returns the JWT.
  ///
  /// Throws [ApiException] (e.g. `INVALID_CREDENTIALS`, `NETWORK_ERROR`).
  Future<String> login(String username, String password) async {
    final body = await _api.post('auth/login', body: {
      'username': username,
      'password': password,
    });
    final token = body is Map ? body['token'] : null;
    if (token is! String || token.isEmpty) {
      throw ApiException.badResponse(200);
    }
    return token;
  }
}
