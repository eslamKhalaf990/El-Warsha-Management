import 'package:flutter/foundation.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/core/state/async_view_model.dart';
import 'package:warsha_app/core/validation/validators.dart';
import 'package:warsha_app/models/customerModel.dart';
import 'package:warsha_app/models/governorate_count.dart';
import 'package:warsha_app/services/customers_services.dart';

/// Customers screen (list, search, add, edit, delete) and the customer
/// pickers on the order screens.
class CustomerVM extends ChangeNotifier with AsyncViewModel {
  CustomerVM(this._service);

  final CustomerService _service;

  // Same limits as the Customers table.
  static const nameMaxLength = 100;
  static const phoneMaxLength = 20;
  static const cityMaxLength = 60;
  static const addressMaxLength = 255;
  static const emailMaxLength = 255;

  static const formFields = ['fullName', 'phone', 'secondaryPhone', 'governorate', 'city', 'address', 'email'];

  List<CustomerModel> _all = [];
  String _query = '';
  CustomerModel? _lastSaved;

  /// Every customer, newest first.
  List<CustomerModel> get allCustomers => List.unmodifiable(_all);

  /// Customers matching the Customers screen's search box.
  List<CustomerModel> get customers => search(_query);

  String get query => _query;

  /// The customer created or updated by the last successful [add] / [update].
  CustomerModel? get lastSaved => _lastSaved;

  /// Customers per governorate, most first.
  List<GovernorateCountPerCustomer> get governorateCounts {
    final counts = <String, int>{};
    for (final c in _all) {
      final g = c.governorate.trim().isEmpty ? 'Unknown' : c.governorate.trim();
      counts[g] = (counts[g] ?? 0) + 1;
    }
    final list = [for (final e in counts.entries) GovernorateCountPerCustomer(governorate: e.key, count: e.value)];
    list.sort((a, b) => b.count.compareTo(a.count));
    return list;
  }

  Future<bool> fetch() => load(() async => _all = await _service.list());

  void setQuery(String query) {
    if (query == _query) return;
    _query = query;
    notify();
  }

  /// Customers whose name, phone (any format) or number match [query].
  /// Pure: the order screens call it with their own search text.
  List<CustomerModel> search(String query, {int? limit}) {
    final q = query.trim().toLowerCase();
    Iterable<CustomerModel> result = _all;
    if (q.isNotEmpty) {
      final digits = normalizePhone(q);
      result = _all.where((c) =>
          c.fullName.toLowerCase().contains(q) ||
          '${c.customerId}' == q.replaceFirst('#', '') ||
          (digits.length >= 3 && (normalizePhone(c.phone).contains(digits) || normalizePhone(c.secondaryPhone).contains(digits))));
    }
    return (limit == null ? result : result.take(limit)).toList();
  }

  // ── Validation ──────────────────────────────────────────

  /// Digits only, with +20 / 0020 turned into the local 0 (same as the backend).
  static String normalizePhone(String phone) {
    var s = phone.replaceAll(RegExp(r'[\s\-()]'), '');
    if (s.startsWith('+20')) {
      s = '0${s.substring(3)}';
    } else if (s.startsWith('0020')) {
      s = '0${s.substring(4)}';
    }
    return s;
  }

  Map<String, String> validate(CustomerRequest r, {int? editingId}) {
    final errors = Validators.collect({
      'fullName': () => Validators.firstOf([
            () => Validators.required(r.fullName, "Enter the customer's name."),
            () => Validators.maxLength(r.fullName, nameMaxLength, 'Name'),
          ]),
      'phone': () => Validators.firstOf([
            () => Validators.required(r.phone, "Enter the customer's mobile number."),
            () => Validators.egyptianMobile(normalizePhone(r.phone)),
          ]),
      'secondaryPhone': () => Validators.firstOf([
            () => Validators.maxLength(r.secondaryPhone, phoneMaxLength, 'Second phone'),
            () => Validators.phone(r.secondaryPhone),
          ]),
      'governorate': () => Validators.required(r.governorate, 'Choose the governorate.'),
      'city': () => Validators.maxLength(r.city, cityMaxLength, 'City'),
      'address': () => Validators.maxLength(r.address, addressMaxLength, 'Address'),
      'email': () => Validators.firstOf([
            () => Validators.maxLength(r.email, emailMaxLength, 'Email'),
            () => Validators.email(r.email),
          ]),
    });
    if (!errors.containsKey('phone')) {
      final phone = normalizePhone(r.phone);
      final owner = _all.where((c) => c.customerId != editingId && normalizePhone(c.phone) == phone);
      if (owner.isNotEmpty) {
        errors['phone'] = 'This number belongs to ${owner.first.fullName} (customer #${owner.first.customerId}).';
      }
    }
    return errors;
  }

  // ── CRUD ────────────────────────────────────────────────
  // Each returns true on success; on failure [error] / [fieldError] say why.

  Future<bool> add(CustomerRequest request) async {
    final errors = validate(request);
    if (errors.isNotEmpty) return fail(ApiException.validation(errors));
    return run(() async {
      final created = await _service.create(request);
      _lastSaved = created;
      _all = [created, ..._all];
    });
  }

  Future<bool> update(int id, CustomerRequest request) async {
    final errors = validate(request, editingId: id);
    if (errors.isNotEmpty) return fail(ApiException.validation(errors));
    return run(() async {
      final updated = await _service.update(id, request);
      _lastSaved = updated;
      _all = [for (final c in _all) c.customerId == id ? updated : c];
    });
  }

  Future<bool> delete(CustomerModel customer) => run(() async {
        await _service.delete(customer.customerId);
        _all = _all.where((c) => c.customerId != customer.customerId).toList();
      });
}
