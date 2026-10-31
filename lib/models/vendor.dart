class Vendor {
  final int vendorId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? taxNumber;
  final String? contactPerson;
  final String? notes;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Vendor({
    required this.vendorId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.taxNumber,
    this.contactPerson,
    this.notes,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      vendorId: (json['vendorId'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      taxNumber: json['taxNumber']?.toString(),
      contactPerson: json['contactPerson']?.toString(),
      notes: json['notes']?.toString(),
      // Rows from before IsActive existed come back as null: still active.
      isActive: json['isActive'] != false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}

/// Body of POST /vendors and PUT /vendors/{id}. Blank fields are sent as null.
class VendorRequest {
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? taxNumber;
  final String? contactPerson;
  final String? notes;

  const VendorRequest({
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.taxNumber,
    this.contactPerson,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        'phone': _orNull(phone),
        'email': _orNull(email),
        'address': _orNull(address),
        'taxNumber': _orNull(taxNumber),
        'contactPerson': _orNull(contactPerson),
        'notes': _orNull(notes),
      };

  static String? _orNull(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
}
