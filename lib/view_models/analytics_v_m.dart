import 'package:flutter/foundation.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/core/state/async_view_model.dart';
import 'package:warsha_app/models/analytics.dart';
import 'package:warsha_app/services/analytics_service.dart';

/// The ranges the dashboard offers. [custom] is whatever was picked last.
enum RangePreset {
  thisMonth('This month'),
  last30('Last 30 days'),
  last90('Last 90 days'),
  thisYear('This year'),
  last12Months('Last 12 months'),
  allTime('All time'),
  custom('Custom');

  const RangePreset(this.label);

  final String label;
}

/// The analytics dashboard for one date range. Each section loads on its own:
/// one failing endpoint leaves its section empty instead of blanking the whole
/// dashboard, and [failedSections] says which ones to retry.
class AnalyticsVM extends ChangeNotifier with AsyncViewModel {
  AnalyticsVM(this._service, {DateTime Function()? today}) : _today = today ?? DateTime.now;

  final AnalyticsService _service;
  final DateTime Function() _today;

  RangePreset _preset = RangePreset.last12Months;
  DateTime? _customFrom;
  DateTime? _customTo;

  RangePreset get preset => _preset;

  AnalyticsOverview? overview;
  SalesTrend? trend;
  ProductInsights? products;
  List<ChannelSales>? channels;
  List<RegionSales>? regions;
  CustomerInsights? customers;
  CashInsights? cash;

  final Set<String> _failed = {};

  /// Sections whose figures could not be loaded, e.g. `Products`.
  Set<String> get failedSections => Set.unmodifiable(_failed);

  /// The first day asked for; null is all time.
  DateTime? get from => range.$1;

  DateTime get to => range.$2;

  /// The [preset] as days, both inclusive.
  (DateTime?, DateTime) get range {
    final now = _today();
    final today = DateTime(now.year, now.month, now.day);
    return switch (_preset) {
      RangePreset.thisMonth => (DateTime(today.year, today.month), today),
      RangePreset.last30 => (today.subtract(const Duration(days: 29)), today),
      RangePreset.last90 => (today.subtract(const Duration(days: 89)), today),
      RangePreset.thisYear => (DateTime(today.year), today),
      RangePreset.last12Months => (DateTime(today.year - 1, today.month, today.day + 1), today),
      RangePreset.allTime => (null, today),
      RangePreset.custom => (_customFrom, _customTo ?? today),
    };
  }

  Future<bool> setPreset(RangePreset preset) {
    _preset = preset;
    return fetch();
  }

  Future<bool> setCustomRange(DateTime from, DateTime to) {
    _preset = RangePreset.custom;
    _customFrom = DateTime(from.year, from.month, from.day);
    _customTo = DateTime(to.year, to.month, to.day);
    return fetch();
  }

  /// Loads every section; fails (with the first reason) only when all failed.
  Future<bool> fetch() => load(() async {
        _failed.clear();
        final (from, to) = range;
        ApiException? firstError;
        Future<void> section<T>(String name, Future<T> Function() fetch, void Function(T value) apply) async {
          try {
            apply(await fetch());
          } on ApiException catch (e) {
            _failed.add(name);
            firstError ??= e;
          } catch (e) {
            // Unreadable figures: drop this section only
            debugPrint('Analytics section "$name": $e');
            _failed.add(name);
            firstError ??= ApiException.unexpected();
          }
        }

        final sections = [
          section('Overview', () => _service.overview(from: from, to: to), (v) => overview = v),
          section('Sales trend', () => _service.trend(from: from, to: to), (v) => trend = v),
          section('Products', () => _service.products(from: from, to: to), (v) => products = v),
          section('Channels', () => _service.channels(from: from, to: to), (v) => channels = v),
          section('Regions', () => _service.regions(from: from, to: to), (v) => regions = v),
          section('Customers', () => _service.customers(from: from, to: to), (v) => customers = v),
          section('Cash', () => _service.cash(from: from, to: to), (v) => cash = v),
        ];
        await Future.wait(sections);
        if (_failed.length == sections.length) throw firstError!;
      });

  /// Change against the previous period as a fraction (0.12 = +12%), or null
  /// when there is nothing to compare with.
  static double? change(num current, num? previous) {
    if (previous == null || previous == 0) return null;
    return (current - previous) / previous.abs();
  }
}
