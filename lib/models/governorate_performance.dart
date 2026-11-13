import 'package:warsha_app/core/l10n/app_locale.dart';
class GovernoratePerformanceModel {
  final String governorate;
  final int totalOrders;
  final double totalRevenue;
  final double totalDeliveryCollected;

  GovernoratePerformanceModel({
    required this.governorate,
    required this.totalOrders,
    required this.totalRevenue,
    required this.totalDeliveryCollected,
  });

  factory GovernoratePerformanceModel.fromJson(Map<String, dynamic> json) {
    return GovernoratePerformanceModel(
      governorate: json['governorate']?.toString().trim() ?? tr('Unknown'),
      totalOrders: json['totalOrders'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      totalDeliveryCollected: (json['totalDeliveryCollected'] ?? 0).toDouble(),
    );
  }
}