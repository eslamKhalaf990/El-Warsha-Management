import 'package:flutter_test/flutter_test.dart';
import 'package:warsha_app/models/voucher.dart';
import 'package:warsha_app/services/vouchers_service.dart';
import 'package:warsha_app/view_models/vouchers_v_m.dart';

class FakeVouchers implements VouchersService {
  List<Voucher> rows = [Voucher(id: 1, code: 'SAVE10', kind: DiscountKind.percentage, value: 10, startDate: DateTime(2026))];

  @override
  Future<List<Voucher>> list() async => rows;

  @override
  Future<Voucher> create(VoucherRequest r) async =>
      Voucher(id: 2, code: r.toJson()['code'], kind: r.kind, value: r.value!, startDate: r.startDate!);

  @override
  Future<Voucher> update(int id, VoucherRequest r) async =>
      Voucher(id: id, code: r.toJson()['code'], kind: r.kind, value: r.value!, startDate: r.startDate!, active: r.active);

  @override
  Future<void> delete(int id) async {}
}

void main() {
  late VouchersVM vm;

  setUp(() async {
    vm = VouchersVM(FakeVouchers());
    await vm.fetch();
  });

  VoucherForm form(String code, {String value = '10', DiscountKind kind = DiscountKind.percentage}) =>
      VoucherForm(code: code, kind: kind, value: value, startDate: DateTime(2026, 2));

  test('checks the code, the value and the dates', () {
    expect(vm.validate(form('')).keys, contains('code'));
    expect(vm.validate(form('HAS SPACE')).keys, contains('code'));
    expect(vm.validate(form('save10'))['code'], contains('already exists'));
    expect(vm.validate(form('OK', value: '120'))['discountValue'], contains('100'));
    expect(vm.validate(form('OK', value: '120', kind: DiscountKind.fixed)), isEmpty);
    final backwards = VoucherForm(code: 'OK', kind: DiscountKind.fixed, value: '5', startDate: DateTime(2026, 2), endDate: DateTime(2026, 1));
    expect(vm.validate(backwards).keys, contains('endDate'));
  });

  test('saves a new code in capitals, first in the list', () async {
    expect(await vm.save(form('ramadan')), isTrue);
    expect(vm.allVouchers.first.code, 'RAMADAN');
  });

  test('state follows dates, limit and the switch', () {
    final day = DateTime(2026, 6, 1);
    Voucher v({bool active = true, DateTime? start, DateTime? end, int? limit, int used = 0}) => Voucher(
        id: 1, code: 'X', kind: DiscountKind.fixed, value: 1, startDate: start ?? DateTime(2026),
        endDate: end, active: active, usageLimit: limit, usageCount: used);

    expect(v().stateOn(day), VoucherState.active);
    expect(v(active: false).stateOn(day), VoucherState.off);
    expect(v(start: DateTime(2026, 7)).stateOn(day), VoucherState.scheduled);
    expect(v(end: DateTime(2026, 5)).stateOn(day), VoucherState.expired);
    expect(v(limit: 3, used: 3).stateOn(day), VoucherState.usedUp);
  });
}
