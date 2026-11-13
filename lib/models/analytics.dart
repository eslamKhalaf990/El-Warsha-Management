/// Responses of the backend's `/analytics` endpoints. Money is in EGP; rates
/// and shares are fractions (0.25 = 25%).
///
/// Terms: net sales = items − discounts; order value = net sales + delivery;
/// gross profit = net sales − cost at today's buying prices. Cancelled orders
/// only count towards cancellation figures.
library;

import 'package:warsha_app/models/json_read.dart';
import 'package:warsha_app/core/l10n/app_locale.dart';

int _int(Object? v) => readInt(v) ?? 0;

List<T> _list<T>(Object? v, T Function(Map<String, dynamic>) parse) => readList(v).map(parse).toList();

/// The range shown and the one just before it (none for all time).
class AnalyticsPeriod {
  const AnalyticsPeriod({required this.from, required this.to, this.previousFrom, this.previousTo, required this.days});

  final DateTime from;
  final DateTime to;
  final DateTime? previousFrom;
  final DateTime? previousTo;
  final int days;

  factory AnalyticsPeriod.fromJson(Map<String, dynamic>? j) {
    final now = DateTime.now();
    return AnalyticsPeriod(
      from: readDate(j?['from']) ?? now,
      to: readDate(j?['to']) ?? now,
      previousFrom: readDate(j?['previousFrom']),
      previousTo: readDate(j?['previousTo']),
      days: _int(j?['days']),
    );
  }
}

class Kpis {
  const Kpis({
    this.orders = 0,
    this.cancelledOrders = 0,
    this.cancellationRate = 0,
    this.units = 0,
    this.sales = 0,
    this.discounts = 0,
    this.netSales = 0,
    this.deliveryFees = 0,
    this.orderValue = 0,
    this.cost = 0,
    this.grossProfit = 0,
    this.grossMargin = 0,
    this.averageOrderValue = 0,
    this.itemsPerOrder = 0,
    this.customers = 0,
    this.newCustomers = 0,
    this.returningCustomers = 0,
    this.collected = 0,
    this.outstanding = 0,
  });

  final int orders;
  final int cancelledOrders;
  final double cancellationRate;
  final int units;
  final double sales;
  final double discounts;
  final double netSales;
  final double deliveryFees;
  final double orderValue;
  final double cost;
  final double grossProfit;
  final double grossMargin;
  final double averageOrderValue;
  final double itemsPerOrder;
  final int customers;
  final int newCustomers;
  final int returningCustomers;
  final double collected;
  final double outstanding;

  factory Kpis.fromJson(Map<String, dynamic> j) => Kpis(
        orders: _int(j['orders']),
        cancelledOrders: _int(j['cancelledOrders']),
        cancellationRate: readDouble(j['cancellationRate']),
        units: _int(j['units']),
        sales: readDouble(j['sales']),
        discounts: readDouble(j['discounts']),
        netSales: readDouble(j['netSales']),
        deliveryFees: readDouble(j['deliveryFees']),
        orderValue: readDouble(j['orderValue']),
        cost: readDouble(j['cost']),
        grossProfit: readDouble(j['grossProfit']),
        grossMargin: readDouble(j['grossMargin']),
        averageOrderValue: readDouble(j['averageOrderValue']),
        itemsPerOrder: readDouble(j['itemsPerOrder']),
        customers: _int(j['customers']),
        newCustomers: _int(j['newCustomers']),
        returningCustomers: _int(j['returningCustomers']),
        collected: readDouble(j['collected']),
        outstanding: readDouble(j['outstanding']),
      );
}

class AnalyticsOverview {
  const AnalyticsOverview({required this.period, required this.current, this.previous});

  final AnalyticsPeriod period;
  final Kpis current;
  final Kpis? previous;

  factory AnalyticsOverview.fromJson(Map<String, dynamic> j) {
    final previous = readMap(j['previous']);
    return AnalyticsOverview(
      period: AnalyticsPeriod.fromJson(readMap(j['period'])),
      current: Kpis.fromJson(readMap(j['current']) ?? const {}),
      previous: previous == null ? null : Kpis.fromJson(previous),
    );
  }
}

class TrendPoint {
  const TrendPoint({required this.start, this.orders = 0, this.netSales = 0, this.grossProfit = 0, this.discounts = 0});

  final DateTime start;
  final int orders;
  final double netSales;
  final double grossProfit;
  final double discounts;

