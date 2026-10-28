import 'package:flutter/material.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/core/state/async_view_model.dart';
import 'package:warsha_app/core/validation/validators.dart';
import 'package:warsha_app/models/customerModel.dart';
import 'package:warsha_app/models/orderItemModel.dart';
import 'package:warsha_app/models/order_request.dart';
import 'package:warsha_app/models/order_status.dart';
import 'package:warsha_app/models/order_totals.dart';
import 'package:warsha_app/services/orders_service.dart';
import '../models/orderModel.dart';

enum ViewState { idle, loading, error }

/// What the add/edit order screens hold, as typed. [OrderVM] validates it and
/// turns it into an [OrderRequest].
class OrderForm {
  final CustomerModel? customer;
  final List<OrderItemModel> items;

  /// The quantity field the screen edits (`quantityToOrder` when adding,
  /// `orderedQuantity` when editing).
  final int Function(OrderItemModel item) quantityOf;
  final String paymentMethod;
  final String orderSource;
  final String notes;
  final String downPayment;
  final String delivery;
  final String discount;

  const OrderForm({
    required this.customer,
    required this.items,
    required this.quantityOf,
    required this.paymentMethod,
    required this.orderSource,
    this.notes = '',
    this.downPayment = '',
    this.delivery = '',
    this.discount = '',
  });

  static double amount(String text) => double.tryParse(text.trim().replaceAll(',', '.')) ?? 0;

  OrderTotals get totals => OrderTotals.compute(
        items: items,
        quantityOf: quantityOf,
        extraDiscount: amount(discount),
        delivery: amount(delivery),
        downPayment: amount(downPayment),
      );

  /// A down payment has to land in a bank account the user picks.
  bool get needsBankAccount => amount(downPayment) > 0;

  OrderRequest toRequest({int? bankAccountId}) => OrderRequest(
        customerId: customer!.customerId,
        items: [
          for (final item in items)
            OrderLineRequest(
              productId: item.productId,
              variantId: item.variantId,
              quantity: quantityOf(item),
              unitPrice: item.unitPrice,
            ),
        ],
        paymentMethod: _orEmpty(paymentMethod),
        orderSource: _orEmpty(orderSource),
        notes: _orEmpty(notes),
        downPayment: amount(downPayment),
        delivery: amount(delivery),
        discount: amount(discount),
        bankAccountId: bankAccountId,
      );

  /// Old orders show "-" for empty fields; send those as empty.
  static String _orEmpty(String s) => s.trim() == '-' ? '' : s.trim();
}

/// Orders screen (list, filters, status changes, delete) and saving from the
/// add/edit order screens.
class OrderVM extends ChangeNotifier with AsyncViewModel {
  final OrdersService _orderService;

  OrderVM(this._orderService);

  // Orders
  List<OrderModel> _orders = [];
  List<OrderModel> _filteredOrders = [];

  // Sorting
  int? sortColumnIndex;
  bool sortAscending = true;

  // Filtering
  final Map<String, String> _filters = {};
  DateTime? _startDate;
  DateTime? _endDate;

  ViewState get state => isLoading
      ? ViewState.loading
      : loadFailed
          ? ViewState.error
          : ViewState.idle;

  /// The failure of the last load or save, for the screens to show.
  ApiException? get lastError => error;

  /// Only input mistakes go under a field; stock and status problems are
  /// shown as a message.
  @override
  String? fieldError(String field) => (error?.isValidation ?? false) ? error!.messageFor(field) : null;

  List<OrderModel> get orders =>
      _filteredOrders.isEmpty && _filters.isEmpty && _startDate == null && _endDate == null
          ? _orders
          : _filteredOrders;

  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  /// The text typed in the filter for [key], to restore the filter fields.
  String filterValue(String key) => _filters[key] ?? '';

  // ────────────────────────────
  // FETCH ORDERS
  // ────────────────────────────
  Future<bool> fetchOrders() => load(() async {
        final now = DateTime.now();
        _orders = await _orderService.list(from: now.subtract(const Duration(days: 45)), to: now);
        _filterOrders(notifyNow: false);
      });

