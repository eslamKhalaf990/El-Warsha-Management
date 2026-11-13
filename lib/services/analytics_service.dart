import 'package:intl/intl.dart';
import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/models/analytics.dart';
import 'package:warsha_app/models/json_read.dart';

/// The analytics dashboard (backend: AnalyticsController under `/analytics`).
/// [from] and [to] are inclusive days; no [from] means all time, no [to] today.
/// Every failure surfaces as an ApiException from [ApiClient].
class AnalyticsService {
  AnalyticsService(this._api);

  final ApiClient _api;

  static final _day = DateFormat('yyyy-MM-dd');

  Map<String, String> _range(DateTime? from, DateTime? to) => {
        if (from != null) 'from': _day.format(from),
        if (to != null) 'to': _day.format(to),
      };

  Future<Map<String, dynamic>> _map(String path, DateTime? from, DateTime? to, [Map<String, String> extra = const {}]) async =>
      readMap(await _api.get(path, query: {..._range(from, to), ...extra})) ?? const {};

  Future<List<T>> _list<T>(String path, DateTime? from, DateTime? to, T Function(Map<String, dynamic>) parse) async =>
      readList(await _api.get(path, query: _range(from, to))).map(parse).toList();

  Future<AnalyticsOverview> overview({DateTime? from, DateTime? to}) async =>
      AnalyticsOverview.fromJson(await _map('analytics/overview', from, to));

  /// [granularity] is day, week or month; left out, the backend picks one for the range.
  Future<SalesTrend> trend({DateTime? from, DateTime? to, String? granularity}) async =>
      SalesTrend.fromJson(await _map('analytics/trend', from, to, {if (granularity != null) 'granularity': granularity}));

  Future<ProductInsights> products({DateTime? from, DateTime? to}) async =>
      ProductInsights.fromJson(await _map('analytics/products', from, to));

  Future<List<ChannelSales>> channels({DateTime? from, DateTime? to}) =>
      _list('analytics/channels', from, to, ChannelSales.fromJson);

  Future<List<RegionSales>> regions({DateTime? from, DateTime? to}) =>
      _list('analytics/regions', from, to, RegionSales.fromJson);

  Future<CustomerInsights> customers({DateTime? from, DateTime? to}) async =>
      CustomerInsights.fromJson(await _map('analytics/customers', from, to));

  Future<CashInsights> cash({DateTime? from, DateTime? to}) async =>
      CashInsights.fromJson(await _map('analytics/cash', from, to));
}
