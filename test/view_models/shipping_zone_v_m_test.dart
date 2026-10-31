import 'package:flutter_test/flutter_test.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/models/shipping_zone.dart';
import 'package:warsha_app/services/shipping_zone_service.dart';
import 'package:warsha_app/view_models/shipping_zone_v_m.dart';

class FakeZoneService implements ShippingZoneService {
  ApiException? failWith;
  int calls = 0;
  ShippingZoneRequest? lastRequest;

  Future<T> _answer<T>(T value) async {
    calls++;
    if (failWith != null) throw failWith!;
    return value;
  }

  @override
  Future<List<ShippingZone>> list() => _answer([
        ShippingZone(id: 1, cityName: 'القاهرة', shippingPrice: 80),
        ShippingZone(id: 2, cityName: 'الإسكندرية', shippingPrice: 90),
        ShippingZone(id: 3, cityName: 'مطروح', shippingPrice: 130, isActive: false),
      ]);

  ShippingZone _from(int id, ShippingZoneRequest r) {
    lastRequest = r;
    return ShippingZone(id: id, cityName: r.cityName.trim(), shippingPrice: r.shippingFee!, isActive: r.isActive);
  }

  @override
  Future<ShippingZone> create(ShippingZoneRequest r) => _answer(_from(4, r));

  @override
  Future<ShippingZone> update(int id, ShippingZoneRequest r) => _answer(_from(id, r));

  @override
  Future<void> delete(int id) => _answer(null);
}

void main() {
  late FakeZoneService service;
  late ShippingZoneVM vm;

  setUp(() async {
    service = FakeZoneService();
    vm = ShippingZoneVM(service);
    await vm.fetch();
    service.calls = 0;
  });

  test('priceFor matches spelling variants and skips inactive zones', () {
    expect(vm.priceFor('الاسكندريه'), 90);
    expect(vm.priceFor('مطروح'), isNull);
    expect(vm.priceFor(''), isNull);
  });

  test('search uses the same loose matching', () {
    vm.search('اسكندري');
    expect(vm.zones.map((z) => z.id), [2]);
  });

  test('price box is validated before calling the server', () async {
    for (final (text, message) in [
      ('', 'Enter the delivery price.'),
      ('abc', 'Delivery price must be a number.'),
      ('-5', "Delivery price can't be negative."),
      ('12.345', 'Delivery price can have at most 2 decimal places.'),
    ]) {
      expect(await vm.save(cityName: 'أسوان', priceText: text, isActive: true), isFalse, reason: text);
      expect(vm.fieldError('shippingFee'), message, reason: text);
    }
    expect(service.calls, 0);
  });

  test('a governorate can only have one zone, whatever the spelling', () async {
    expect(await vm.save(cityName: 'القاهره', priceText: '70', isActive: true), isFalse);
    expect(vm.fieldError('cityName'), "'القاهرة' already has a delivery price.");
  });

  test('saving accepts a comma as decimal separator', () async {
    expect(await vm.save(cityName: 'أسوان', priceText: '150,5', isActive: true), isTrue);
    expect(service.lastRequest!.shippingFee, 150.5);
    expect(vm.priceFor('أسوان'), 150.5);
  });

  test('editing keeps its own name and can deactivate', () async {
    expect(await vm.save(cityName: 'القاهرة', priceText: '85', isActive: false, editingId: 1), isTrue);
    expect(vm.priceFor('القاهرة'), isNull);
  });

  test('setActive reopens a zone with its old price', () async {
    expect(await vm.setActive(vm.allZones[2], true), isTrue);
    expect(vm.priceFor('مطروح'), 130);
  });

  test('a failed delete keeps the zone', () async {
    service.failWith = ApiException.network();
    expect(await vm.delete(vm.allZones.first), isFalse);
    expect(vm.allZones, hasLength(3));
    expect(vm.errorMessage, contains("Can't reach the server"));
  });
}
