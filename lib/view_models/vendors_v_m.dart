import 'package:flutter/foundation.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/core/state/async_view_model.dart';
import 'package:warsha_app/core/validation/validators.dart';
import 'package:warsha_app/models/vendor.dart';
import 'package:warsha_app/services/vendors_service.dart';

/// Vendors screen: list, search, add, edit and archive.
class VendorVM extends ChangeNotifier with AsyncViewModel {
  VendorVM(this._service);

  final VendorService _service;

  // Same limits as the Vendors table.
  static const nameMaxLength = 200;
  static const phoneMaxLength = 50;
  static const emailMaxLength = 255;
  static const addressMaxLength = 300;
  static const taxNumberMaxLength = 50;
  static const contactPersonMaxLength = 100;
  static const notesMaxLength = 2000;

  List<Vendor> _all = [];
  String _query = '';

  List<Vendor> get allVendors => List.unmodifiable(_all);

  /// Vendors whose name, contact person, phone or tax number match the search.
  List<Vendor> get vendors {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return allVendors;
    bool has(String? s) => s != null && s.toLowerCase().contains(q);
    return _all.where((v) => has(v.name) || has(v.contactPerson) || has(v.phone) || has(v.taxNumber)).toList();
  }

  String get query => _query;

  Future<bool> fetch() => load(() async => _all = await _service.list());

  void search(String query) {
    if (query == _query) return;
    _query = query;
    notify();
  }

  // ── Validation ──────────────────────────────────────────

  Map<String, String> validate(VendorRequest r, {int? editingId}) {
    final errors = Validators.collect({
      'name': () => Validators.firstOf([
            () => Validators.required(r.name, 'Enter the vendor name.'),
            () => Validators.maxLength(r.name, nameMaxLength, 'Vendor name'),
          ]),
      'phone': () => Validators.firstOf([
            () => Validators.maxLength(r.phone, phoneMaxLength, 'Phone'),
            () => Validators.phone(r.phone),
          ]),
      'email': () => Validators.firstOf([
            () => Validators.maxLength(r.email, emailMaxLength, 'Email'),
            () => Validators.email(r.email),
          ]),
      'address': () => Validators.maxLength(r.address, addressMaxLength, 'Address'),
      'taxNumber': () => Validators.maxLength(r.taxNumber, taxNumberMaxLength, 'Tax number'),
      'contactPerson': () => Validators.maxLength(r.contactPerson, contactPersonMaxLength, 'Contact person'),
      'notes': () => Validators.maxLength(r.notes, notesMaxLength, 'Notes'),
    });
    if (!errors.containsKey('name')) {
      final key = _key(r.name);
      final clash = _all.where((v) => v.vendorId != editingId && _key(v.name) == key);
      if (clash.isNotEmpty) errors['name'] = 'A vendor named "${clash.first.name}" already exists.';
    }
    return errors;
  }

  // ── CRUD ────────────────────────────────────────────────
  // Each returns true on success; on failure [error] / [fieldError] say why.

  Future<bool> add(VendorRequest request) async {
    final errors = validate(request);
    if (errors.isNotEmpty) return fail(ApiException.validation(errors));
    return run(() async => _all = [..._all, await _service.create(request)]);
  }

  Future<bool> update(int id, VendorRequest request) async {
    final errors = validate(request, editingId: id);
    if (errors.isNotEmpty) return fail(ApiException.validation(errors));
    return run(() async {
      final updated = await _service.update(id, request);
      _all = [for (final v in _all) v.vendorId == id ? updated : v];
    });
  }

  Future<bool> archive(Vendor vendor) => run(() async {
        await _service.archive(vendor.vendorId);
        _all = _all.where((v) => v.vendorId != vendor.vendorId).toList();
      });

  static String _key(String name) => name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}