  factory TrendPoint.fromJson(Map<String, dynamic> j) => TrendPoint(
        start: readDate(j['start']) ?? DateTime.now(),
        orders: _int(j['orders']),
        netSales: readDouble(j['netSales']),
        grossProfit: readDouble(j['grossProfit']),
        discounts: readDouble(j['discounts']),
      );
}

/// Sales over time, one point per day, week (from Saturday) or month.
class SalesTrend {
  const SalesTrend({required this.granularity, required this.points});

  final String granularity;
  final List<TrendPoint> points;

  factory SalesTrend.fromJson(Map<String, dynamic> j) =>
      SalesTrend(granularity: readString(j['granularity'], 'day'), points: _list(j['points'], TrendPoint.fromJson));
}

class CategorySales {
  const CategorySales({required this.category, this.units = 0, this.netSales = 0, this.grossProfit = 0, this.grossMargin = 0, this.share = 0});

  final String category;
  final int units;
  final double netSales;
  final double grossProfit;
  final double grossMargin;
  final double share;

  factory CategorySales.fromJson(Map<String, dynamic> j) => CategorySales(
        category: readString(j['category'], tr('Unknown')),
        units: _int(j['units']),
        netSales: readDouble(j['netSales']),
        grossProfit: readDouble(j['grossProfit']),
        grossMargin: readDouble(j['grossMargin']),
        share: readDouble(j['share']),
      );
}

class ProductSales {
  const ProductSales({
    this.productId,
    required this.name,
    this.category,
    this.units = 0,
    this.netSales = 0,
    this.grossProfit = 0,
    this.grossMargin = 0,
    this.stock,
    this.daysOfCover,
  });

  final int? productId;
  final String name;
  final String? category;
  final int units;
  final double netSales;
  final double grossProfit;
  final double grossMargin;
  final int? stock;

  /// How many days the stock lasts at this period's sales rate.
  final double? daysOfCover;

  factory ProductSales.fromJson(Map<String, dynamic> j) => ProductSales(
        productId: readInt(j['productId']),
        name: readString(j['name'], '—'),
        category: readStringOrNull(j['category']),
        units: _int(j['units']),
        netSales: readDouble(j['netSales']),
        grossProfit: readDouble(j['grossProfit']),
        grossMargin: readDouble(j['grossMargin']),
        stock: readInt(j['stock']),
        daysOfCover: readDoubleOrNull(j['daysOfCover']),
      );
}

/// In stock but not sold in the period.
class SlowMover {
  const SlowMover({this.productId, required this.name, this.category, this.stock = 0, this.stockValue = 0, this.lastSold});

  final int? productId;
  final String name;
  final String? category;
  final int stock;
  final double stockValue;
  final DateTime? lastSold;

  factory SlowMover.fromJson(Map<String, dynamic> j) => SlowMover(
        productId: readInt(j['productId']),
        name: readString(j['name'], '—'),
        category: readStringOrNull(j['category']),
        stock: _int(j['stock']),
        stockValue: readDouble(j['stockValue']),
        lastSold: readDate(j['lastSold']),
      );
}

class ProductInsights {
  const ProductInsights({this.categories = const [], this.topProducts = const [], this.runningLow = const [], this.slowMovers = const []});

  final List<CategorySales> categories;
  final List<ProductSales> topProducts;
  final List<ProductSales> runningLow;
  final List<SlowMover> slowMovers;

  factory ProductInsights.fromJson(Map<String, dynamic> j) => ProductInsights(
        categories: _list(j['categories'], CategorySales.fromJson),
        topProducts: _list(j['topProducts'], ProductSales.fromJson),
        runningLow: _list(j['runningLow'], ProductSales.fromJson),
        slowMovers: _list(j['slowMovers'], SlowMover.fromJson),
      );
}

class ChannelSales {
  const ChannelSales({
    required this.channel,
    this.orders = 0,
    this.cancelled = 0,
    this.cancellationRate = 0,
    this.netSales = 0,
    this.averageOrderValue = 0,
    this.share = 0,
  });

  final String channel;
  final int orders;
  final int cancelled;
  final double cancellationRate;
  final double netSales;
  final double averageOrderValue;
  final double share;

  factory ChannelSales.fromJson(Map<String, dynamic> j) => ChannelSales(
        channel: readString(j['channel'], tr('Unknown')),
        orders: _int(j['orders']),
        cancelled: _int(j['cancelled']),
        cancellationRate: readDouble(j['cancellationRate']),
        netSales: readDouble(j['netSales']),
        averageOrderValue: readDouble(j['averageOrderValue']),
        share: readDouble(j['share']),
      );
}

