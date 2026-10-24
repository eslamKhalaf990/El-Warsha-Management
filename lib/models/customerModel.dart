import 'json_read.dart';

class CustomerModel {
  final int customerId;
  final String fullName;
  final String governorate;
  final String city;
  final String secondaryPhone;
  final String phone;
  final String address;

  CustomerModel({
    required this.customerId,
    required this.fullName,
    required this.governorate,
    required this.secondaryPhone,
    required this.city,
    required this.phone,
    required this.address,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      customerId: readInt(json['customerId'] ?? json['id']) ?? 0,
      fullName: readString(json['fullName']),
      governorate: readString(json['governorate']),
      phone: readString(json['phone']),
      address: readString(json['address']),
      secondaryPhone: readString(json['secondaryPhone']),
      city: readString(json['city']),
    );
  }
}
