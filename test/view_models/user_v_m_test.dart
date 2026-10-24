import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/services/user_service.dart';
import 'package:warsha_app/view_models/user_v_m.dart';

String jwtExpiringAt(DateTime exp) {
  String part(Map<String, dynamic> m) => base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part({'sub': 'admin', 'exp': exp.millisecondsSinceEpoch ~/ 1000})}.sig';
}

UserViewModel vmWith(MockClientHandler handler) =>
    UserViewModel(UserService(ApiClient(client: MockClient(handler), baseUrl: 'http://api.test/')));

void main() {
  final validToken = jwtExpiringAt(DateTime.now().add(const Duration(hours: 4)));
  final expiredToken = jwtExpiringAt(DateTime.now().subtract(const Duration(minutes: 1)));

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('restoreSession', () {
    test('keeps a saved token that is still valid', () async {
      SharedPreferences.setMockInitialValues({'auth_token': validToken});
      final vm = vmWith((_) async => http.Response('', 500));

      expect(vm.isRestoring, isTrue);
      await vm.restoreSession();

      expect(vm.isRestoring, isFalse);
      expect(vm.isAuthenticated, isTrue);
      expect(vm.token, validToken);
    });

    test('drops an expired token instead of using it', () async {
      SharedPreferences.setMockInitialValues({'auth_token': expiredToken});
      final vm = vmWith((_) async => http.Response('', 500));

      await vm.restoreSession();

      expect(vm.isAuthenticated, isFalse);
      expect((await SharedPreferences.getInstance()).getString('auth_token'), isNull);
    });
  });

  group('login', () {
    test('stores the token and starts a new session', () async {
      final vm = vmWith((_) async => http.Response(jsonEncode({'token': validToken}), 200));
      final before = vm.sessionEpoch;

      expect(await vm.login('admin', 'pw'), isTrue);

      expect(vm.isAuthenticated, isTrue);
      expect(vm.sessionEpoch, before + 1);
      expect((await SharedPreferences.getInstance()).getString('auth_token'), validToken);
    });

    test('shows the server message on wrong password', () async {
      final vm = vmWith((_) async => http.Response(
          jsonEncode({'status': 401, 'code': 'INVALID_CREDENTIALS', 'message': 'Incorrect username or password.'}),
          401));

      expect(await vm.login('admin', 'wrong'), isFalse);

      expect(vm.isAuthenticated, isFalse);
      expect(vm.errorMessage, 'Incorrect username or password.');
    });

    test('rejects empty fields without calling the server', () async {
      var called = false;
      final vm = vmWith((_) async {
        called = true;
        return http.Response('', 200);
      });

      expect(await vm.login('  ', ''), isFalse);
      expect(called, isFalse);
      expect(vm.errorMessage, isNotNull);
    });
  });

  group('session end', () {
    test('expiry logs out with a reason and bumps the session', () async {
      SharedPreferences.setMockInitialValues({'auth_token': validToken});
      final vm = vmWith((_) async => http.Response('', 500));
      await vm.restoreSession();
      final before = vm.sessionEpoch;

      vm.handleSessionExpired();
      await Future<void>.delayed(Duration.zero);

      expect(vm.isAuthenticated, isFalse);
      expect(vm.logoutReason, UserViewModel.sessionExpiredMessage);
      expect(vm.sessionEpoch, before + 1);
    });

    test('expiry while already logged out does nothing', () async {
      final vm = vmWith((_) async => http.Response('', 500));
      await vm.restoreSession();
      final before = vm.sessionEpoch;

      vm.handleSessionExpired();

      expect(vm.sessionEpoch, before);
      expect(vm.logoutReason, isNull);
    });
  });

  test('isTokenExpired treats malformed tokens as expired', () {
    expect(UserViewModel.isTokenExpired('not-a-jwt'), isTrue);
    expect(UserViewModel.isTokenExpired(validToken), isFalse);
    expect(UserViewModel.isTokenExpired(expiredToken), isTrue);
  });
}
