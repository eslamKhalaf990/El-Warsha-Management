import 'package:warsha_app/core/state/form_draft.dart';
import 'package:warsha_app/models/customer_model.dart';
import 'package:warsha_app/models/order_item_model.dart';
import 'package:warsha_app/models/order_model.dart';
import 'package:warsha_app/models/order_totals.dart';
import 'package:warsha_app/models/product_model.dart';
import 'package:warsha_app/models/product_variant.dart';
import 'package:warsha_app/view_models/order_v_m.dart';

/// The order being added or edited: customer, lines and payment, as typed.
/// [OrderVM] validates it (via [form]) and sends it.
class OrderDraft extends FormDraft {
  OrderDraft({OrderModel? order, Map<int, double> unitDiscounts = const {}})
      : editingId = order?.orderId,
        super(
          text: {
            'notes': _plain(order?.notes),
            'downPayment': _amount(order?.downPayment),
            'delivery': _amount(order?.delivery),
            'discount': _amount(order?.extraDiscount),
          },
          values: {
            'customer': order?.customer,
            'items': [
              for (final item in order?.orderItems ?? const <OrderItemModel>[])
                (item.withQuantity(item.orderedQuantity)..unitDiscount = unitDiscounts[item.productId] ?? item.unitDiscount),
            ],
            'paymentMethod': _plain(order?.paymentMethod),
            'orderSource': _plain(order?.orderSource),
          },
        );

  /// Null while adding.
  final int? editingId;

  bool get isEdit => editingId != null;

  CustomerModel? get customer => value<CustomerModel>('customer');

  List<OrderItemModel> get items => value<List<OrderItemModel>>('items') ?? const [];

  int? get bankAccountId => value<int>('bankAccountId');

  /// Picks the customer; fills the delivery price from their governorate's
  /// zone when the delivery box is still empty or was filled this way.
  void selectCustomer(CustomerModel customer, {double? deliveryPrice}) {
    final autoFilled = value<bool>('deliveryAuto') ?? false;
    set('customer', customer);
    if (deliveryPrice != null && (text('delivery').trim().isEmpty || autoFilled)) {
      setText('delivery', _amount(deliveryPrice) ?? '');
      set('deliveryAuto', true);
    }
  }

  /// Adds [quantity] pieces of [product] (in [variant] when it has sizes /
  /// colors); an existing line for the same thing grows instead.
  void addLine(ProductModel product, {ProductVariant? variant, int quantity = 1}) {
    final line = OrderItemModel(
      productId: int.parse(product.id),
      productName: product.name,
      quantity: 0,
      unitPrice: variant?.price ?? product.sellingPriceValue,
      variantId: variant?.id,
      size: variant?.size,
      color: variant?.color,
    )..unitDiscount = product.discountValue;
    final index = items.indexWhere((i) => i.sameLineAs(line));
    if (index >= 0) {
      setQuantity(index, items[index].quantityToOrder + quantity);
    } else {
      set('items', [...items, line.withQuantity(quantity)]);
    }
  }

  /// Sets line [index] to [quantity] pieces; below 1 removes the line.
  void setQuantity(int index, int quantity) {
    if (quantity < 1) return removeLine(index);
    final next = [...items];
    next[index] = next[index].withQuantity(quantity);
    set('items', next);
  }

  void removeLine(int index) => set('items', [...items]..removeAt(index));

  OrderForm get form => OrderForm(
        customer: customer,
        items: items,
        quantityOf: (item) => item.quantityToOrder,
        paymentMethod: value<String>('paymentMethod') ?? '',
        orderSource: value<String>('orderSource') ?? '',
        notes: text('notes'),
        downPayment: text('downPayment'),
        delivery: text('delivery'),
        discount: text('discount'),
      );

  OrderTotals get totals => form.totals;

  static String? _plain(String? s) => (s == null || s.trim() == '-' || s.trim().isEmpty) ? null : s.trim();

  static String? _amount(double? v) {
    if (v == null || v == 0) return null;
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  }
}
