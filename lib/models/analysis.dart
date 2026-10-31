class CustomerAnalysis {
  final int customerId;
  final String fullName;
  final int orderCount;

  CustomerAnalysis({
    required this.customerId,
    required this.fullName,
    required this.orderCount,
  });

  // Create a Customer object from a JSON map
  factory CustomerAnalysis.fromJson(Map<String, dynamic> json) {
    return CustomerAnalysis(
      customerId: json['customerId'] as int,
      fullName: json['fullName'] as String,
      orderCount: json['orderCount'] as int,
    );
  }

  // Convert a Customer object back to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'fullName': fullName,
      'orderCount': orderCount,
    };
  }
}

class CustomerAnalytics {
  final String fullName;
  final int totalOrders;
  final double totalLifetimeSpend;
  final double averageOrderValue;

  CustomerAnalytics({
    required this.fullName,
    required this.totalOrders,
    required this.totalLifetimeSpend,
    required this.averageOrderValue,
  });

  // Factory constructor for converting JSON to Object
  factory CustomerAnalytics.fromJson(Map<String, dynamic> json) {
    return CustomerAnalytics(
      fullName: json['fullName'] as String,
      totalOrders: json['totalOrders'] as int,
      // Using .toDouble() ensures safety if the JSON value arrives as an int
      totalLifetimeSpend: (json['totalLifetimeSpend'] as num).toDouble(),
      averageOrderValue: (json['averageOrderValue'] as num).toDouble(),
    );
  }

  // Method for converting Object back to JSON
  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'totalOrders': totalOrders,
      'totalLifetimeSpend': totalLifetimeSpend,
      'averageOrderValue': averageOrderValue,
    };
  }
}

class CustomerRetention {
  final String fullName;
  final String phone;
  final int lifetimeOrders;
  final DateTime lastOrderDate;
  final int daysSinceLastOrder;

  CustomerRetention({
    required this.fullName,
    required this.phone,
    required this.lifetimeOrders,
    required this.lastOrderDate,
    required this.daysSinceLastOrder,
  });

  factory CustomerRetention.fromJson(Map<String, dynamic> json) {
    return CustomerRetention(
      fullName: json['fullName'] as String,
      phone: json['phone'] as String,
      lifetimeOrders: json['lifetimeOrders'] as int,
      // Parse the ISO string into a DateTime object
      lastOrderDate: DateTime.parse(json['lastOrderDate'] as String),
      daysSinceLastOrder: json['daysSinceLastOrder'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phone': phone,
      'lifetimeOrders': lifetimeOrders,
      'lastOrderDate': lastOrderDate.toIso8601String(),
      'daysSinceLastOrder': daysSinceLastOrder,
    };
  }
}

class GovernorateAnalytics {
  final String governorate;
  final int totalOrders;
  final double totalRevenue;
  final double totalDeliveryCollected;

  GovernorateAnalytics({
    required this.governorate,
    required this.totalOrders,
    required this.totalRevenue,
    required this.totalDeliveryCollected,
  });

  factory GovernorateAnalytics.fromJson(Map<String, dynamic> json) {
    return GovernorateAnalytics(
      governorate: json['governorate'] as String,
      totalOrders: json['totalOrders'] as int,
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      totalDeliveryCollected: (json['totalDeliveryCollected'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'governorate': governorate,
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'totalDeliveryCollected': totalDeliveryCollected,
    };
  }

  // Helpful getter for average delivery cost per region
  double get averageDelivery => totalOrders > 0
      ? totalDeliveryCollected / totalOrders
      : 0.0;
}

class CustomerDiscount {
  final String fullName;
  final int totalOrders;
  final double totalPaid;
  final double totalDiscountsReceived;

  CustomerDiscount({
    required this.fullName,
    required this.totalOrders,
    required this.totalPaid,
    required this.totalDiscountsReceived,
  });

  factory CustomerDiscount.fromJson(Map<String, dynamic> json) {
    return CustomerDiscount(
      fullName: json['fullName'] as String,
      totalOrders: json['totalOrders'] as int,
      // Using .toDouble() for safety with currency values
      totalPaid: (json['totalPaid'] as num).toDouble(),
      totalDiscountsReceived: (json['totalDiscountsReceived'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'totalOrders': totalOrders,
      'totalPaid': totalPaid,
      'totalDiscountsReceived': totalDiscountsReceived,
    };
  }
}

class OrderSourceAnalytics {
  final String orderSource;
  final int totalOrders;
  final double totalRevenue;
  final double averageOrderValue;

  OrderSourceAnalytics({
    required this.orderSource,
    required this.totalOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
  });

  factory OrderSourceAnalytics.fromJson(Map<String, dynamic> json) {
    return OrderSourceAnalytics(
      orderSource: json['orderSource'] as String,
      totalOrders: json['totalOrders'] as int,
      // .toDouble() is essential here due to the high-precision averages
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      averageOrderValue: (json['averageOrderValue'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderSource': orderSource,
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'averageOrderValue': averageOrderValue,
    };
  }
}

class DailySales {
  final DateTime salesDate;
  final int numberOfOrders;
  final double totalDiscountsGiven;
  final double netRevenue;

  DailySales({
    required this.salesDate,
    required this.numberOfOrders,
    required this.totalDiscountsGiven,
    required this.netRevenue,
  });

  factory DailySales.fromJson(Map<String, dynamic> json) {
    // Parsing '13 03 2026' to DateTime
    final dateParts = (json['salesDate'] as String).split(' ');
    final parsedDate = DateTime(
      int.parse(dateParts[2]), // Year
      int.parse(dateParts[1]), // Month
      int.parse(dateParts[0]), // Day
    );

    return DailySales(
      salesDate: parsedDate,
      numberOfOrders: json['numberOfOrders'] as int,
      totalDiscountsGiven: (json['totalDiscountsGiven'] as num).toDouble(),
      netRevenue: (json['netRevenue'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Formats it back to your dd mm yyyy style
      'salesDate': "${salesDate.day.toString().padLeft(2, '0')} "
          "${salesDate.month.toString().padLeft(2, '0')} "
          "${salesDate.year}",
      'numberOfOrders': numberOfOrders,
      'totalDiscountsGiven': totalDiscountsGiven,
      'netRevenue': netRevenue,
    };
  }
}