/// Order lifecycle, mirroring the backend's OrderStatus:
/// Pending → Processing → Shipped → Completed, and Cancelled from any
/// status before Completed. The backend decides which moves are allowed
/// (see `OrderModel.allowedNextStatuses`).
enum OrderStatus {
  pending('Pending'),
  processing('Processing'),
  shipped('Shipped'),
  completed('Completed'),
  cancelled('Cancelled');

  const OrderStatus(this.label);

  /// The value sent to and received from the API, e.g. "Shipped".
  final String label;

  bool get isFinal => this == completed || this == cancelled;

  /// Items, prices and payments can only change before the order ships.
  bool get isEditable => this == pending || this == processing;

  /// Accepts the label or the name in any case; returns null for anything else.
  static OrderStatus? tryParse(Object? value) {
    if (value is! String) return null;
    final v = value.trim().toLowerCase();
    if (v == 'canceled') return cancelled;
    for (final s in values) {
      if (s.label.toLowerCase() == v || s.name == v) return s;
    }
    return null;
  }

  @override
  String toString() => label;
}
