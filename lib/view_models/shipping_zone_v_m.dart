import 'package:flutter/foundation.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/core/state/async_view_model.dart';
import 'package:warsha_app/core/validation/validators.dart';
import 'package:warsha_app/models/shipping_zone.dart';
import 'package:warsha_app/services/shipping_zone_service.dart';

/// Shipping zones screen, plus delivery prices for the order and customer forms.
class ShippingZoneVM extends ChangeNotifier with AsyncViewModel {
  ShippingZoneVM(this._service);

  final ShippingZoneService _service;

  static const nameMaxLength = 100;

  List<ShippingZone> _all = [];
  String _query = '';

  List<ShippingZone> get allZones => List.unmodifiable(_all);

  /// Zones customers can be delivered to, in the order the ERP lists them.
  List<ShippingZone> get activeZones => _all.where((z) => z.isActive).toList();

  /// Zones matching the search box; spelling variants match too.
  List<ShippingZone> get zones {
    final q = _query.trim();
    if (q.isEmpty) return allZones;
    final key = governorateKey(q);
    return _all.where((z) => governorateKey(z.cityName).contains(key)).toList();
  }

  String get query => _query;

  /// Delivery price for [governorate], or null when it has no active zone.
  double? priceFor(String? governorate) {
    if (governorate == null || governorate.trim().isEmpty) return null;
    final key = governorateKey(governorate);
    for (final zone in activeZones) {
      if (governorateKey(zone.cityName) == key) return zone.shippingPrice;
    }
    return null;
  }

  Future<bool> fetch() => load(() async => _all = await _service.list());

  void search(String query) {
    if (query == _query) return;
    _query = query;
    notify();
  }

  // ── Validation ──────────────────────────────────────────

  /// Parses the price box: null when empty or not a number.
  static double? parsePrice(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

  Map<String, String> validate(ShippingZoneRequest r, {required String priceText, int? editingId}) {
    final errors = Validators.collect({
      'cityName': () => Validators.firstOf([
            () => Validators.required(r.cityName, 'Enter the governorate name.'),
            () => Validators.maxLength(r.cityName, nameMaxLength, 'Governorate name'),
          ]),
      'shippingFee': () => Validators.firstOf([
            () => Validators.nonNegativeNumber(priceText, 'Delivery price', required: true),
            () => RegExp(r'^\d+([.,]\d{1,2})?$').hasMatch(priceText.trim())
                ? null
                : 'Delivery price can have at most 2 decimal places.',
          ]),
    });
    if (!errors.containsKey('cityName')) {
      final key = governorateKey(r.cityName);
      final clash = _all.where((z) => z.id != editingId && governorateKey(z.cityName) == key);
      if (clash.isNotEmpty) errors['cityName'] = "'${clash.first.cityName}' already has a delivery price.";
    }
    return errors;
  }

  // ── CRUD ────────────────────────────────────────────────

  /// Adds a zone, or updates [editingId]. [priceText] is the raw price box.
  Future<bool> save({required String cityName, required String priceText, required bool isActive, int? editingId}) async {
    final request = ShippingZoneRequest(cityName: cityName, shippingFee: parsePrice(priceText), isActive: isActive);
    final errors = validate(request, priceText: priceText, editingId: editingId);
    if (errors.isNotEmpty) return fail(ApiException.validation(errors));
    return run(() async {
      if (editingId == null) {
        _all = [..._all, await _service.create(request)];
      } else {
        final updated = await _service.update(editingId, request);
        _all = [for (final z in _all) z.id == editingId ? updated : z];
      }
    });
  }

  /// Turns a zone on or off for the store without deleting its price.
  Future<bool> setActive(ShippingZone zone, bool active) => run(() async {
        final updated = await _service.update(
          zone.id!,
          ShippingZoneRequest(cityName: zone.cityName, shippingFee: zone.shippingPrice, isActive: active),
        );
        _all = [for (final z in _all) z.id == zone.id ? updated : z];
      });

  Future<bool> delete(ShippingZone zone) => run(() async {
        await _service.delete(zone.id!);
        _all = _all.where((z) => z.id != zone.id).toList();
      });
}