  // ────────────────────────────
  // VALIDATION
  // Keys match the backend's field names, so both show the same way.
  // ────────────────────────────
  Map<String, String> validateOrder(OrderForm form) {
    final errors = Validators.collect({
      'customerId': () => form.customer == null ? 'Choose a customer.' : null,
      'items': () => form.items.isEmpty ? 'Add at least one product.' : null,
      'paymentMethod': () => OrderForm._orEmpty(form.paymentMethod).isEmpty ? 'Choose the payment method.' : null,
      'orderSource': () => OrderForm._orEmpty(form.orderSource).isEmpty ? 'Choose where the order came from.' : null,
      'downPayment': () => Validators.nonNegativeNumber(form.downPayment, 'Down payment'),
      'delivery': () => Validators.nonNegativeNumber(form.delivery, 'Delivery'),
      'discount': () => Validators.nonNegativeNumber(form.discount, 'Discount'),
    });
    for (var i = 0; i < form.items.length; i++) {
      if (form.quantityOf(form.items[i]) < 1) errors['items[$i].quantity'] = 'Quantity must be at least 1.';
    }
    if (form.items.isNotEmpty && !errors.keys.any((k) => const ['downPayment', 'delivery', 'discount'].contains(k))) {
      final totals = form.totals;
      if (totals.grandTotal < 0) {
        errors['discount'] = "Discount can't be more than the order total.";
      } else if (totals.downPayment > totals.grandTotal) {
        errors['downPayment'] = "Down payment can't be more than the order total.";
      }
    }
    return errors;
  }

  /// Checks [form] before asking for a bank account; true when it can be sent.
  bool checkOrder(OrderForm form) {
    final errors = validateOrder(form);
    if (errors.isEmpty) {
      clearError();
      return true;
    }
    return fail(ApiException.validation(errors));
  }

  // ────────────────────────────
  // ADD / UPDATE / STATUS / DELETE
  // Each returns true (or the order) on success; on failure [lastError] says why.
  // ────────────────────────────

  /// Validates and creates the order. Returns it, or null on failure.
  Future<OrderModel?> placeOrder(OrderForm form, {int? bankAccountId}) async {
    if (!checkOrder(form)) return null;
    return addOrder(form.toRequest(bankAccountId: bankAccountId));
  }

  /// Validates and saves the edited order.
  Future<bool> saveOrder(int orderId, OrderForm form) async {
    if (!checkOrder(form)) return false;
    return updateOrder(orderId, form.toRequest());
  }

  /// Returns the created order, or null on failure.
  Future<OrderModel?> addOrder(OrderRequest request) async {
    OrderModel? created;
    await run(() async {
      created = await _orderService.create(request);
      _orders.insert(0, created!);
      _filterOrders(notifyNow: false);
    });
    return created;
  }

  Future<bool> updateOrder(int orderId, OrderRequest request) =>
      run(() async => _replaceOrder(await _orderService.update(orderId, request)));

  /// Cancelling goes through the cancel endpoint, which also returns the stock
  /// and refunds the down payment. Completing needs the [bankAccountId] that
  /// receives the amount due.
  Future<bool> updateOrderStatus({
    required int orderId,
    required OrderStatus status,
    int? bankAccountId,
  }) =>
      run(() async => _replaceOrder(status == OrderStatus.cancelled
          ? await _orderService.cancel(orderId)
          : await _orderService.changeStatus(orderId, status, bankAccountId: bankAccountId)));

  Future<bool> deleteOrder(int id) => run(() async {
        await _orderService.delete(id);
        _orders.removeWhere((order) => order.orderId == id);
        _filteredOrders.removeWhere((order) => order.orderId == id);
      });

  void _replaceOrder(OrderModel updated) {
    int indexIn(List<OrderModel> list) => list.indexWhere((o) => o.orderId == updated.orderId);
    final i = indexIn(_orders);
    if (i >= 0) _orders[i] = updated;
    final j = indexIn(_filteredOrders);
    if (j >= 0) _filteredOrders[j] = updated;
  }