class RegionSales {
  const RegionSales({
    required this.governorate,
    this.orders = 0,
    this.customers = 0,
    this.netSales = 0,
    this.deliveryFees = 0,
    this.averageOrderValue = 0,
    this.share = 0,
  });

  final String governorate;
  final int orders;
  final int customers;
  final double netSales;
  final double deliveryFees;
  final double averageOrderValue;
  final double share;

  factory RegionSales.fromJson(Map<String, dynamic> j) => RegionSales(
        governorate: readString(j['governorate'], tr('Unknown')),
        orders: _int(j['orders']),
        customers: _int(j['customers']),
        netSales: readDouble(j['netSales']),
        deliveryFees: readDouble(j['deliveryFees']),
        averageOrderValue: readDouble(j['averageOrderValue']),
        share: readDouble(j['share']),
      );
}

class TopCustomer {
  const TopCustomer({this.customerId, required this.name, this.phone, this.governorate, this.orders = 0, this.spend = 0, this.lastOrder});

  final int? customerId;
  final String name;
  final String? phone;
  final String? governorate;
  final int orders;
  final double spend;
  final DateTime? lastOrder;

  factory TopCustomer.fromJson(Map<String, dynamic> j) => TopCustomer(
        customerId: readInt(j['customerId']),
        name: readString(j['name'], '—').trim(),
        phone: readStringOrNull(j['phone']),
        governorate: readStringOrNull(j['governorate']),
        orders: _int(j['orders']),
        spend: readDouble(j['spend']),
        lastOrder: readDate(j['lastOrder']),
      );
}

class CustomerInsights {
  const CustomerInsights({
    this.customers = 0,
    this.newCustomers = 0,
    this.returningCustomers = 0,
    this.repeatRate = 0,
    this.averageSpend = 0,
    this.topCustomers = const [],
  });

  final int customers;
  final int newCustomers;
  final int returningCustomers;

  /// Share of the period's customers who have ordered more than once.
  final double repeatRate;
  final double averageSpend;
  final List<TopCustomer> topCustomers;

  factory CustomerInsights.fromJson(Map<String, dynamic> j) => CustomerInsights(
        customers: _int(j['customers']),
        newCustomers: _int(j['newCustomers']),
        returningCustomers: _int(j['returningCustomers']),
        repeatRate: readDouble(j['repeatRate']),
        averageSpend: readDouble(j['averageSpend']),
        topCustomers: _list(j['topCustomers'], TopCustomer.fromJson),
      );
}

class MethodShare {
  const MethodShare({required this.method, this.orders = 0, this.amount = 0, this.share = 0});

  final String method;
  final int orders;
  final double amount;
  final double share;

  factory MethodShare.fromJson(Map<String, dynamic> j) => MethodShare(
        method: readString(j['method'], tr('Not recorded')),
        orders: _int(j['orders']),
        amount: readDouble(j['amount']),
        share: readDouble(j['share']),
      );
}

class StatusTotal {
  const StatusTotal({required this.status, this.orders = 0, this.orderValue = 0, this.outstanding = 0});

  final String status;
  final int orders;
  final double orderValue;
  final double outstanding;

  factory StatusTotal.fromJson(Map<String, dynamic> j) => StatusTotal(
        status: readString(j['status'], tr('Unknown')),
        orders: _int(j['orders']),
        orderValue: readDouble(j['orderValue']),
        outstanding: readDouble(j['outstanding']),
      );
}

class WeekdaySales {
  const WeekdaySales({required this.weekday, this.orders = 0, this.netSales = 0});

  final String weekday;
  final int orders;
  final double netSales;

  factory WeekdaySales.fromJson(Map<String, dynamic> j) =>
      WeekdaySales(weekday: readString(j['weekday']), orders: _int(j['orders']), netSales: readDouble(j['netSales']));
}

class CashInsights {
  const CashInsights({
    this.collected = 0,
    this.outstanding = 0,
    this.paymentMethods = const [],
    this.statuses = const [],
    this.weekdays = const [],
  });

  final double collected;
  final double outstanding;

  /// How down payments were made.
  final List<MethodShare> paymentMethods;
  final List<StatusTotal> statuses;

  /// Saturday first.
  final List<WeekdaySales> weekdays;

  factory CashInsights.fromJson(Map<String, dynamic> j) => CashInsights(
        collected: readDouble(j['collected']),
        outstanding: readDouble(j['outstanding']),
        paymentMethods: _list(j['paymentMethods'], MethodShare.fromJson),
        statuses: _list(j['statuses'], StatusTotal.fromJson),
        weekdays: _list(j['weekdays'], WeekdaySales.fromJson),
      );
}
