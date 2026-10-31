import 'package:flutter_test/flutter_test.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/models/vendor.dart';
import 'package:warsha_app/services/vendors_service.dart';
import 'package:warsha_app/view_models/vendors_v_m.dart';

class FakeVendorService implements VendorService {
  ApiException? failWith;
  int calls = 0;

  Future<T> _answer<T>(T value) async {
    calls++;
    if (failWith != null) throw failWith!;
    return value;
  }

  @override
  Future<List<Vendor>> list({bool includeArchived = false}) => _answer(const [
        Vendor(vendorId: 1, name: 'Silver Co', contactPerson: 'Mona', phone: '01012345678'),
        Vendor(vendorId: 2, name: 'Box House', taxNumber: 'TX-77'),
      ]);

  @override
  Future<Vendor> create(VendorRequest r) => _answer(Vendor(vendorId: 3, name: r.name.trim()));

  @override
  Future<Vendor> update(int id, VendorRequest r) => _answer(Vendor(vendorId: id, name: r.name.trim()));

  @override
  Future<void> archive(int id) => _answer(null);
}

void main() {
  late FakeVendorService service;
  late VendorVM vm;

  setUp(() async {
    service = FakeVendorService();
    vm = VendorVM(service);
    await vm.fetch();
    service.calls = 0;
  });

  test('search matches name, contact person, phone and tax number', () {
    for (final (query, expected) in [('mona', 'Silver Co'), ('0101', 'Silver Co'), ('tx-7', 'Box House'), ('box', 'Box House')]) {
      vm.search(query);
      expect(vm.vendors.map((v) => v.name), [expected], reason: query);
    }
  });

  test('every invalid field is reported at once, without calling the server', () async {
    final ok = await vm.add(const VendorRequest(name: ' ', phone: 'call me', email: 'nope'));

    expect(ok, isFalse);
    expect(vm.fieldError('name'), 'Enter the vendor name.');
    expect(vm.fieldError('phone'), 'Enter a valid phone number.');
    expect(vm.fieldError('email'), 'Enter a valid email address.');
    expect(vm.errorMessage, 'Please fix the highlighted fields.');
    expect(service.calls, 0);
  });

  test('phone accepts mobile, landline and international formats', () async {
    for (final phone in ['01012345678', '02 2345 6789', '+20 100 123-4567', '(03) 4801234']) {
      expect(vm.validate(VendorRequest(name: 'New', phone: phone)), isEmpty, reason: phone);
    }
  });

  test('duplicate names are caught locally', () async {
    expect(await vm.add(const VendorRequest(name: 'silver  co')), isFalse);
    expect(vm.fieldError('name'), 'A vendor named "Silver Co" already exists.');
  });

  test('add, edit and archive keep the list in sync', () async {
    expect(await vm.add(const VendorRequest(name: 'Gold Co')), isTrue);
    expect(await vm.update(1, const VendorRequest(name: 'Silver Company')), isTrue);
    expect(await vm.archive(vm.allVendors[1]), isTrue);

    expect(vm.allVendors.map((v) => v.name), ['Silver Company', 'Gold Co']);
  });

  test('a server error keeps the list and shows the message', () async {
    service.failWith = ApiException.timeout();

    expect(await vm.archive(vm.allVendors.first), isFalse);
    expect(vm.allVendors, hasLength(2));
    expect(vm.errorMessage, contains('taking too long'));
    expect(vm.isSaving, isFalse);
  });
}
