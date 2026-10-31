import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/core/state/async_view_model.dart';

class _VM extends ChangeNotifier with AsyncViewModel {
  Future<bool> doLoad(Future<void> Function() f) => load(f);
  Future<bool> doRun(Future<void> Function() f) => run(f);
}

void main() {
  late _VM vm;
  setUp(() => vm = _VM());

  test('load toggles isLoading and marks hasLoaded on success', () async {
    final seen = <bool>[];
    vm.addListener(() => seen.add(vm.isLoading));

    expect(await vm.doLoad(() async {}), isTrue);

    expect(seen, [true, false]);
    expect(vm.hasLoaded, isTrue);
    expect(vm.error, isNull);
  });

  test('a failed first load is a load failure with the API message', () async {
    const e = ApiException(code: ApiException.codeNetwork, message: "Can't reach the server.");

    expect(await vm.doLoad(() async => throw e), isFalse);

    expect(vm.loadFailed, isTrue);
    expect(vm.errorMessage, "Can't reach the server.");
  });

  test('a failed action after a good load is not a load failure', () async {
    await vm.doLoad(() async {});
    await vm.doRun(() async => throw const ApiException(code: 'CONFLICT', message: 'Taken.'));

    expect(vm.loadFailed, isFalse);
    expect(vm.isSaving, isFalse);
    expect(vm.errorMessage, 'Taken.');
  });

  test('unexpected errors never reach the screen as raw text', () async {
    await vm.doRun(() async => throw StateError('null check operator used on a null value'));

    expect(vm.error!.code, ApiException.codeUnexpected);
    expect(vm.errorMessage, 'Something went wrong. Please try again.');
  });

  test('fieldError reads client and server field errors alike', () async {
    vm.fail(ApiException.validation({'name': 'Enter the name.'}));
    expect(vm.fieldError('name'), 'Enter the name.');

    await vm.doRun(() async => throw const ApiException(
          code: 'CONFLICT',
          statusCode: 409,
          message: 'Exists.',
          details: [FieldViolation('name', 'Exists.')],
        ));
    expect(vm.fieldError('name'), 'Exists.');

    vm.clearError();
    expect(vm.fieldError('name'), isNull);
  });

  test('finishing after dispose does not throw', () async {
    final pending = vm.doRun(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    vm.dispose();
    expect(await pending, isTrue);
  });
}
