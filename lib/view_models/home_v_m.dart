import 'package:flutter/foundation.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/core/state/async_view_model.dart';
import 'package:warsha_app/models/analysis_models/analysis.dart';
import 'package:warsha_app/models/daily_cash.dart';
import 'package:warsha_app/models/revenue_summary.dart';
import 'package:warsha_app/models/top_products.dart';
import 'package:warsha_app/services/home_service.dart';

/// Dashboard figures. Each section loads on its own: one failing endpoint
/// leaves its section empty instead of blanking the whole dashboard, and
/// [failedSections] says which ones to retry.
class HomeVM extends ChangeNotifier with AsyncViewModel {
  HomeVM(this._service);

  final HomeService _service;

  // --- CORE ---
  RevenueSummary? revenueSummary;
  List<DailyCashFlowModel>? dailyCashFlow;
  List<TopProduct>? topProducts;

  // --- CUSTOMER INSIGHTS ---
  List<CustomerAnalysis>? loyalCustomers;
  List<CustomerAnalytics>? vipCustomers;
  List<CustomerRetention>? atRiskCustomers;
  List<CustomerDiscount>? discountSeekers;

  // --- SALES & MARKET PERFORMANCE ---
  double? averageBasketSize;
  List<OrderSourceAnalytics>? revenueBySource;
  List<CustomerAnalytics>? topPerformers;
  List<GovernorateAnalytics>? governoratePerformance;
  List<DailySales>? dailyRevenueReport;

  final Set<String> _failed = {};

  /// Sections whose figures could not be loaded, e.g. `Revenue summary`.
  Set<String> get failedSections => Set.unmodifiable(_failed);

  /// Loads every section; fails (with the first reason) only when all failed.
  Future<bool> fetch() => load(() async {
        _failed.clear();
        ApiException? firstError;
        Future<void> section<T>(String name, Future<T> Function() fetch, void Function(T value) apply) async {
          try {
            apply(await fetch());
          } on ApiException catch (e) {
            _failed.add(name);
            firstError ??= e;
          } catch (e) {
            // Unreadable figures: drop this section only
            debugPrint('Dashboard section "$name": $e');
            _failed.add(name);
            firstError ??= ApiException.unexpected();
          }
        }

        await Future.wait([
          section('Revenue summary', _service.revenueSummary, (v) => revenueSummary = v),
          section('Daily cash flow', _service.dailyCashFlow, (v) => dailyCashFlow = v),
          section('Top products', _service.topSoldProducts, (v) => topProducts = v),
          section('Loyal customers', _service.loyalCustomers, (v) => loyalCustomers = v),
          section('VIP customers', _service.vipCustomers, (v) => vipCustomers = v),
          section('At-risk customers', _service.atRiskCustomers, (v) => atRiskCustomers = v),
          section('Discount seekers', _service.discountSeekers, (v) => discountSeekers = v),
          section('Average basket', _service.averageBasketSize, (v) => averageBasketSize = v),
          section('Revenue by source', _service.revenueBySource, (v) => revenueBySource = v),
          section('Top performers', _service.topPerformers, (v) => topPerformers = v),
          section('Regions', _service.governoratePerformance, (v) => governoratePerformance = v),
          section('Daily revenue', _service.dailyRevenueReport, (v) => dailyRevenueReport = v),
        ]);
        if (_failed.length == 12) throw firstError!;
      });

  /// Older name used by the dashboard's pull-to-refresh.
  Future<bool> initHome() => fetch();
}
