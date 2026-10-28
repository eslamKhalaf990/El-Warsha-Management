import 'package:flutter_test/flutter_test.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/models/customerModel.dart';
import 'package:warsha_app/services/customers_services.dart';
import 'package:warsha_app/view_models/customers_v_m.dart';

CustomerModel customer(int id, String name, String phone, String governorate) => CustomerModel(
      customerId: id,
      fullName: name,
      governorate: governorate,
      secondaryPhone: '',
      city: '',
      phone: phone,
      address: '',
    );

class FakeCustomerService implements CustomerService {
  ApiException? failWith;
  int calls = 0;

  Future<T> _answer<T>(T value) async {
    calls++;
    if (failWith != null) throw failWith!;
    return value;
  }

  @override
  Future<List<CustomerModel>> list() => _answer([
        customer(2, 'Sara Ahmed', '0100 123 4567', 'القاهرة'),
        customer(1, 'Mona Ali', '01212345678', 'القاهرة'),
        customer(3, 'Omar', '01512345678', 'الجيزة'),
      ]);

  @override
  Future<CustomerModel> create(CustomerRequest r) =>
      _answer(customer(9, r.fullName.trim(), r.phone, r.governorate));

  @override
  Future<CustomerModel> update(int id, CustomerRequest r) =>
      _answer(customer(id, r.fullName.trim(), r.phone, r.governorate));

  @override
  Future<void> delete(int id) => _answer(null);
}

void main() {
  late FakeCustomerService service;
  late CustomerVM vm;

  setUp(() async {
    service = FakeCustomerService();
    vm = CustomerVM(service);
    await vm.fetch();
    service.calls = 0;
  });

  test('search finds by name, any phone format or customer number', () {
    expect(vm.search('mona').map((c) => c.customerId), [1]);
    expect(vm.search('+20 100 1234').map((c) => c.customerId), [2]);
    expect(vm.search('#3').map((c) => c.customerId), [3]);
    expect(vm.search('', limit: 2), hasLength(2));
  });

  test('governorate counts come from the loaded customers', () {
    expect(vm.governorateCounts.map((g) => (g.governorate, g.count)), [('القاهرة', 2), ('الجيزة', 1)]);
  });

  test('required fields and phone formats are checked locally', () async {
    final ok = await vm.add(const CustomerRequest(fullName: ' ', phone: '0221234567', governorate: '', email: 'x@'));

    expect(ok, isFalse);
    expect(vm.fieldError('fullName'), "Enter the customer's name.");
    expect(vm.fieldError('phone'), 'Enter a valid mobile number, e.g. 01012345678.');
    expect(vm.fieldError('governorate'), 'Choose the governorate.');
    expect(vm.fieldError('email'), 'Enter a valid email address.');
    expect(service.calls, 0);
  });

  test('a phone already on file is caught in any format', () async {
    expect(await vm.add(const CustomerRequest(fullName: 'New', phone: '+201001234567', governorate: 'القاهرة')), isFalse);
    expect(vm.fieldError('phone'), 'This number belongs to Sara Ahmed (customer #2).');
  });

  test('editing keeps the customer\'s own phone', () async {
    expect(await vm.update(2, const CustomerRequest(fullName: 'Sara A.', phone: '01001234567', governorate: 'القاهرة')),
        isTrue);
    expect(vm.lastSaved!.fullName, 'Sara A.');
    expect(vm.allCustomers.firstWhere((c) => c.customerId == 2).fullName, 'Sara A.');
  });

  test('a new customer goes to the top and counts update', () async {
    expect(await vm.add(const CustomerRequest(fullName: 'Nour', phone: '01098765432', governorate: 'الجيزة')), isTrue);
    expect(vm.allCustomers.first.customerId, 9);
    expect(vm.governorateCounts.last.count, 2);
  });

  test('a refused delete keeps the customer and explains why', () async {
    service.failWith = const ApiException(
        code: 'CONFLICT', statusCode: 409, message: "Omar has 2 orders, so they can't be deleted.");

    expect(await vm.delete(vm.allCustomers.last), isFalse);
    expect(vm.allCustomers, hasLength(3));
    expect(vm.errorMessage, contains('2 orders'));
  });
}
