class ShippingZone {
  final int? id;
  final String cityName;
  final double shippingPrice;

  /// Inactive zones are hidden from the store and can't be ordered to.
  final bool isActive;

  ShippingZone({
    this.id,
    required this.cityName,
    required this.shippingPrice,
    this.isActive = true,
  });

  factory ShippingZone.fromJson(Map<String, dynamic> json) {
    return ShippingZone(
      id: (json['id'] as num?)?.toInt(),
      cityName: json['cityName']?.toString() ?? '',
      shippingPrice: (json['shippingFee'] as num).toDouble(),
      isActive: json['isActive'] != false,
    );
  }

  /// "80 EGP", or "82.5 EGP" when there are piastres.
  String get priceLabel =>
      '${shippingPrice == shippingPrice.roundToDouble() ? shippingPrice.toStringAsFixed(0) : shippingPrice.toStringAsFixed(2)} EGP';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShippingZone &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Body of POST /shipping and PUT /shipping/{id}.
class ShippingZoneRequest {
  final String cityName;
  final double? shippingFee;
  final bool isActive;

  const ShippingZoneRequest({required this.cityName, required this.shippingFee, this.isActive = true});

  Map<String, dynamic> toJson() => {
        'cityName': cityName.trim(),
        'shippingFee': shippingFee,
        'isActive': isActive,
      };
}

/// Matching key for Arabic governorate names (same rules as the backend), so
/// "الاسكندريه" and "الإسكندرية" find the same zone.
String governorateKey(String name) {
  var s = name
      .trim()
      .replaceAll(RegExp('[\u064B-\u065F\u0640]'), '')
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll(RegExp(r'\s+'), ' ');
  return s.startsWith('ال') ? s.substring(2) : s;
}
