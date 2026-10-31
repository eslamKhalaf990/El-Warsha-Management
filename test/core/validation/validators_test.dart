import 'package:flutter_test/flutter_test.dart';
import 'package:warsha_app/core/validation/validators.dart';

void main() {
  test('required rejects empty and blank text', () {
    expect(Validators.required(null, 'Enter it.'), 'Enter it.');
    expect(Validators.required('   ', 'Enter it.'), 'Enter it.');
    expect(Validators.required('x', 'Enter it.'), isNull);
  });

  test('maxLength counts trimmed text', () {
    expect(Validators.maxLength(' abc ', 3, 'Name'), isNull);
    expect(Validators.maxLength('abcd', 3, 'Name'), 'Name can be at most 3 characters.');
  });

  test('egyptianMobile accepts 010/011/012/015 numbers with spaces or dashes', () {
    expect(Validators.egyptianMobile('010 1234-5678'), isNull);
    expect(Validators.egyptianMobile('01512345678'), isNull);
    expect(Validators.egyptianMobile('01312345678'), isNotNull);
    expect(Validators.egyptianMobile('0101234567'), isNotNull);
  });

  test('phone is optional and accepts common formats', () {
    expect(Validators.phone(''), isNull);
    expect(Validators.phone('+20 (2) 2345-6789'), isNull);
    expect(Validators.phone('12'), isNotNull);
    expect(Validators.phone('call me'), isNotNull);
  });

  test('email is optional but must look like one', () {
    expect(Validators.email(''), isNull);
    expect(Validators.email('a@b.co'), isNull);
    expect(Validators.email('a@b'), isNotNull);
  });

  test('nonNegativeNumber', () {
    expect(Validators.nonNegativeNumber('', 'price'), isNull);
    expect(Validators.nonNegativeNumber('', 'Price', required: true), 'Enter the price.');
    expect(Validators.nonNegativeNumber('12,5', 'Price'), isNull);
    expect(Validators.nonNegativeNumber('abc', 'Price'), 'Price must be a number.');
    expect(Validators.nonNegativeNumber('-1', 'Price'), "Price can't be negative.");
    expect(Validators.nonNegativeNumber('12.5', 'Price'), isNull);
  });

  test('firstOf stops at the first failure; collect keeps only failing fields', () {
    expect(Validators.firstOf([() => null, () => 'second', () => 'third']), 'second');
    expect(Validators.collect({'a': () => null, 'b': () => 'bad'}), {'b': 'bad'});
  });
}
