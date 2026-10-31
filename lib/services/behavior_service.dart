import 'package:intl/intl.dart';
import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/models/behavior.dart';
import 'package:warsha_app/models/json_read.dart';

/// Store visitor behavior (backend: BehaviorController under `/analytics/behavior`).
/// [from] and [to] are inclusive days; no [from] means the 30 days ending on [to],
/// no [to] today; at most one year. Every failure surfaces as an ApiException.
class BehaviorService {
  BehaviorService(this._api);

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

  Future<BehaviorOverview> overview({DateTime? from, DateTime? to}) async =>
      BehaviorOverview.fromJson(await _map('analytics/behavior/overview', from, to));

  Future<List<ProductInterest>> products({DateTime? from, DateTime? to}) =>
      _list('analytics/behavior/products', from, to, ProductInterest.fromJson);

  /// [idleMinutes]: how long a cart must sit unchanged to count as left (15 min – 7 days).
  Future<AbandonedCartsReport> abandonedCarts({DateTime? from, DateTime? to, int? idleMinutes}) async =>
      AbandonedCartsReport.fromJson(await _map('analytics/behavior/abandoned-carts', from, to,
          {if (idleMinutes != null) 'idleMinutes': '$idleMinutes'}));

  Future<SearchReport> searches({DateTime? from, DateTime? to}) async =>
      SearchReport.fromJson(await _map('analytics/behavior/searches', from, to));

  Future<List<VoucherAttempts>> vouchers({DateTime? from, DateTime? to}) =>
      _list('analytics/behavior/vouchers', from, to, VoucherAttempts.fromJson);

  Future<List<TrafficSource>> sources({DateTime? from, DateTime? to}) =>
      _list('analytics/behavior/sources', from, to, TrafficSource.fromJson);
}
