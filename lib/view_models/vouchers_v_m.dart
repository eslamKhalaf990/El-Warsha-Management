import 'package:flutter/foundation.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/core/state/async_view_model.dart';
import 'package:warsha_app/core/validation/validators.dart';
import 'package:warsha_app/models/voucher.dart';
import 'package:warsha_app/services/vouchers_service.dart';

/// What the promo code form holds, as typed.
class VoucherForm {
  const VoucherForm({
    required this.code,
    required this.kind,
    required this.value,
    this.minOrder = '',
    this.maxDiscount = '',
    this.usageLimit = '',
    this.startDate,
    this.endDate,
    this.active = true,
  });

  final String code;
  final DiscountKind kind;
  final String value;
  final String minOrder;
  final String maxDiscount;
  final String usageLimit;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool active;

  static double? _n(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  VoucherRequest toRequest() => VoucherRequest(
        code: code,
        kind: kind,
        value: _n(value),
        minOrder: _n(minOrder),
        maxDiscount: _n(maxDiscount),
        startDate: startDate,
        endDate: endDate,
        active: active,
        usageLimit: int.tryParse(usageLimit.trim()),
      );
}

/// Promo codes screen: list, add, edit, turn on/off, delete.
class VouchersVM extends ChangeNotifier with AsyncViewModel {
  VouchersVM(this._service);

  final VouchersService _service;

  static const codeMaxLength = 50;
  static const formFields = ['code', 'type', 'discountValue', 'minOrderAmount', 'maxDiscountAmount', 'startDate', 'endDate', 'maxUsageLimit'];

  List<Voucher> _all = [];
  String _query = '';

  List<Voucher> get allVouchers => List.unmodifiable(_all);
  String get query => _query;

  List<Voucher> get vouchers {
    final q = _query.trim().toUpperCase();
    return q.isEmpty ? allVouchers : _all.where((v) => v.code.contains(q)).toList();
  }

  int get liveCount => _all.where((v) => v.stateOn(DateTime.now()) == VoucherState.active).length;

  Future<bool> fetch() => load(() async => _all = await _service.list());

  void setQuery(String q) {
    _query = q;
    notify();
  }

  Map<String, String> validate(VoucherForm f, {int? editingId}) {
    final errors = Validators.collect({
      'code': () => Validators.firstOf([
            () => Validators.required(f.code, 'Enter the code customers type.'),
            () => Validators.maxLength(f.code, codeMaxLength, 'Code'),
            () => RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(f.code.trim()) ? null : 'Use letters, numbers, - or _ only, no spaces.',
          ]),
      'discountValue': () => Validators.firstOf([
            () => Validators.nonNegativeNumber(f.value, 'Discount', required: true),
            () => (VoucherForm._n(f.value) ?? 0) <= 0 ? 'Discount must be more than 0.' : null,
            () => f.kind == DiscountKind.percentage && VoucherForm._n(f.value)! > 100 ? 'A percentage can be at most 100.' : null,
          ]),
      'minOrderAmount': () => Validators.nonNegativeNumber(f.minOrder, 'Minimum order'),
      'maxDiscountAmount': () => Validators.nonNegativeNumber(f.maxDiscount, 'Maximum discount'),
      'maxUsageLimit': () {
        final t = f.usageLimit.trim();
        if (t.isEmpty) return null;
        final n = int.tryParse(t);
        return n == null || n < 1 ? 'Usage limit must be a whole number from 1.' : null;
      },
      'startDate': () => f.startDate == null ? 'Choose the start date.' : null,
      'endDate': () => f.startDate != null && f.endDate != null && f.endDate!.isBefore(f.startDate!)
          ? "The end date can't be before the start date."
          : null,
    });
    if (!errors.containsKey('code')) {
      final code = f.code.trim().toUpperCase();
      if (_all.any((v) => v.id != editingId && v.code == code)) errors['code'] = 'The code $code already exists.';
    }
    return errors;
  }

  Future<bool> save(VoucherForm form, {Voucher? editing}) async {
    final errors = validate(form, editingId: editing?.id);
    if (errors.isNotEmpty) return fail(ApiException.validation(errors));
    return run(() async {
      if (editing == null) {
        _all = [await _service.create(form.toRequest()), ..._all];
      } else {
        final updated = await _service.update(editing.id, form.toRequest());
        _all = [for (final v in _all) v.id == editing.id ? updated : v];
      }
    });
  }

  Future<bool> setActive(Voucher v, bool active) => run(() async {
        final updated = await _service.update(
          v.id,
          VoucherRequest(
            code: v.code,
            kind: v.kind,
            value: v.value,
            minOrder: v.minOrder,
            maxDiscount: v.maxDiscount,
            startDate: v.startDate,
            endDate: v.endDate,
            active: active,
            usageLimit: v.usageLimit,
          ),
        );
        _all = [for (final x in _all) x.id == v.id ? updated : x];
      });

  Future<bool> delete(Voucher v) => run(() async {
        await _service.delete(v.id);
        _all = _all.where((x) => x.id != v.id).toList();
      });
}
