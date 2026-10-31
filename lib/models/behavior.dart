/// Responses of the backend's `/analytics/behavior` endpoints: what store
/// visitors did, from the events the store sends. Rates are fractions
/// (0.25 = 25%); money is in EGP.
library;

import 'package:warsha_app/models/json_read.dart';

int _int(Object? v) => readInt(v) ?? 0;

List<T> _list<T>(Object? v, T Function(Map<String, dynamic>) parse) => readList(v).map(parse).toList();

class BehaviorRange {
  const BehaviorRange({required this.from, required this.to, required this.days});

  final DateTime from;
  final DateTime to;
  final int days;

  factory BehaviorRange.fromJson(Map<String, dynamic>? j) {
    final now = DateTime.now();
    return BehaviorRange(from: readDate(j?['from']) ?? now, to: readDate(j?['to']) ?? now, days: _int(j?['days']));
  }
}

/// Sessions that reached each step, each counted on its own.
class BehaviorFunnel {
  const BehaviorFunnel({
    this.sessions = 0,
    this.viewedProduct = 0,
    this.addedToCart = 0,
    this.startedCheckout = 0,
    this.ordered = 0,
    this.viewToCartRate = 0,
    this.cartToCheckoutRate = 0,
    this.checkoutToOrderRate = 0,
    this.conversionRate = 0,
  });

  final int sessions;
  final int viewedProduct;
  final int addedToCart;
  final int startedCheckout;
  final int ordered;
  final double viewToCartRate;
  final double cartToCheckoutRate;
  final double checkoutToOrderRate;

  /// Share of all sessions that ended in an order.
  final double conversionRate;

  factory BehaviorFunnel.fromJson(Map<String, dynamic>? j) => BehaviorFunnel(
        sessions: _int(j?['sessions']),
        viewedProduct: _int(j?['viewedProduct']),
        addedToCart: _int(j?['addedToCart']),
        startedCheckout: _int(j?['startedCheckout']),
        ordered: _int(j?['ordered']),
        viewToCartRate: readDouble(j?['viewToCartRate']),
        cartToCheckoutRate: readDouble(j?['cartToCheckoutRate']),
        checkoutToOrderRate: readDouble(j?['checkoutToOrderRate']),
        conversionRate: readDouble(j?['conversionRate']),
      );
}

class DeviceSessions {
  const DeviceSessions({required this.device, required this.sessions, required this.share});

  /// MOBILE, TABLET, DESKTOP or UNKNOWN.
  final String device;
  final int sessions;
  final double share;

  String get label => switch (device) {
        'MOBILE' => 'Mobile',
        'TABLET' => 'Tablet',
        'DESKTOP' => 'Desktop',
        _ => 'Unknown',
      };

  factory DeviceSessions.fromJson(Map<String, dynamic> j) =>
      DeviceSessions(device: readString(j['device'], 'UNKNOWN'), sessions: _int(j['sessions']), share: readDouble(j['share']));
}

class BehaviorDay {
  const BehaviorDay({
    required this.date,
    this.visitors = 0,
    this.sessions = 0,
    this.productViews = 0,
    this.cartAdds = 0,
    this.orders = 0,
  });

  final DateTime date;
  final int visitors;
  final int sessions;
  final int productViews;
  final int cartAdds;
  final int orders;

  factory BehaviorDay.fromJson(Map<String, dynamic> j) => BehaviorDay(
        date: readDate(j['date']) ?? DateTime.now(),
        visitors: _int(j['visitors']),
        sessions: _int(j['sessions']),
        productViews: _int(j['productViews']),
        cartAdds: _int(j['cartAdds']),
        orders: _int(j['orders']),
      );
}

class BehaviorOverview {
  const BehaviorOverview({
    required this.range,
    this.visitors = 0,
    this.newVisitors = 0,
    this.sessions = 0,
    this.pageViews = 0,
    this.productViews = 0,
    this.cartAdds = 0,
    this.cartRemoves = 0,
    this.checkoutsStarted = 0,
    this.orders = 0,
    this.orderValue = 0,
    this.funnel = const BehaviorFunnel(),
    this.devices = const [],
    this.days = const [],
  });

  final BehaviorRange range;
  final int visitors;
  final int newVisitors;
  final int sessions;
  final int pageViews;
  final int productViews;
  final int cartAdds;
  final int cartRemoves;
  final int checkoutsStarted;
  final int orders;
  final double orderValue;
  final BehaviorFunnel funnel;
  final List<DeviceSessions> devices;
  final List<BehaviorDay> days;

