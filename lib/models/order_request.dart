/// One line of an [OrderRequest].
class OrderLineRequest {
  final int productId;
  final int quantity;

  /// Required when the product has sizes/colors.
  final int? variantId;

  /// Overrides the catalogue price (ERP only); null uses the product's price.
  final double? unitPrice;

  const OrderLineRequest({required this.productId, required this.quantity, this.variantId, this.unitPrice});

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'quantity': quantity,
        if (variantId != null) 'variantId': variantId,
        if (unitPrice != null) 'unitPrice': unitPrice,
      };
}

/// Body for creating or editing an ERP order (backend: OrderRequest).
/// Numbers are sent as numbers; the backend validates every field and
/// returns per-field messages on failure.
class OrderRequest {
  final int customerId;
  final List<OrderLineRequest> items;
  final String paymentMethod;
  final String orderSource;
  final String notes;
  final double downPayment;
  final double delivery;

  /// Extra discount on top of product discounts.
  final double discount;

  /// Account that received the down payment. Null on edit keeps the current one.
  final int? bankAccountId;

  const OrderRequest({
    required this.customerId,
    required this.items,
    required this.paymentMethod,
    required this.orderSource,
    this.notes = '',
    this.downPayment = 0,
    this.delivery = 0,
    this.discount = 0,
    this.bankAccountId,
  });

  Map<String, dynamic> toJson() => {
        'customerId': customerId,
        'items': items.map((i) => i.toJson()).toList(),
        'paymentMethod': paymentMethod,
        'orderSource': orderSource,
        'notes': notes,
        'downPayment': downPayment,
        'delivery': delivery,
        'discount': discount,
        if (bankAccountId != null) 'bankAccountId': bankAccountId,
      };
}