  // ────────────────────────────
  // SORTING
  // ────────────────────────────
  void sort<T>(
      Comparable<T> Function(OrderModel order) getField,
      int columnIndex,
      bool ascending,
      ) {
    _filteredOrders.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      return ascending
          ? Comparable.compare(aValue, bValue)
          : Comparable.compare(bValue, aValue);
    });

    sortColumnIndex = columnIndex;
    sortAscending = ascending;
    notify();
  }

  // ────────────────────────────
  // FILTERING
  // ────────────────────────────

  /// ADDED: Call this from your UI to set the date range
  void setDateRange(DateTimeRange? range) {
    if (range != null) {
      _startDate = range.start;
      _endDate = range.end;
    } else {
      _startDate = null;
      _endDate = null;
    }
    _filterOrders(); // Re-apply all filters
  }

  void applyFilter(String key, String value) {
    if (value.trim().isEmpty) {
      _filters.remove(key);
    } else {
      _filters[key] = value.toLowerCase();
    }
    _filterOrders();
  }

  /// ✨ MODIFIED: Now clears date filters as well
  void clearAllFilters() {
    _filters.clear();
    _startDate = null;
    _endDate = null;
    _filteredOrders = List.from(_orders);
    notify();
  }

  // applies both text and date filters
  void _filterOrders({bool notifyNow = true}) {
    _filteredOrders = _orders.where((order) {

      // --- 1. Text Filters (Existing Logic) ---
      bool passesTextFilter = true;
      if (_filters.isNotEmpty) {
        for (var entry in _filters.entries) {
          final key = entry.key;
          final query = entry.value;

          String target = '';
          switch (key) {
            case 'search':
              // Order number, customer name or phone
              target = '#${order.orderId} ${order.customer?.fullName ?? ''} ${order.customer?.phone ?? ''}'.toLowerCase();
              break;
            case 'status':
              target = order.status?.label.toLowerCase() ?? '';
              break;
            case 'customer':
              target = order.customer?.fullName.toLowerCase() ?? '';
              break;
            case 'phone':
              target = order.customer?.phone.toLowerCase() ?? '';
              break;
            case 'paymentMethod':
              target = order.paymentMethod?.toLowerCase() ?? '';
              break;
            case 'governorate':
              target = order.customer?.governorate.toLowerCase() ?? '';
              break;
            case 'source':
              target = order.orderSource?.toLowerCase() ?? '';
              break;
            case 'total':
              target = (order.totalPrice ?? 0).toString();
              break;
          }

          if (!target.contains(query)) {
            passesTextFilter = false;
            break; // Stop checking filters if one fails
          }
        }
      }

      if (!passesTextFilter) return false; // Failed text filter

      // --- 2. Date Filters (New Logic) ---
      bool passesDateFilter = true;
      final orderDate = order.orderDate; // Assuming OrderModel has DateTime? orderDate

      if (orderDate != null) {
        // Check Start Date
        if (_startDate != null) {
          // Normalize start date to 00:00:00 to be inclusive
          final normalizedStartDate = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
          if (orderDate.isBefore(normalizedStartDate)) {
            passesDateFilter = false;
          }
        }

        // Check End Date (if start date check passed)
        if (passesDateFilter && _endDate != null) {
          // Normalize end date to be the *start* of the *next* day
          // This makes the check inclusive for the entire selected end day
          final normalizedEndDate = DateTime(_endDate!.year, _endDate!.month, _endDate!.day + 1);
          if (!orderDate.isBefore(normalizedEndDate)) {
            passesDateFilter = false;
          }
        }
      } else if (_startDate != null || _endDate != null) {
        // If a date filter is set, but the order has no date, exclude it.
        passesDateFilter = false;
      }

      if (!passesDateFilter) return false; // Failed date filter

      // If we get here, it passed both text and date filters
      return true;

    }).toList();

    if (notifyNow) notify();
  }
}