  int get returningVisitors => (visitors - newVisitors).clamp(0, visitors);

  factory BehaviorOverview.fromJson(Map<String, dynamic> j) => BehaviorOverview(
        range: BehaviorRange.fromJson(readMap(j['range'])),
        visitors: _int(j['visitors']),
        newVisitors: _int(j['newVisitors']),
        sessions: _int(j['sessions']),
        pageViews: _int(j['pageViews']),
        productViews: _int(j['productViews']),
        cartAdds: _int(j['cartAdds']),
        cartRemoves: _int(j['cartRemoves']),
        checkoutsStarted: _int(j['checkoutsStarted']),
        orders: _int(j['orders']),
        orderValue: readDouble(j['orderValue']),
        funnel: BehaviorFunnel.fromJson(readMap(j['funnel'])),
        devices: _list(j['devices'], DeviceSessions.fromJson),
        days: _list(j['days'], BehaviorDay.fromJson),
      );
}

/// Interest in one product: views and cart activity, plus units from tracked store orders.
class ProductInterest {
  const ProductInterest({
    required this.productId,
    required this.name,
    this.views = 0,
    this.viewers = 0,
    this.cartAdds = 0,
    this.cartRemoves = 0,
    this.orders = 0,
    this.unitsOrdered = 0,
    this.viewToCartRate = 0,
    this.cartToOrderRate = 0,
  });

  final int productId;
  final String name;
  final int views;
  final int viewers;
  final int cartAdds;
  final int cartRemoves;
  final int orders;
  final int unitsOrdered;
  final double viewToCartRate;
  final double cartToOrderRate;

  factory ProductInterest.fromJson(Map<String, dynamic> j) => ProductInterest(
        productId: _int(j['productId']),
        name: readString(j['name'], '—'),
        views: _int(j['views']),
        viewers: _int(j['viewers']),
        cartAdds: _int(j['cartAdds']),
        cartRemoves: _int(j['cartRemoves']),
        orders: _int(j['orders']),
        unitsOrdered: _int(j['unitsOrdered']),
        viewToCartRate: readDouble(j['viewToCartRate']),
        cartToOrderRate: readDouble(j['cartToOrderRate']),
      );
}

class AbandonedCartItem {
  const AbandonedCartItem({required this.productId, this.variantId, required this.name, this.variant, this.quantity = 0});

  final int productId;
  final int? variantId;
  final String name;

  /// e.g. "L / Black"; null for products without sizes or colors.
  final String? variant;
  final int quantity;

  String get label => variant == null ? name : '$name ($variant)';

  factory AbandonedCartItem.fromJson(Map<String, dynamic> j) => AbandonedCartItem(
        productId: _int(j['productId']),
        variantId: readInt(j['variantId']),
        name: readString(j['name'], '—'),
        variant: readStringOrNull(j['variant']),
        quantity: _int(j['quantity']),
      );
}

class AbandonedCart {
  const AbandonedCart({
    required this.visitorId,
    this.customerId,
    this.customerName,
    this.phone,
    this.email,
    this.itemCount = 0,
    this.value = 0,
    this.lastActivity,
    this.source = 'Direct',
    this.device,
    this.items = const [],
  });

  final String visitorId;

  /// Null for guests who never logged in.
  final int? customerId;
  final String? customerName;
  final String? phone;
  final String? email;
  final int itemCount;
  final double value;
  final DateTime? lastActivity;
  final String source;
  final String? device;
  final List<AbandonedCartItem> items;

  bool get isGuest => customerId == null;

  String get who => customerName ?? (isGuest ? 'Guest visitor' : 'Customer #$customerId');

  factory AbandonedCart.fromJson(Map<String, dynamic> j) => AbandonedCart(
        visitorId: readString(j['visitorId']),
        customerId: readInt(j['customerId']),
        customerName: readStringOrNull(j['customerName']),
        phone: readStringOrNull(j['phone']),
        email: readStringOrNull(j['email']),
        itemCount: _int(j['itemCount']),
        value: readDouble(j['value']),
        lastActivity: readDate(j['lastActivity']),
        source: readString(j['source'], 'Direct'),
        device: readStringOrNull(j['device']),
        items: _list(j['items'], AbandonedCartItem.fromJson),
      );
}

class AbandonedCartsReport {
  const AbandonedCartsReport({
    required this.range,
    this.idleMinutes = 60,
    this.count = 0,
    this.value = 0,
    this.orderedCarts = 0,
    this.abandonmentRate = 0,
    this.carts = const [],
  });

