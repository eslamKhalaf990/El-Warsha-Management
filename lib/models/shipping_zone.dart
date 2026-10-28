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
      id: json['id'] as int?,
      cityName: json['cityName'] as String,
      shippingPrice: (json['shippingFee'] as num).toDouble(),
      isActive: json['isActive'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cityName': cityName,
      'shippingFee': shippingPrice,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShippingZone &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
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
