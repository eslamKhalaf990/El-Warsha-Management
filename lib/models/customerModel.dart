import 'json_read.dart';

class CustomerModel {
  final int customerId;
  final String fullName;
  final String governorate;
  final String city;
  final String secondaryPhone;
  final String phone;
  final String address;
  final String email;

  CustomerModel({
    required this.customerId,
    required this.fullName,
    required this.governorate,
    required this.secondaryPhone,
    required this.city,
    required this.phone,
    required this.address,
    this.email = '',
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
      email: readString(json['email']),
    );
  }
}

/// Body of POST /customers and PUT /customers/{id}. Blank optional fields are
/// sent as null.
class CustomerRequest {
  final String fullName;
  final String phone;
  final String governorate;
  final String? secondaryPhone;
  final String? city;
  final String? address;
  final String? email;

  const CustomerRequest({
    required this.fullName,
    required this.phone,
    required this.governorate,
    this.secondaryPhone,
    this.city,
    this.address,
    this.email,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName.trim(),
        'phone': phone.trim(),
        'governorate': governorate.trim(),
        'secondaryPhone': _orNull(secondaryPhone),
        'city': _orNull(city),
        'address': _orNull(address),
        'email': _orNull(email),
      };

  static String? _orNull(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
}
