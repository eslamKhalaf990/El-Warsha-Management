import 'package:flutter_test/flutter_test.dart';
import 'package:warsha_app/models/shipping_zone.dart';

void main() {
  test('governorate names match across common spellings', () {
    expect(governorateKey('الاسكندريه'), governorateKey('الإسكندرية'));
    expect(governorateKey(' اسكندرية '), governorateKey('الإسكندرية'));
    expect(governorateKey('جيزة'), governorateKey('الجيزة'));
    expect(governorateKey('القاهرة'), isNot(governorateKey('الجيزة')));
  });

  test('zones are active unless the server says otherwise', () {
    expect(ShippingZone.fromJson({'id': 1, 'cityName': 'القاهرة', 'shippingFee': 80}).isActive, isTrue);
    expect(ShippingZone.fromJson({'id': 2, 'cityName': 'مطروح', 'shippingFee': 130, 'isActive': false}).isActive,
        isFalse);
  });
}
