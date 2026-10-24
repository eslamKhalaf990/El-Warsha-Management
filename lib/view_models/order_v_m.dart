import 'package:flutter/material.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/models/order_request.dart';
import 'package:warsha_app/models/order_status.dart';
import 'package:warsha_app/services/orders_service.dart';
import 'package:warsha_app/utils/navigator.dart';
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
      _errorMessage = '';
      _state = ViewState.idle;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _state = ViewState.error;
    }

    notifyListeners();
  }

  // ────────────────────────────
  // ADD ORDER
  // ────────────────────────────
  Future<bool> addOrder(OrderRequest request) async {
    _isSaving = true;
    _errorMessage = '';
    _state = ViewState.idle;
    notifyListeners();

    try {
      final created = await _orderService.create(request);
      _orders.insert(0, created);
      _filterOrders();
      _showSnackBar("Order #${created.orderId} added successfully");
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _showSnackBar(e.message, isError: true);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ────────────────────────────
  // UPDATE ORDER
  // ────────────────────────────
  Future<bool> updateOrder(int orderId, OrderRequest request) async {
    _isSaving = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _replaceOrder(await _orderService.update(orderId, request));
      _showSnackBar("Order #$orderId updated successfully");
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _showSnackBar(e.message, isError: true);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ────────────────────────────
  // UPDATE STATUS
  // ────────────────────────────
  /// Cancelling goes through the cancel endpoint, which also refunds the
  /// down payment. Completing needs the [bankAccountId] that gets paid.
  Future<bool> updateOrderStatus({
    required int orderId,
    required OrderStatus status,
    int? bankAccountId,
  }) async {
    _isSaving = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final updated = status == OrderStatus.cancelled
          ? await _orderService.cancel(orderId)
          : await _orderService.changeStatus(orderId, status, bankAccountId: bankAccountId);
      _replaceOrder(updated);
      if (status == OrderStatus.cancelled) {
        _showSnackBar("Order #$orderId cancelled successfully", isError: true);
      }
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _showSnackBar(e.message, isError: true);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ────────────────────────────
  // DELETE ORDER
  // ────────────────────────────
  Future<bool> deleteOrder(int id) async {
    _isSaving = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _orderService.delete(id);
      _orders.removeWhere((order) => order.orderId == id);
      _filteredOrders.removeWhere((order) => order.orderId == id);
      _showSnackBar("Order #$id deleted successfully", isError: true);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _showSnackBar(e.message, isError: true);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void _replaceOrder(OrderModel updated) {
    int indexIn(List<OrderModel> list) => list.indexWhere((o) => o.orderId == updated.orderId);
    final i = indexIn(_orders);
    if (i >= 0) _orders[i] = updated;
    final j = indexIn(_filteredOrders);
    if (j >= 0) _filteredOrders[j] = updated;
  }

  // Moves to the views in step 6.
  void _showSnackBar(String message, {bool isError = false}) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.grey,
        duration: const Duration(seconds: 2),
      ),
    );
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