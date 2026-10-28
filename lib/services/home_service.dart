import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/models/analysis_models/analysis.dart';
import 'package:warsha_app/models/daily_cash.dart';
import 'package:warsha_app/models/json_read.dart';
import 'package:warsha_app/models/revenue_summary.dart';
import 'package:warsha_app/models/top_products.dart';
import 'package:warsha_app/utils/date.dart';

/// Dashboard figures (backend: CashFlowController under `/cashFlow`).
/// Every failure surfaces as an ApiException from [ApiClient].
class HomeService {
  HomeService(this._api);

  final ApiClient _api;

  Future<List<T>> _list<T>(String path, T Function(Map<String, dynamic>) parse, {Map<String, String>? query}) async =>
      readList(await _api.get(path, query: query)).map(parse).toList();

  Future<RevenueSummary> revenueSummary() async =>
      RevenueSummary.fromJson(readMap(await _api.get('cashFlow/revenueSummary')) ?? const {});

  Future<List<TopProduct>> topSoldProducts() => _list('cashFlow/topSoldProducts', TopProduct.fromJson,
      query: {'date': DateHelper.formatDateMY(DateTime.now().toString())});

  Future<List<DailyCashFlowModel>> dailyCashFlow() => _list('cashFlow/daily', DailyCashFlowModel.fromJson);

  Future<List<CustomerAnalysis>> loyalCustomers() =>
      _list('cashFlow/analysis/customers/loyalty', CustomerAnalysis.fromJson);

  Future<List<CustomerAnalytics>> vipCustomers() => _list('cashFlow/analysis/customers/vip', CustomerAnalytics.fromJson);

  Future<List<CustomerRetention>> atRiskCustomers() =>
      _list('cashFlow/analysis/customers/at-risk', CustomerRetention.fromJson);

  Future<List<CustomerDiscount>> discountSeekers() =>
      _list('cashFlow/analysis/discount-seekers', CustomerDiscount.fromJson);

  /// The backend answers a bare number or `{ "average": n }`.
  Future<double?> averageBasketSize() async {
    final body = await _api.get('cashFlow/analysis/kpi/average-basket-size');
    if (body is num) return body.toDouble();
    if (body is Map) return readDoubleOrNull(body['average']);
    return null;
  }

  Future<List<OrderSourceAnalytics>> revenueBySource() =>
      _list('cashFlow/analysis/revenue-by-source', OrderSourceAnalytics.fromJson);

  Future<List<CustomerAnalytics>> topPerformers() =>
      _list('cashFlow/analysis/products/top-performers', CustomerAnalytics.fromJson);

  Future<List<GovernorateAnalytics>> governoratePerformance() =>
      _list('cashFlow/analysis/governorate-performance', GovernorateAnalytics.fromJson);

  Future<List<DailySales>> dailyRevenueReport() => _list('cashFlow/analysis/daily-revenue-report', DailySales.fromJson);
}