  final BehaviorRange range;
  final int idleMinutes;

  /// Every abandoned cart in the range; [carts] lists the latest 500.
  final int count;
  final double value;

  /// Carts that turned into an order in the range.
  final int orderedCarts;

  /// abandoned / (abandoned + ordered).
  final double abandonmentRate;
  final List<AbandonedCart> carts;

  factory AbandonedCartsReport.fromJson(Map<String, dynamic> j) => AbandonedCartsReport(
        range: BehaviorRange.fromJson(readMap(j['range'])),
        idleMinutes: readInt(j['idleMinutes']) ?? 60,
        count: _int(j['count']),
        value: readDouble(j['value']),
        orderedCarts: _int(j['orderedCarts']),
        abandonmentRate: readDouble(j['abandonmentRate']),
        carts: _list(j['carts'], AbandonedCart.fromJson),
      );
}

class SearchTerm {
  const SearchTerm({required this.query, this.searches = 0, this.visitors = 0, this.averageResults, this.noResultSearches = 0});

  final String query;
  final int searches;
  final int visitors;

  /// Null when the store never reported how many products matched.
  final double? averageResults;
  final int noResultSearches;

  factory SearchTerm.fromJson(Map<String, dynamic> j) => SearchTerm(
        query: readString(j['query']),
        searches: _int(j['searches']),
        visitors: _int(j['visitors']),
        averageResults: readDoubleOrNull(j['averageResults']),
        noResultSearches: _int(j['noResultSearches']),
      );
}

class SearchReport {
  const SearchReport({this.total = 0, this.noResults = 0, this.top = const [], this.withoutResults = const []});

  final int total;
  final int noResults;
  final List<SearchTerm> top;

  /// Things visitors looked for and didn't find: products to add or rename.
  final List<SearchTerm> withoutResults;

  factory SearchReport.fromJson(Map<String, dynamic> j) => SearchReport(
        total: _int(j['total']),
        noResults: _int(j['noResults']),
        top: _list(j['top'], SearchTerm.fromJson),
        withoutResults: _list(j['withoutResults'], SearchTerm.fromJson),
      );
}

class VoucherAttempts {
  const VoucherAttempts({
    required this.code,
    this.tries = 0,
    this.visitors = 0,
    this.applied = 0,
    this.rejected = 0,
    this.rejections = const {},
  });

  final String code;
  final int tries;
  final int visitors;
  final int applied;
  final int rejected;

  /// Rejection reason (EXPIRED, MIN_ORDER…) → how often.
  final Map<String, int> rejections;

  /// The rejections in words, most frequent first: "Expired ×3, Below minimum ×1".
  String get rejectionSummary {
    final entries = rejections.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => '${reasonLabel(e.key)} ×${e.value}').join(', ');
  }

  static String reasonLabel(String reason) => switch (reason) {
        'NOT_FOUND' => 'Wrong code',
        'INACTIVE' => 'Turned off',
        'NOT_STARTED' => 'Not started yet',
        'EXPIRED' => 'Expired',
        'USED_UP' => 'Used up',
        'MIN_ORDER' => 'Below minimum',
        'LOGIN_REQUIRED' => 'Not logged in',
        'EMPTY' => 'Empty',
        _ => 'Other',
      };

  factory VoucherAttempts.fromJson(Map<String, dynamic> j) => VoucherAttempts(
        code: readString(j['code']),
        tries: _int(j['tries']),
        visitors: _int(j['visitors']),
        applied: _int(j['applied']),
        rejected: _int(j['rejected']),
        rejections: {
          for (final e in (readMap(j['rejections']) ?? const {}).entries) e.key: readInt(e.value) ?? 0,
        },
      );
}

class TrafficSource {
  const TrafficSource({
    required this.source,
    this.visitors = 0,
    this.orderingVisitors = 0,
    this.orders = 0,
    this.orderValue = 0,
    this.conversionRate = 0,
  });

  final String source;
  final int visitors;
  final int orderingVisitors;
  final int orders;
  final double orderValue;
  final double conversionRate;

  factory TrafficSource.fromJson(Map<String, dynamic> j) => TrafficSource(
        source: readString(j['source'], 'Direct'),
        visitors: _int(j['visitors']),
        orderingVisitors: _int(j['orderingVisitors']),
        orders: _int(j['orders']),
        orderValue: readDouble(j['orderValue']),
        conversionRate: readDouble(j['conversionRate']),
      );
}
