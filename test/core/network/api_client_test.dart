import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/core/network/api_exception.dart';

ApiClient clientWith(MockClientHandler handler, {Duration? timeout}) => ApiClient(
      client: MockClient(handler),
      baseUrl: 'http://api.test/',
      timeout: timeout ?? const Duration(seconds: 20),
    );

http.Response jsonResponse(Object body, int status) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  group('requests', () {
    test('postFile sends multipart with the token and decodes the reply', () async {
      late http.Request seen;
      final api = clientWith((req) async {
        seen = req;
        return jsonResponse({'id': 7}, 201);
      })
        ..tokenProvider = (() => 'abc');

      final body = await api.postFile('products/5/images/upload', field: 'image', bytes: [1, 2, 3], filename: 'a.png');

      expect(body, {'id': 7});
      expect(seen.url.toString(), 'http://api.test/products/5/images/upload');
      expect(seen.headers['Authorization'], 'Bearer abc');
      expect(seen.headers['content-type'], startsWith('multipart/form-data'));
      expect(seen.body, contains('name="image"; filename="a.png"'));
    });

    test('resolves relative paths and adds the bearer token', () async {
      late http.BaseRequest seen;
      final api = clientWith((req) async {
        seen = req;
        return jsonResponse({'ok': true}, 200);
      })
        ..tokenProvider = (() => 'abc');

      final body = await api.get('/orders', query: {'page': '1'});

      expect(body, {'ok': true});
      expect(seen.url.toString(), 'http://api.test/orders?page=1');
      expect(seen.headers['Authorization'], 'Bearer abc');
    });

    test('sends JSON bodies and decodes Arabic text', () async {
      late http.Request seen;
      final api = clientWith((req) async {
        seen = req;
        return jsonResponse({'name': 'اسوره'}, 201);
      });

      final body = await api.post('customers', body: {'governorate': 'القاهرة'});

      expect(jsonDecode(seen.body), {'governorate': 'القاهرة'});
      expect(body['name'], 'اسوره');
    });

    test('empty 204 response returns null', () async {
      final api = clientWith((_) async => http.Response('', 204));
      expect(await api.delete('orders/1'), isNull);
    });
  });

  group('errors', () {
    test('uses the backend ApiError body', () async {
      final api = clientWith((_) async => jsonResponse({
            'status': 409,
            'code': 'INSUFFICIENT_STOCK',
            'message': "Not enough stock for 'Bracelet'.",
            'details': [
              {'field': 'items[0].quantity', 'message': 'only 2 left'}
            ],
            'requestId': 'r-1',
          }, 409));

      final error = await api.post('orders').then<ApiException?>((_) => null,
          onError: (e) => e as ApiException);

      expect(error!.code, 'INSUFFICIENT_STOCK');
      expect(error.statusCode, 409);
      expect(error.message, "Not enough stock for 'Bracelet'.");
      expect(error.messageFor('items[0].quantity'), 'only 2 left');
      expect(error.requestId, 'r-1');
    });

    test('falls back to a friendly message for non-ApiError bodies', () async {
      final api = clientWith((_) async => http.Response('<html>Bad Gateway</html>', 502));

      expect(
        () => api.get('orders'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'INTERNAL_ERROR')
            .having((e) => e.message, 'message', contains('Something went wrong'))),
      );
    });

    test('network failures become NETWORK_ERROR', () async {
      final api = clientWith((_) async => throw http.ClientException('connection refused'));
      expect(() => api.get('orders'),
          throwsA(isA<ApiException>().having((e) => e.code, 'code', ApiException.codeNetwork)));
    });

    test('slow responses become TIMEOUT', () async {
      final api = clientWith(
        (_) => Completer<http.Response>().future,
        timeout: const Duration(milliseconds: 10),
      );
      expect(() => api.get('orders'),
          throwsA(isA<ApiException>().having((e) => e.code, 'code', ApiException.codeTimeout)));
    });

    test('invalid JSON on success becomes BAD_RESPONSE', () async {
      final api = clientWith((_) async => http.Response('not json', 200));
      expect(() => api.get('orders'),
          throwsA(isA<ApiException>().having((e) => e.code, 'code', ApiException.codeBadResponse)));
    });
  });

  group('session expiry', () {
    test('401 on an authenticated request triggers onUnauthorized', () async {
      var calls = 0;
      final api = clientWith((_) async => jsonResponse(
          {'status': 401, 'code': 'UNAUTHENTICATED', 'message': 'Please log in to continue.'}, 401))
        ..tokenProvider = (() => 'expired')
        ..onUnauthorized = (() => calls++);

      await expectLater(api.get('orders'), throwsA(isA<ApiException>()));
      expect(calls, 1);
    });

    test('wrong password on login does not end the session', () async {
      var calls = 0;
      final api = clientWith((_) async => jsonResponse(
          {'status': 401, 'code': 'INVALID_CREDENTIALS', 'message': 'Incorrect username or password.'}, 401))
        ..tokenProvider = (() => null)
        ..onUnauthorized = (() => calls++);

      await expectLater(
        api.post('auth/login', body: {'username': 'a', 'password': 'b'}),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'INVALID_CREDENTIALS')),
      );
      expect(calls, 0);
    });
  });
}
