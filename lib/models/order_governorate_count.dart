import 'json_read.dart';

class GovernorateCountPerOrder {
  final String governorate;
  final int count;

  GovernorateCountPerOrder({
    required this.governorate,
    required this.count,
  });

  factory GovernorateCountPerOrder.fromJson(Map<String, dynamic> json) {
    return GovernorateCountPerOrder(
      governorate: readString(json['governorate'], '-'),
      count: readInt(json['orderCount']) ?? 0,
    );
  }
}
