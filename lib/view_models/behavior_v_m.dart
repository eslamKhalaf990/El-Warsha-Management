import 'package:flutter/foundation.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/core/state/async_view_model.dart';
import 'package:warsha_app/models/behavior.dart';
import 'package:warsha_app/services/behavior_service.dart';

/// The ranges the behavior page offers. Raw events are kept for a year, so
/// there is no "all time". [custom] is whatever was picked last.
enum BehaviorPreset {
  today('Today'),
  last7('Last 7 days'),
  last30('Last 30 days'),
  thisMonth('This month'),
  last90('Last 90 days'),
  custom('Custom');

  const BehaviorPreset(this.label);

  final String label;
}

/// How long a cart must sit unchanged before it counts as abandoned.
enum IdleCutoff {
  minutes30('30 min', 30),
  hour1('1 hour', 60),
  hours6('6 hours', 360),
  day1('1 day', 1440);

  const IdleCutoff(this.label, this.minutes);

  final String label;
  final int minutes;
}

/// What store visitors did in one date range. Like the dashboard, each section
/// loads on its own and [failedSections] says which ones to retry.
class BehaviorVM extends ChangeNotifier with AsyncViewModel {
  BehaviorVM(this._service, {DateTime Function()? today}) : _today = today ?? DateTime.now;

  final BehaviorService _service;
  final DateTime Function() _today;

  BehaviorPreset _preset = BehaviorPreset.last30;
  DateTime? _customFrom;
  DateTime? _customTo;
  IdleCutoff _idle = IdleCutoff.hour1;

  BehaviorPreset get preset => _preset;

  IdleCutoff get idle => _idle;

  BehaviorOverview? overview;
  List<ProductInterest>? products;
  AbandonedCartsReport? abandoned;
  SearchReport? searches;
  List<VoucherAttempts>? vouchers;
  List<TrafficSource>? sources;

  final Set<String> _failed = {};

  Set<String> get failedSections => Set.unmodifiable(_failed);

  /// True once something was tracked in the range; false means the store has
  /// not sent anything yet (or nobody visited).
  bool get hasActivity => (overview?.sessions ?? 0) > 0 || (abandoned?.count ?? 0) > 0;

  DateTime get from => range.$1;

  DateTime get to => range.$2;

  /// The [preset] as days, both inclusive.
  (DateTime, DateTime) get range {
    final now = _today();
    final today = DateTime(now.year, now.month, now.day);
    // Calendar days, not 24-hour steps: Egypt changes its clocks twice a year
    DateTime daysBack(int n) => DateTime(today.year, today.month, today.day - n);
    return switch (_preset) {
      BehaviorPreset.today => (today, today),
      BehaviorPreset.last7 => (daysBack(6), today),
      BehaviorPreset.last30 => (daysBack(29), today),
      BehaviorPreset.thisMonth => (DateTime(today.year, today.month), today),
      BehaviorPreset.last90 => (daysBack(89), today),
      BehaviorPreset.custom => (_customFrom ?? today, _customTo ?? today),
    };
  }

  Future<bool> setPreset(BehaviorPreset preset) {
    _preset = preset;
    return fetch();
  }

  Future<bool> setCustomRange(DateTime from, DateTime to) {
    _preset = BehaviorPreset.custom;
    _customFrom = DateTime(from.year, from.month, from.day);
    _customTo = DateTime(to.year, to.month, to.day);
    return fetch();
  }

  /// Reloads only the abandoned carts with the new cut-off.
  Future<bool> setIdle(IdleCutoff idle) {
    _idle = idle;
    return run(() async {
      _failed.remove('Abandoned carts');
      try {
        abandoned = await _service.abandonedCarts(from: from, to: to, idleMinutes: idle.minutes);
      } on ApiException {
        _failed.add('Abandoned carts');
        rethrow;
      }
    });
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
            debugPrint('Behavior section "$name": $e');
            _failed.add(name);
            firstError ??= ApiException.unexpected();
          }
        }

        final sections = [
          section('Overview', () => _service.overview(from: from, to: to), (v) => overview = v),
          section('Products', () => _service.products(from: from, to: to), (v) => products = v),
          section('Abandoned carts',
              () => _service.abandonedCarts(from: from, to: to, idleMinutes: _idle.minutes), (v) => abandoned = v),
          section('Searches', () => _service.searches(from: from, to: to), (v) => searches = v),
          section('Promo codes', () => _service.vouchers(from: from, to: to), (v) => vouchers = v),
          section('Traffic sources', () => _service.sources(from: from, to: to), (v) => sources = v),
        ];
        await Future.wait(sections);
        if (_failed.length == sections.length) throw firstError!;
      });
}
