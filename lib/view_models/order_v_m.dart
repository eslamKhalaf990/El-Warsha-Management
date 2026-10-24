import 'package:flutter/material.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/models/order_request.dart';
import 'package:warsha_app/models/order_status.dart';
import 'package:warsha_app/services/orders_service.dart';
import '../models/orderModel.dart';

enum ViewState { idle, loading, error }

class OrderVM extends ChangeNotifier {
  final OrdersService _orderService;

  TextEditingController customer = TextEditingController();
  TextEditingController status = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController governorate = TextEditingController();
  TextEditingController total = TextEditingController();
  TextEditingController source = TextEditingController();
  TextEditingController paymentMethod = TextEditingController();

  OrderVM(this._orderService);

  // State
  ViewState _state = ViewState.idle;
  bool _isSaving = false;
  String _errorMessage = '';
  ApiException? _lastError;

  // Orders
  List<OrderModel> _orders = [];
  List<OrderModel> _filteredOrders = [];

  // Sorting
  int? sortColumnIndex;
  bool sortAscending = true;

  // Filtering
  final Map<String, String> _filters = {};
  DateTime? _startDate; // ✨ ADDED
  DateTime? _endDate; // ✨ ADDED

  // Getters
  ViewState get state => _state;
  bool get isSaving => _isSaving;
  String get errorMessage => _errorMessage;

  /// The failure of the last load or save, for the screens to show.
  ApiException? get lastError => _lastError;

  /// The backend's message for [field] (e.g. `discount`, `items[0].quantity`)
  /// when the last save failed validation.
  String? fieldError(String field) =>
      (_lastError?.isValidation ?? false) ? _lastError!.messageFor(field) : null;

  /// Forgets the last failure, e.g. when a form is opened again.
  void clearError() {
    if (_lastError == null && _errorMessage.isEmpty) return;
    _lastError = null;
    _errorMessage = '';
    notifyListeners();
  }

  // ✨ MODIFIED getter to check all filter types
  List<OrderModel> get orders =>
      _filteredOrders.isEmpty &&
          _filters.isEmpty &&
          _startDate == null &&
          _endDate == null
          ? _orders
          : _filteredOrders;

  // ✨ ADDED getters for date range
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  // ────────────────────────────
  // FETCH ORDERS
  // ────────────────────────────
  Future<void> fetchOrders() async {
    _state = ViewState.loading;
    notifyListeners();

    try {
      final now = DateTime.now();
      _orders = await _orderService.list(
        from: now.subtract(const Duration(days: 45)),
        to: now,
      );
      _filteredOrders = List.from(_orders);
      _setError(null);
      _state = ViewState.idle;
    } on ApiException catch (e) {
      _setError(e);
      _state = ViewState.error;
    }

    notifyListeners();
  }

  // ────────────────────────────
  // ADD / UPDATE / STATUS / DELETE
  // Each returns true on success; on failure [lastError] says why.
  // ────────────────────────────

  /// Returns the created order, or null on failure.
  Future<OrderModel?> addOrder(OrderRequest request) => _save(() async {
        final created = await _orderService.create(request);
        _orders.insert(0, created);
        _filterOrders();
        return created;
      });

  Future<bool> updateOrder(int orderId, OrderRequest request) async =>
      await _save(() async => _replaceOrder(await _orderService.update(orderId, request))) != null;

  /// Cancelling goes through the cancel endpoint, which also returns the stock
  /// and refunds the down payment. Completing needs the [bankAccountId] that
  /// receives the amount due.
  Future<bool> updateOrderStatus({
    required int orderId,
    required OrderStatus status,
    int? bankAccountId,
  }) async =>
      await _save(() async => _replaceOrder(status == OrderStatus.cancelled
          ? await _orderService.cancel(orderId)
          : await _orderService.changeStatus(orderId, status, bankAccountId: bankAccountId))) !=
      null;

  Future<bool> deleteOrder(int id) async =>
      await _save(() async {
        await _orderService.delete(id);
        _orders.removeWhere((order) => order.orderId == id);
        _filteredOrders.removeWhere((order) => order.orderId == id);
        return true;
      }) !=
      null;

  Future<T?> _save<T extends Object>(Future<T> Function() action) async {
    _isSaving = true;
    _setError(null);
    notifyListeners();

    try {
      return await action();
    } on ApiException catch (e) {
      _setError(e);
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void _setError(ApiException? e) {
    _lastError = e;
    _errorMessage = e?.message ?? '';
  }

  OrderModel _replaceOrder(OrderModel updated) {
    int indexIn(List<OrderModel> list) => list.indexWhere((o) => o.orderId == updated.orderId);
    final i = indexIn(_orders);
    if (i >= 0) _orders[i] = updated;
    final j = indexIn(_filteredOrders);
    if (j >= 0) _filteredOrders[j] = updated;
    return updated;
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
    notifyListeners();
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
    notifyListeners();
  }

  // applies both text and date filters
  void _filterOrders() {
    _filteredOrders = _orders.where((order) {

      // --- 1. Text Filters (Existing Logic) ---
      bool passesTextFilter = true;
      if (_filters.isNotEmpty) {
        for (var entry in _filters.entries) {
          final key = entry.key;
          final query = entry.value;

          String target = '';
          switch (key) {
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

    notifyListeners();
  }
}