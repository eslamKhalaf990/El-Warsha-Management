import 'json_read.dart';

enum DiscountKind {
  percentage('PERCENTAGE', '% off'),
  fixed('FIXED', 'EGP off');

  const DiscountKind(this.api, this.label);
  final String api;
  final String label;

  static DiscountKind parse(Object? v) => '$v'.toUpperCase() == 'FIXED' ? fixed : percentage;
}

/// Where a promo code stands today.
enum VoucherState { active, scheduled, expired, usedUp, off }

/// A promo code customers type at checkout (backend: VoucherDto).
class Voucher {
  const Voucher({
    required this.id,
    required this.code,
    required this.kind,
    required this.value,
    required this.startDate,
    this.minOrder = 0,
    this.maxDiscount,
    this.endDate,
    this.active = true,
    this.usageLimit,
    this.usageCount = 0,
  });

  final int id;
  final String code;
  final DiscountKind kind;
  final double value;
  final double minOrder;

  /// Cap for percentage codes; null = no cap.
  final double? maxDiscount;
  final DateTime startDate;
  final DateTime? endDate;
  final bool active;

  /// Null = unlimited.
  final int? usageLimit;
  final int usageCount;

  VoucherState stateOn(DateTime day) {
    final today = DateTime(day.year, day.month, day.day);
    if (!active) return VoucherState.off;
    if (usageLimit != null && usageCount >= usageLimit!) return VoucherState.usedUp;
    if (endDate != null && today.isAfter(endDate!)) return VoucherState.expired;
    if (today.isBefore(startDate)) return VoucherState.scheduled;
    return VoucherState.active;
  }

  factory Voucher.fromJson(Map<String, dynamic> json) => Voucher(
        id: readInt(json['id']) ?? 0,
        code: readString(json['code']),
        kind: DiscountKind.parse(json['type']),
        value: readDouble(json['discountValue']),
        minOrder: readDouble(json['minOrderAmount']),
        maxDiscount: readDoubleOrNull(json['maxDiscountAmount']),
        startDate: readDate(json['startDate']) ?? DateTime(2000),
        endDate: readDate(json['endDate']),
        active: json['active'] != false,
        usageLimit: readInt(json['maxUsageLimit']),
        usageCount: readInt(json['usageCount']) ?? 0,
      );
}

/// Body of POST /vouchers and PUT /vouchers/{id}.
class VoucherRequest {
  const VoucherRequest({
    required this.code,
    required this.kind,
    required this.value,
    required this.startDate,
    this.minOrder,
    this.maxDiscount,
    this.endDate,
    this.active = true,
    this.usageLimit,
  });

  final String code;
  final DiscountKind kind;
  final double? value;
  final double? minOrder;
  final double? maxDiscount;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool active;
  final int? usageLimit;

  static String? _day(DateTime? d) => d == null
      ? null
      : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'code': code.trim().toUpperCase(),
        'type': kind.api,
        'discountValue': value,
        'minOrderAmount': minOrder ?? 0,
        'maxDiscountAmount': kind == DiscountKind.percentage ? maxDiscount : null,
        'startDate': _day(startDate),
        'endDate': _day(endDate),
        'active': active,
        'maxUsageLimit': usageLimit,
      };
}
