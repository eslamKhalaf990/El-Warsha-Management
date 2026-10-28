import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:warsha_app/models/shipping_zone.dart';
import 'package:warsha_app/services/shipping_zone_service.dart';
import 'package:warsha_app/view_models/user_v_m.dart';

class ShippingZoneVM extends ChangeNotifier {
  final ShippingZoneService _shippingZoneService;
  final UserViewModel _userViewModel;

  List<ShippingZone>? allZones;
  bool isLoading = false;

  /// Zones customers can be delivered to, in the order the ERP lists them.
  List<ShippingZone> get activeZones => (allZones ?? []).where((z) => z.isActive).toList();

  /// Delivery price for [governorate], or null when it has no active zone.
  double? priceFor(String? governorate) {
    if (governorate == null || governorate.trim().isEmpty) return null;
    final key = governorateKey(governorate);
    for (final zone in activeZones) {
      if (governorateKey(zone.cityName) == key) return zone.shippingPrice;
    }
    return null;
  }

  ShippingZoneVM(this._shippingZoneService, this._userViewModel) {
    initZones();
  }

  void initZones() async {
    await getAllShippingZones();
  }

  Future<String> getAllShippingZones() async {
    String status = "";
    isLoading = true;
    notifyListeners();

    try {
      final response = await _shippingZoneService.getAllShippingZones(_userViewModel.token);

      if (response.statusCode == 200) {
        status = "zones_fetched";
        final data = jsonDecode(response.body) as List;
        allZones = data.map((item) => ShippingZone.fromJson(item)).toList();
        debugPrint("Shipping zones fetched successfully");
      } else {
        status = "zones_not_fetched";
        debugPrint("Failed to fetch shipping zones: ${response.statusCode}");
      }
    } catch (e) {
      status = "zones_not_fetched";
      debugPrint("Error fetching shipping zones: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return status;
  }

  Future<String> addShippingZone(Map<String, dynamic> zoneData) async {
    String status = "";
    try {
      isLoading = true;
      notifyListeners();

      final response = await _shippingZoneService.addShippingZone(_userViewModel.token, zoneData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint("Shipping zone added successfully");
        await getAllShippingZones();
        status = "zone_added";
      } else {
        debugPrint("Failed to add shipping zone: ${response.statusCode}");
        status = "zone_not_added";
      }
    } catch (e) {
      debugPrint("Error adding shipping zone: $e");
      status = "zone_not_added";
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return status;
  }

  Future<String> updateShippingZone(int id, double shippingPrice) async {
    String status = "";
    try {
      isLoading = true;
      notifyListeners();

      final response = await _shippingZoneService.updateShippingZone(_userViewModel.token, id, shippingPrice);

      if (response.statusCode == 200) {
        debugPrint("Shipping zone updated successfully");
        await getAllShippingZones();
        status = "zone_updated";
      } else {
        debugPrint("Failed to update shipping zone: ${response.statusCode}");
        status = "zone_not_updated";
      }
    } catch (e) {
      debugPrint("Error updating shipping zone: $e");
      status = "zone_not_updated";
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return status;
  }

  Future<String> deleteShippingZone(int id) async {
    String status = "";
    try {
      isLoading = true;
      notifyListeners();

      final response = await _shippingZoneService.deleteShippingZone(_userViewModel.token, id);

      if (response.statusCode == 200 || response.statusCode == 204) {
        status = "zone_deleted";
        debugPrint("Shipping zone deleted successfully");
        await getAllShippingZones();
      } else {
        debugPrint("Failed to delete shipping zone: ${response.statusCode}");
        status = "zone_not_deleted";
      }
    } catch (e) {
      debugPrint("Error deleting shipping zone: $e");
      status = "zone_not_deleted";
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return status;
  }
}
